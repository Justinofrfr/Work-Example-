local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local GameConfig = require(Shared.Config.Game)
local EggConfig = require(Shared.Config.Egg)
local MapConfig = require(Shared.Config.Map)
local ProjectsConfig = require(Shared.Config.Projects)
local EffectsConfig = require(Shared.Config.Effects)
local UIConfig = require(Shared.Config.UI)
local Format = require(Shared.Util.Format)
local EggShape = require(Shared.Util.EggShape)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local EggController = {
	Visible = -1,
	Ring = 0,
	Project = nil,
	Cracked = false,
	InCutscene = false,
}

local W = Names.World
local A = Names.Attributes
local ClientState
local EffectController
local remotes
local player
local gui
local segments = {}
local ringModels = {}
local steps = {}
local anchors = {}
local arrows = {}
local board
local camera = Workspace.CurrentCamera

function EggController:Init(modules, context)
	ClientState = modules.ClientState
	EffectController = modules.EffectController
	remotes = context.Remotes
	player = context.Player
	gui = context.Gui
end

function EggController:Start()
	local world = Workspace:WaitForChild(W.Root)
	local site = world:WaitForChild(W.Site)
	local egg = site:WaitForChild(W.Egg)
	for _, ring in egg:WaitForChild(W.Rings):GetChildren() do
		ringModels[ring:GetAttribute(A.Ring)] = ring
		for _, segment in ring:GetChildren() do
			local index = segment:GetAttribute(A.Segment)
			if index then
				segments[index] = segment
			end
		end
	end
	for _, step in site:WaitForChild(W.Scaffold):GetChildren() do
		if step.Name == "Step" then
			table.insert(steps, { Part = step, Height = step:GetAttribute("Height"), Color = step.Color, Material = step.Material })
		end
	end
	for _, anchor in site:WaitForChild(W.Band):GetChildren() do
		table.insert(anchors, anchor)
	end
	table.sort(anchors, function(a, b)
		return a.Name < b.Name
	end)
	for _, arrow in site:WaitForChild(W.Trail):GetChildren() do
		table.insert(arrows, arrow)
	end
	board = egg:FindFirstChild(W.EggBoard, true)
	ClientState.ServerChanged:Connect(function(server, previous)
		self:Render(server, previous)
	end)
	ClientState.StateChanged:Connect(function(state)
		self:RenderTrail(state)
		self:RenderHatch()
	end)
	remotes[Names.Remotes.Notify].OnClientEvent:Connect(function(kind)
		if kind == "EggComplete" then
			task.spawn(self.PlayCutscene, self)
		end
	end)
	local hatch = gui:WaitForChild("Hatch")
	Ui.Feel(hatch.Button, function()
		self:Claim()
	end)
	gui.Cutscene.Skip.Activated:Connect(function()
		self.SkipRequested = true
	end)
	RunService.Heartbeat:Connect(function()
		self:Animate()
	end)
end

function EggController:ProjectColor(server)
	local project = server and ProjectsConfig.List[server.Project]
	return project and project.Color or MapConfig.Palette.Shell
end

function EggController:Render(server, previous)
	local visible = EggShape.VisibleSegments(server.Progress, server.Target)
	local ring = server.Ring
	local color = self:ProjectColor(server)
	local projectChanged = self.Project ~= server.Project
	if previous and previous.Round ~= server.Round then
		self:Restore()
	end
	if visible ~= self.Visible or ring ~= self.Ring or projectChanged then
		local before = self.Visible
		for index, segment in segments do
			local built = index <= visible
			local ghost = not built and segment.Parent:GetAttribute(A.Ring) == ring and server.Phase == "Building"
			if built then
				segment.Transparency = 0
				segment.Color = color
				segment.Material = Enum.Material.SmoothPlastic
				if before >= 0 and index > before and visible - before <= 12 then
					local size = segment.Size
					segment.Size = size * 0.6
					Ui.Tween(segment, 0.12, { Size = size }, Enum.EasingStyle.Back)
				end
			elseif ghost then
				segment.Color = MapConfig.Palette.Band
				segment.Material = Enum.Material.Neon
				segment.Transparency = 0.7
			else
				segment.Transparency = 1
			end
		end
		self.Visible = visible
		self.Ring = ring
		self.Project = server.Project
		self:RenderBand(server)
	end
	if board then
		board.Title.Text = string.upper(server.ProjectName)
		board.Percent.Text = Format.Percent(server.Target > 0 and server.Progress / server.Target or 0)
	end
	self:RenderHatch()
end

function EggController:RenderBand(server)
	local building = server.Phase == "Building"
	local bandY = EggShape.BandHeight(server.Ring)
	local reach = EggConfig.BandVerticalReach
	for _, step in steps do
		local inBand = building and math.abs(step.Height - bandY) <= reach
		step.Part.Color = inBand and MapConfig.Palette.Band or step.Color
		step.Part.Material = inBand and Enum.Material.Neon or step.Material
	end
	local count = #anchors
	for index, anchor in anchors do
		local offset = ((index - 1) / math.max(count - 1, 1) - 0.5) * 2 * reach
		local point = EggShape.ScaffoldPoint(bandY + offset)
		anchor.CFrame = CFrame.new(point + Vector3.new(0, EggConfig.StandHeight, 0))
		local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = building and prompt.Enabled
		end
	end
end

function EggController:RenderTrail(state)
	local show = state.PiecesPlaced == 0 or not EffectsConfig.TrailFirstTripOnly
	for _, arrow in arrows do
		arrow:SetAttribute("Show", show)
		if not show then
			arrow.Transparency = 1
		end
	end
end

function EggController:Animate()
	local t = os.clock()
	local pulse = 0.55 + 0.2 * math.sin(t * EffectsConfig.BandPulseSpeed * math.pi)
	local ring = ringModels[self.Ring]
	if ring and ClientState.Server and ClientState.Server.Phase == "Building" then
		for _, segment in ring:GetChildren() do
			if segment.Material == Enum.Material.Neon then
				segment.Transparency = pulse
			end
		end
	end
	for index, arrow in arrows do
		if arrow:GetAttribute("Show") then
			arrow.Transparency = 0.15 + 0.6 * (0.5 + 0.5 * math.sin(t * 4 - index * 0.6))
		end
	end
end

function EggController:IsContributor()
	local state = ClientState.State
	return state ~= nil and (state.RoundPieces or 0) >= GameConfig.InteriorMinContribution
end

function EggController:RenderHatch()
	local server = ClientState.Server
	local state = ClientState.State
	local hatch = gui:FindFirstChild("Hatch")
	if not hatch or not server or not state then
		return
	end
	local show = server.Phase == "Interior" and self:IsContributor() and not state.Claimed and not self.InCutscene
	if show and not hatch.Visible then
		hatch.Visible = true
		Ui.Pop(hatch.Button, 1.15)
	elseif not show then
		hatch.Visible = false
	end
	if show then
		local remaining = math.max(0, math.ceil(server.PhaseEndsAt - GameConfig.InteriorDuration + GameConfig.HatchAutoClaimDelay - Workspace:GetServerTimeNow()))
		hatch.Timer.Text = remaining > 0 and ("Auto-hatch in %ds"):format(remaining) or ""
	end
end

function EggController:Claim()
	local ok, result = remotes[Names.Remotes.ClaimHatch]:InvokeServer()
	if ok then
		Audio.Play("Hatch")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			EffectController:Burst("Confetti", root.Position + Vector3.new(0, 4, 0), 30)
		end
	elseif result == "NotContributor" then
		Audio.Play("Error")
	end
	gui.Hatch.Visible = false
end

function EggController:SetGlow(alpha)
	local color = self:ProjectColor(ClientState.Server)
	for _, segment in segments do
		if segment.Transparency < 1 then
			segment.Material = alpha > 0.5 and Enum.Material.Neon or Enum.Material.SmoothPlastic
			segment.Color = color:Lerp(Color3.new(1, 1, 1), alpha)
		end
	end
end

function EggController:Crack(rings)
	for index = GameConfig.RingCount - rings + 1, GameConfig.RingCount do
		local ring = ringModels[index]
		if ring then
			for _, segment in ring:GetChildren() do
				if segment:IsA("BasePart") then
					segment.Transparency = 1
				end
			end
		end
	end
	self.Cracked = true
end

function EggController:Restore()
	self.Cracked = false
	self.Visible = -1
end

function EggController:PlayCutscene()
	local cutscene = gui.Cutscene
	local contributor = self:IsContributor()
	local def = EffectsConfig.Cutscene
	local total = GameConfig.CompletionCutsceneTime
	EffectController:Shake(EffectsConfig.Shake.LastPiece)
	Audio.Play("LastPiece")
	self.InCutscene = true
	self.SkipRequested = false
	local previousType = camera.CameraType
	if contributor then
		cutscene.Visible = true
		Ui.Tween(cutscene.Top, 0.4, { Position = UDim2.fromScale(0, 0) })
		Ui.Tween(cutscene.Bottom, 0.4, { Position = UDim2.fromScale(0, 0.88) })
		cutscene.Caption.Text = string.upper(ClientState.Server and ClientState.Server.ProjectName or "EGG") .. " COMPLETE!"
		camera.CameraType = Enum.CameraType.Scriptable
	end
	local started = os.clock()
	local focus = EggConfig.Center + Vector3.new(0, EggConfig.Height * 0.5, 0)
	local glowSound = Audio.Play("EggGlow")
	local cracked = false
	local burst = false
	while os.clock() - started < total and not self.SkipRequested do
		local elapsed = os.clock() - started
		local alpha = elapsed / total
		if contributor then
			local angle = math.rad(def.OrbitDegrees) * alpha
			local position = EggConfig.Center + Vector3.new(math.sin(angle) * def.OrbitRadius, def.OrbitHeight * (0.6 + 0.4 * alpha), -math.cos(angle) * def.OrbitRadius)
			camera.CFrame = CFrame.lookAt(position, focus)
		end
		self:SetGlow(math.clamp(elapsed / def.GlowTime, 0, 1))
		if not cracked and elapsed >= def.GlowTime then
			cracked = true
			Audio.Play("EggCrack")
			EffectController:Shake({ Magnitude = 0.4, Duration = 0.3 })
		end
		if not burst and elapsed >= def.GlowTime + def.CrackTime then
			burst = true
			self:Burst()
		end
		RunService.RenderStepped:Wait()
	end
	if glowSound then
		glowSound:Stop()
	end
	if not burst then
		self:Burst()
	end
	if contributor then
		camera.CameraType = previousType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or previousType
		Ui.Tween(cutscene.Top, 0.3, { Position = UDim2.fromScale(0, -0.12) })
		Ui.Tween(cutscene.Bottom, 0.3, { Position = UDim2.fromScale(0, 1) }).Completed:Wait()
		cutscene.Visible = false
	end
	self.InCutscene = false
	self:RenderHatch()
end

function EggController:Burst()
	Audio.Play("EggBurst")
	Audio.Play("Fanfare")
	EffectController:Shake(EffectsConfig.Shake.Burst)
	local flash = gui.Flash
	flash.BackgroundTransparency = 0.2
	Ui.Tween(flash, 0.6, { BackgroundTransparency = 1 })
	local top = EggConfig.Center + Vector3.new(0, EggConfig.Height, 0)
	EffectController:Burst("Shards", top, 30)
	EffectController:Burst("Confetti", top + Vector3.new(0, 10, 0), 30)
	EffectController:Fireworks(5)
	self:SetGlow(0)
	self:Crack(3)
end

return EggController
