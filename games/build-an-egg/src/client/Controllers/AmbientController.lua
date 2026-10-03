local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PropsConfig = require(Shared.Config.Props)

local AmbientController = {
	Wobblers = {},
	Wanderers = {},
	Clouds = {},
}

local CULL = 260
local camera = Workspace.CurrentCamera
local random = Random.new()

function AmbientController:Start()
	local function addWobble(model)
		if model:IsA("Model") then
			self.Wobblers[model] = { Base = model:GetPivot(), Phase = random:NextNumber(0, math.pi * 2) }
		end
	end
	local function addWander(model)
		if model:IsA("Model") then
			local pivot = model:GetPivot()
			self.Wanderers[model] = {
				Position = pivot.Position,
				Facing = pivot.Rotation,
				Home = model:GetAttribute("Home") or pivot.Position,
				Spread = model:GetAttribute("Spread") or 10,
				Speed = model:GetAttribute("Speed") or 4,
				Yaw = math.rad(model:GetAttribute("Yaw") or 0),
				Target = nil,
				PauseUntil = os.clock() + random:NextNumber(0, 3),
				Phase = random:NextNumber(0, math.pi * 2),
			}
		end
	end
	for _, model in CollectionService:GetTagged("Wobble") do
		addWobble(model)
	end
	for _, model in CollectionService:GetTagged("Wander") do
		addWander(model)
	end
	local function addNPC(npc)
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
		if not animator or PropsConfig.NPCIdleAnimation == "" then
			return
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = PropsConfig.NPCIdleAnimation
		local ok, track = pcall(animator.LoadAnimation, animator, animation)
		if ok and track then
			track.Looped = true
			track:Play()
		end
	end
	for _, npc in CollectionService:GetTagged("NPC") do
		task.spawn(addNPC, npc)
	end
	CollectionService:GetInstanceAddedSignal("NPC"):Connect(addNPC)
	CollectionService:GetInstanceAddedSignal("Wobble"):Connect(addWobble)
	CollectionService:GetInstanceAddedSignal("Wander"):Connect(addWander)
	local function addCloud(model)
		if model:IsA("Model") then
			self.Clouds[model] = { Base = model:GetPivot(), Drift = model:GetAttribute("Drift") or 2, Phase = random:NextNumber(0, math.pi * 2) }
		end
	end
	for _, model in CollectionService:GetTagged("Cloud") do
		addCloud(model)
	end
	CollectionService:GetInstanceAddedSignal("Cloud"):Connect(addCloud)
	RunService.Heartbeat:Connect(function(dt)
		self:Step(dt)
	end)
end

function AmbientController:Step(dt)
	local t = os.clock()
	local cameraPosition = camera.CFrame.Position
	local display = PropsConfig.Displays
	for model, state in self.Wobblers do
		if not model.Parent then
			self.Wobblers[model] = nil
		elseif (state.Base.Position - cameraPosition).Magnitude < CULL then
			local angle = math.rad(display.WobbleDegrees)
			local wobble = CFrame.Angles(math.sin(t * display.WobbleSpeed + state.Phase) * angle, t * 0.6 + state.Phase, math.cos(t * display.WobbleSpeed * 1.3 + state.Phase) * angle * 0.6)
			model:PivotTo(state.Base * wobble)
		end
	end
	for model, state in self.Clouds do
		if not model.Parent then
			self.Clouds[model] = nil
		else
			local sway = math.sin(t * 0.03 * state.Drift + state.Phase) * PropsConfig.CloudSway
			model:PivotTo(state.Base * CFrame.new(sway, math.sin(t * 0.2 + state.Phase) * 1.5, 0))
		end
	end
	for model, state in self.Wanderers do
		if not model.Parent then
			self.Wanderers[model] = nil
		elseif (state.Position - cameraPosition).Magnitude < CULL then
			local moving = false
			if t >= state.PauseUntil then
				if not state.Target then
					local home = state.Home
					state.Target = Vector3.new(home.X + random:NextNumber(-state.Spread, state.Spread), state.Position.Y, home.Z + random:NextNumber(-state.Spread, state.Spread))
				end
				local delta = state.Target - state.Position
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude < 0.3 then
					state.Target = nil
					state.PauseUntil = t + random:NextNumber(PropsConfig.WanderPause[1], PropsConfig.WanderPause[2])
				else
					moving = true
					local step = math.min(flat.Magnitude, state.Speed * dt)
					state.Position += flat.Unit * step
					local goal = CFrame.lookAt(Vector3.zero, flat.Unit) * CFrame.Angles(0, state.Yaw, 0)
					state.Facing = state.Facing:Lerp(goal.Rotation, math.min(1, dt * 8))
				end
			end
			local hop = moving and math.abs(math.sin(t * 12 + state.Phase)) * PropsConfig.WanderHop or 0
			local peck = not moving and math.max(0, math.sin(t * 3 + state.Phase)) ^ 8 * 0.35 or 0
			model:PivotTo(CFrame.new(state.Position + Vector3.new(0, hop, 0)) * state.Facing * CFrame.Angles(0, 0, -peck))
		end
	end
end

return AmbientController
