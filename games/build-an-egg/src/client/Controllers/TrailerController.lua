local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local EggConfig = require(Shared.Config.Egg)
local TrailerConfig = require(Shared.Config.Trailer)
local EggShape = require(Shared.Util.EggShape)

local Cinematic = require(script.Parent.Parent.Util.Cinematic)

local TrailerController = {
	Running = false,
	Generation = 0,
}

local ClientState
local CutsceneController
local EggController
local remotes
local player
local camera = Workspace.CurrentCamera

local HIDDEN_GUIS = { Names.Gui.Notify, Names.Gui.Alert, Names.Gui.Overlay, Names.Gui.PurchaseBlur, Names.Gui.Fx }
local HIDDEN_CUTSCENE = { "Top", "Bottom", "Caption", "Skip" }

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function flat(vector)
	local result = Vector3.new(vector.X, 0, vector.Z)
	return result.Magnitude > 0.01 and result.Unit or Vector3.new(0, 0, -1)
end

local function armed()
	return Workspace:GetAttribute(TrailerConfig.Attribute) == true
end

function TrailerController:Init(modules, context)
	ClientState = modules.ClientState
	CutsceneController = modules.CutsceneController
	EggController = modules.EggController
	remotes = context.Remotes
	player = context.Player
	if armed() then
		CutsceneController.IntroDone = true
	end
end

function TrailerController:Start()
	local function tryAuto()
		if armed() and Workspace:GetAttribute(TrailerConfig.AutoAttribute) == true then
			task.spawn(self.Run, self)
		end
	end
	Workspace:GetAttributeChangedSignal(TrailerConfig.Attribute):Connect(function()
		if armed() then
			CutsceneController.IntroDone = true
		end
		tryAuto()
	end)
	Workspace:GetAttributeChangedSignal(TrailerConfig.AutoAttribute):Connect(tryAuto)
	UserInputService.InputBegan:Connect(function(input)
		if armed() and input.KeyCode == TrailerConfig.StartKey then
			task.spawn(self.Run, self)
		end
	end)
	tryAuto()
end

function TrailerController:Root()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function TrailerController:Humanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

function TrailerController:Controls()
	local playerModule = player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return nil
	end
	local ok, module = pcall(require, playerModule)
	return ok and module:GetControls() or nil
end

function TrailerController:Prepare(on)
	if on then
		Cinematic.Enter()
	else
		Cinematic.Exit()
	end
	pcall(StarterGui.SetCore, StarterGui, "TopbarEnabled", not on)
	UserInputService.MouseIconEnabled = not on
	pcall(function()
		ProximityPromptService.Enabled = not on
	end)
	local playerGui = player:FindFirstChild("PlayerGui")
	for _, name in HIDDEN_GUIS do
		local screen = playerGui and playerGui:FindFirstChild(name)
		if screen then
			screen.Enabled = not on
		end
	end
	local cutscene = Cinematic.Gui():FindFirstChild("Cutscene")
	for _, name in HIDDEN_CUTSCENE do
		local item = cutscene and cutscene:FindFirstChild(name)
		if item then
			item.Visible = not on
		end
	end
	local controls = self:Controls()
	if controls then
		if on then
			controls:Disable()
		else
			controls:Enable()
		end
	end
	camera.CameraType = on and Enum.CameraType.Scriptable or Enum.CameraType.Custom
	camera.FieldOfView = TrailerConfig.FieldOfView
	Cinematic.Focus(nil)
end

function TrailerController:Flash()
	local fade = Cinematic.Gui():FindFirstChild("Fade")
	if not fade then
		return
	end
	local color = fade.BackgroundColor3
	fade.BackgroundColor3 = TrailerConfig.SyncFlash.Color
	fade.BackgroundTransparency = 0
	task.wait(TrailerConfig.SyncFlash.Time)
	fade.BackgroundTransparency = 1
	fade.BackgroundColor3 = color
end

function TrailerController:Log(kind, index, shot)
	print(("[Trailer] %s %d %s t=%.3f"):format(kind, index, shot and shot.Name or "-", os.clock() - (self.Clock or os.clock())))
end

function TrailerController:Stream(spec)
	for _, point in { spec.Center, spec.Focus, spec.From } do
		if typeof(point) == "Vector3" then
			pcall(player.RequestStreamAroundAsync, player, point, 2)
		end
	end
end

function TrailerController:Pose(spec, alpha, dt)
	local t = (1 - math.cos(math.pi * alpha)) / 2
	if spec.Mode == "Path" then
		return spec.From:Lerp(spec.To, t), spec.FocusTo and spec.Focus:Lerp(spec.FocusTo, t) or spec.Focus
	elseif spec.Mode == "Orbit" then
		local angle = math.rad(lerp(spec.From, spec.To, t))
		local radius = lerp(spec.Radius, spec.RadiusTo or spec.Radius, t)
		local height = lerp(spec.Height, spec.HeightTo or spec.Height, t)
		return spec.Center + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius), spec.Focus or spec.Center
	end
	local root = self:Root()
	if not root then
		return nil
	end
	if not self.Anchor or not dt then
		self.Anchor = root.Position
		self.Facing = flat(root.CFrame.LookVector)
	else
		self.Anchor = self.Anchor:Lerp(root.Position, 1 - math.exp(-TrailerConfig.FollowSharpness * dt))
	end
	local anchor = self.Anchor
	if spec.Mode == "Around" then
		local direction = CFrame.Angles(0, math.rad(lerp(spec.From, spec.To, t)), 0):VectorToWorldSpace(self.Facing)
		local radius = lerp(spec.Radius, spec.RadiusTo or spec.Radius, t)
		local height = lerp(spec.Height, spec.HeightTo or spec.Height, t)
		return anchor + direction * radius + Vector3.new(0, height, 0), anchor + spec.Look
	end
	local offset = spec.OffsetTo and spec.Offset:Lerp(spec.OffsetTo, t) or spec.Offset
	if spec.Mode == "Radial" then
		local outward = flat(anchor - EggConfig.Center)
		local tangent = Vector3.yAxis:Cross(outward)
		local function place(vector)
			return anchor + outward * vector.X + Vector3.yAxis * vector.Y + tangent * vector.Z
		end
		return place(offset), place(spec.Look)
	end
	return anchor + offset, anchor + spec.Look
end

function TrailerController:Frame(spec, alpha, dt)
	local position, focus = self:Pose(spec, alpha, dt)
	if position then
		camera.CFrame = CFrame.lookAt(position, focus)
		Cinematic.Focus(focus)
	end
end

function TrailerController:Walk(move, generation)
	local humanoid = self:Humanoid()
	if not humanoid then
		return
	end
	local points = {}
	if move.Scaffold then
		for height = move.Scaffold.From, move.Scaffold.To, move.Scaffold.Step do
			table.insert(points, (EggShape.ScaffoldPoint(height)))
		end
	else
		points = move
	end
	for _, point in points do
		if self.Generation ~= generation then
			return
		end
		humanoid:MoveTo(point)
		humanoid.MoveToFinished:Wait()
	end
end

function TrailerController:Halt()
	self.Generation += 1
	local humanoid = self:Humanoid()
	local root = self:Root()
	if humanoid and root then
		humanoid:MoveTo(root.Position)
	end
end

function TrailerController:Hold(spec, alpha, duration)
	local started = os.clock()
	local last = started
	while os.clock() - started < duration do
		RunService.RenderStepped:Wait()
		local now = os.clock()
		self:Frame(spec, alpha, now - last)
		last = now
	end
end

function TrailerController:Game(index, shot)
	local started = os.clock()
	while not EggController.InCutscene and os.clock() - started < TrailerConfig.GameWait do
		task.wait()
	end
	self:Log("shot", index, shot)
	while EggController.InCutscene and os.clock() - started < shot.Time do
		task.wait()
	end
	task.wait(TrailerConfig.Tail)
	camera.CameraType = Enum.CameraType.Scriptable
end

function TrailerController:Shot(index, shot)
	self:Halt()
	local generation = self.Generation
	self:Log("stage", index, shot)
	remotes[Names.Remotes.Trailer]:InvokeServer("Stage", index)
	local spec = shot.Camera
	if spec.Mode == "Game" then
		self:Game(index, shot)
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = shot.FieldOfView or TrailerConfig.FieldOfView
	self:Stream(spec)
	self.Anchor = nil
	self:Frame(spec, 0, nil)
	self:Hold(spec, 0, TrailerConfig.Lead)
	self:Log("shot", index, shot)
	if shot.Move then
		task.spawn(self.Walk, self, shot.Move, generation)
	end
	local started = os.clock()
	local last = started
	while true do
		RunService.RenderStepped:Wait()
		local now = os.clock()
		local alpha = math.min((now - started) / shot.Time, 1)
		self:Frame(spec, alpha, now - last)
		last = now
		if alpha >= 1 then
			break
		end
	end
	self:Hold(spec, 1, TrailerConfig.Tail)
end

function TrailerController:Run()
	if self.Running then
		return
	end
	self.Running = true
	while not ClientState.State or CutsceneController.Playing or EggController.InCutscene do
		task.wait(0.2)
	end
	self:Prepare(true)
	remotes[Names.Remotes.Trailer]:InvokeServer("Stage", 0)
	task.wait(TrailerConfig.StartDelay)
	self.Clock = os.clock()
	self:Log("flash", 0, nil)
	self:Flash()
	for index, shot in TrailerConfig.Shots do
		self:Shot(index, shot)
	end
	self:Halt()
	self:Log("done", #TrailerConfig.Shots, nil)
	self:Prepare(false)
	self.Running = false
end

return TrailerController
