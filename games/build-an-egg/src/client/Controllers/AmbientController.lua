local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PropsConfig = require(Shared.Config.Props)
local EffectsConfig = require(Shared.Config.Effects)
local Names = require(Shared.Config.Names)

local Settings = require(script.Parent.Parent.Util.Settings)

local AmbientController = {
	Wobblers = {},
	Wanderers = {},
	Clouds = {},
	Swayers = {},
	Streaks = {},
}

local WIND = EffectsConfig.Wind
local windDirection = WIND.Direction.Unit
local swayAxis = Vector3.new(windDirection.Z, 0, -windDirection.X)
local templates
local leaves
local lastStreak = 0

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
	local function addSway(model)
		if model:IsA("Model") then
			local base = model:GetPivot()
			local _, size = model:GetBoundingBox()
			local leaves
			if model:GetAttribute("SwayLeaves") then
				leaves = { Parts = {} }
				local lowest = math.huge
				for _, part in model:GetChildren() do
					local role = part:GetAttribute("Role")
					if part:IsA("BasePart") and role and role:find("^Leaf") then
						table.insert(leaves.Parts, { Part = part, Base = part.CFrame, Light = role == "LeafLight" })
						lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
					end
				end
				leaves.Pivot = CFrame.new(base.Position.X, lowest, base.Position.Z)
			end
			self.Swayers[model] = {
				Base = base,
				Amp = math.rad(model:GetAttribute("Sway") or 2),
				Phase = (base.Position.X + base.Position.Z) * 0.025 + random:NextNumber(0, 0.6),
				Speed = WIND.SwaySpeed * random:NextNumber(0.85, 1.15),
				Small = size.Y < WIND.SmallSize,
				Leaves = leaves,
			}
		end
	end
	for _, model in CollectionService:GetTagged("Sway") do
		addSway(model)
	end
	CollectionService:GetInstanceAddedSignal("Sway"):Connect(addSway)
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
	local leafTemplate = templates:FindFirstChild("WindLeaves")
	if leafTemplate then
		leaves = leafTemplate:Clone()
		leaves.Parent = Workspace.CurrentCamera
	end
	RunService.Heartbeat:Connect(function(dt)
		self:Step(dt)
	end)
end

function AmbientController:StepWind(dt, t, cameraPosition)
	local enabled = Settings:EffectScale() > 0
	if leaves then
		leaves.CFrame = CFrame.new(cameraPosition + Vector3.new(0, WIND.LeafHeight, 0))
		leaves.Leaves.Enabled = enabled
	end
	for model, state in self.Swayers do
		if not model.Parent then
			self.Swayers[model] = nil
		else
			local distance = (state.Base.Position - cameraPosition).Magnitude
			if distance < (state.Small and WIND.SmallRadius or WIND.SwayRadius) then
				local wave = math.sin(t * state.Speed + state.Phase) * 0.7 + math.sin(t * state.Speed * 2.3 + state.Phase * 1.7) * 0.3
				if state.Leaves then
					local pivot = state.Leaves.Pivot
					for _, leaf in state.Leaves.Parts do
						local flutter = leaf.Light and math.sin(t * state.Speed * 3.1 + state.Phase * 2.3) * 0.35 or 0
						local rotation = CFrame.fromAxisAngle(swayAxis, state.Amp * (0.35 + wave + flutter))
						leaf.Part.CFrame = pivot * rotation * pivot:Inverse() * leaf.Base
					end
				else
					model:PivotTo(state.Base * CFrame.fromAxisAngle(state.Base.Rotation:VectorToObjectSpace(swayAxis), state.Amp * (0.35 + wave)))
				end
			end
		end
	end
	for streak, state in self.Streaks do
		local age = t - state.Born
		if age > WIND.StreakLife then
			streak:Destroy()
			self.Streaks[streak] = nil
		else
			local along = state.Origin + windDirection * WIND.StreakSpeed * age
			local lift = math.sin(age * 4 + state.Phase) * WIND.StreakWave
			local curl = math.cos(age * 3 + state.Phase) * WIND.StreakWave * 0.6
			local position = along + Vector3.new(0, lift, 0) + swayAxis * curl
			if streak:IsA("Model") then
				streak:PivotTo(CFrame.lookAt(position, position + windDirection) * state.Roll)
			else
				streak.CFrame = CFrame.new(position)
			end
		end
	end
	if enabled and templates and t - lastStreak > WIND.StreakInterval then
		lastStreak = t
		local count = 0
		for _ in self.Streaks do
			count += 1
		end
		local gusts = templates:FindFirstChild("WindGusts")
		local options = gusts and gusts:GetChildren() or {}
		local template = #options > 0 and options[random:NextInteger(1, #options)] or templates:FindFirstChild("WindStreak")
		if template and count < WIND.StreakMax then
			local angle = random:NextNumber(0, math.pi * 2)
			local radius = random:NextNumber(WIND.StreakRing[1], WIND.StreakRing[2])
			local origin = cameraPosition * Vector3.new(1, 0, 1) + Vector3.new(math.cos(angle) * radius, random:NextNumber(WIND.StreakHeight[1], WIND.StreakHeight[2]), math.sin(angle) * radius) - windDirection * WIND.StreakSpeed * WIND.StreakLife * 0.5
			local streak = template:Clone()
			local roll = CFrame.Angles(0, 0, random:NextNumber(-0.6, 0.6))
			if streak:IsA("Model") then
				streak:PivotTo(CFrame.lookAt(origin, origin + windDirection) * roll)
			else
				streak.CFrame = CFrame.new(origin)
			end
			streak.Parent = Workspace.CurrentCamera
			self.Streaks[streak] = { Born = t, Origin = origin, Phase = random:NextNumber(0, math.pi * 2), Roll = roll }
		end
	end
end

function AmbientController:Step(dt)
	local t = os.clock()
	local cameraPosition = camera.CFrame.Position
	self:StepWind(dt, t, cameraPosition)
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
