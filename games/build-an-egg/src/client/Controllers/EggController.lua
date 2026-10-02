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
local PropsConfig = require(Shared.Config.Props)
local PetsConfig = require(Shared.Config.Pets)
local UIConfig = require(Shared.Config.UI)
local Format = require(Shared.Util.Format)
local EggShape = require(Shared.Util.EggShape)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)
local Cinematic = require(script.Parent.Parent.Util.Cinematic)

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
local NotifyController
local remotes
local player
local gui
local segments = {}
local ringModels = {}
local steps = {}
local anchors = {}
local arrows = {}
local board
local placeZone
local camera = Workspace.CurrentCamera

function EggController:Init(modules, context)
	ClientState = modules.ClientState
	EffectController = modules.EffectController
	NotifyController = modules.NotifyController
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
		if anchor.Name:find("^Point") then
			table.insert(anchors, anchor)
		end
	end
	placeZone = site.Band:WaitForChild("PlaceZone")
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
		self:RenderPlaceZone()
	end)
	if ClientState.Server then
		self:Render(ClientState.Server, nil)
	end
	if ClientState.State then
		self:RenderTrail(ClientState.State)
	end
	remotes[Names.Remotes.Notify].OnClientEvent:Connect(function(kind)
		if kind == "EggComplete" then
			task.spawn(self.PlayCutscene, self)
		end
	end)
	local hatch = gui:WaitForChild("Hatch")
	Ui.Feel(hatch.Button, function()
		self:Claim()
	end)
	Cinematic.Gui():WaitForChild("Cutscene").Skip.Activated:Connect(function()
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
	elseif previous and server.Ring > previous.Ring then
		task.defer(self.FlashRing, self, previous.Ring)
		self:RevealRamp(previous.Ring, server.Ring)
	end
	if server.Phase == "Interior" and not self.Hatchling and not self.InCutscene then
		self:Crack(EffectsConfig.Cutscene.CrackRings)
		self:HideRampTop(true)
		self:SpawnHatchling(server.Project, false)
	elseif server.Phase == "Building" and self.Hatchling then
		self:RemoveHatchling()
	end
	if visible ~= self.Visible or ring ~= self.Ring or projectChanged then
		local before = self.Visible
		for index, segment in segments do
			local built = index <= visible
			local ghost = not built and segment.Parent:GetAttribute(A.Ring) == ring and server.Phase == "Building"
			if built then
				segment.Transparency = 0
				segment.Color = color:Lerp(Color3.new(1, 1, 1), (segment.Parent:GetAttribute(A.Ring) % 2) * EggConfig.RingShade)
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
				segment.Color = color:Lerp(Color3.new(1, 1, 1), 0.4)
				segment.Material = Enum.Material.SmoothPlastic
				segment.Transparency = EggConfig.GhostTransparency
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
		local offset = ((index - 1) / math.max(count - 1, 1) - 1) * reach
		local point = EggShape.ScaffoldPoint(bandY + offset)
		anchor.CFrame = CFrame.new(point + Vector3.new(0, EggConfig.StandHeight, 0))
		local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = building and prompt.Enabled
		end
	end
	if placeZone then
		local point = EggShape.ScaffoldPoint(bandY)
		placeZone.CFrame = CFrame.new(point + Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, 0, math.rad(90))
		self:RenderPlaceZone()
	end
end

function EggController:RevealRamp(fromRing, toRing)
	local scaffold = Workspace:FindFirstChild(W.Root)
	scaffold = scaffold and scaffold:FindFirstChild(W.Site)
	scaffold = scaffold and scaffold:FindFirstChild(W.Scaffold)
	if not scaffold then
		return
	end
	local revealTime = EggConfig.ScaffoldRevealTime
	for _, piece in scaffold:GetChildren() do
		local index = piece:GetAttribute(A.Ring)
		if index and index > fromRing and index <= toRing and piece:IsA("BasePart") then
			local target = piece.CFrame
			piece.CFrame = target - Vector3.new(0, 4, 0)
			piece.LocalTransparencyModifier = 1
			task.delay((index - fromRing - 1) * revealTime * 0.5, function()
				piece.LocalTransparencyModifier = 0
				Ui.Tween(piece, revealTime, { CFrame = target }, Enum.EasingStyle.Back)
				if piece.Name == "Step" then
					EffectController:Vfx("RampReveal", target.Position)
					Audio.PlayAt("Place", target.Position, 0.8)
				end
			end)
		end
	end
end

function EggController:RenderPlaceZone()
	local state = ClientState.State
	local server = ClientState.Server
	local show = state ~= nil and server ~= nil and state.Carry > 0 and server.Phase == "Building"
	if placeZone then
		placeZone.Transparency = show and 0.45 or 1
		placeZone.Label.Enabled = show
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
	self:AnimateHatchling()
	local t = os.clock()
	if t - (self.LastHatchRender or 0) > 0.5 then
		self.LastHatchRender = t
		self:RenderHatch()
		self:RenderInteriorTimer()
	end
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
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local inside = root ~= nil and root.Position.Y < MapConfig.Interior.Center.Y + MapConfig.Interior.Height + 20
	local show = server.Phase == "Interior" and self:IsContributor() and not self.InCutscene and not (state.Claimed and inside)
	if show and not hatch.Visible then
		hatch.Visible = true
		Ui.Pop(hatch.Button, 1.15)
	elseif not show then
		hatch.Visible = false
	end
	if show then
		Ui.SetText(hatch.Button, state.Claimed and UIConfig.Messages.EnterPrompt or UIConfig.Messages.HatchPrompt)
		hatch.Button.Icon.Text = state.Claimed and "🚪" or "🥚"
		if state.Claimed then
			hatch.Timer.Text = UIConfig.Messages.EnterHint
		else
			local remaining = math.max(0, math.ceil(server.PhaseEndsAt - GameConfig.InteriorDuration + GameConfig.HatchAutoClaimDelay - Workspace:GetServerTimeNow()))
			hatch.Timer.Text = remaining > 0 and ("Auto-hatch in %ds"):format(remaining) or ""
		end
	end
end

function EggController:RenderInteriorTimer()
	local label = gui.Hud:FindFirstChild("InteriorTimer")
	local server = ClientState.Server
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not label or not server then
		return
	end
	local inside = root ~= nil and root.Position.Y < MapConfig.Interior.Center.Y + MapConfig.Interior.Height + 20
	label.Visible = server.Phase == "Interior" and inside
	if label.Visible then
		local remaining = math.max(0, math.ceil(server.PhaseEndsAt - Workspace:GetServerTimeNow()))
		label.Text = UIConfig.Messages.InteriorTimer:format(("%d:%02d"):format(remaining // 60, remaining % 60))
		self.WasInside = true
	end
end

function EggController:Claim()
	if self.Claiming then
		return
	end
	self.Claiming = true
	gui.Hatch.Visible = false
	local inside = EffectsConfig.Cutscene.Inside
	self:Fade(inside.Caption, 0.3)
	local ok, result = remotes[Names.Remotes.ClaimHatch]:InvokeServer()
	task.wait(0.4)
	self:Unfade()
	if ok or result == "Claimed" then
		self.WasInside = true
		Audio.Play("Hatch")
		NotifyController:Banner(inside.Banner, Color3.fromRGB(255, 200, 60))
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			EffectController:Burst("Confetti", root.Position + Vector3.new(0, 4, 0), 30)
		end
	elseif result == "NotContributor" then
		Audio.Play("Error")
	end
	self.Claiming = false
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
	self:HideRampTop(false)
	if self.WasInside then
		self.WasInside = false
		task.spawn(function()
			self:Fade(EffectsConfig.Cutscene.Outside.Caption, 0.8)
			self:Unfade()
		end)
	end
end

function EggController:FocusPoint(name)
	local top = EggConfig.Center + Vector3.new(0, EggShape.ScaffoldHeight(), 0)
	if name == "EggTop" then
		return top
	elseif name == "Hatchling" then
		return self:HatchlingBase().Position + Vector3.new(0, PropsConfig.HatchlingHeight * 0.5, 0)
	end
	return EggConfig.Center + Vector3.new(0, EggShape.ScaffoldHeight() * 0.5, 0)
end

function EggController:HatchlingName(project)
	local def = PropsConfig.Hatchlings[project]
	local species = def and PetsConfig.Species[def.Species]
	return species and string.upper(species.Name) or "BABY"
end

function EggController:Fade(text, hold)
	local fade = Cinematic.Gui().Fade
	local time = EffectsConfig.Cutscene.FadeTime
	fade.Text.Text = text or ""
	Ui.Tween(fade, time, { BackgroundTransparency = 0 })
	Ui.Tween(fade.Text, time, { TextTransparency = 0 }).Completed:Wait()
	task.wait(hold or 0.4)
end

function EggController:Unfade()
	local fade = Cinematic.Gui().Fade
	local time = EffectsConfig.Cutscene.FadeTime
	Ui.Tween(fade.Text, time, { TextTransparency = 1 })
	Ui.Tween(fade, time, { BackgroundTransparency = 1 })
end

function EggController:PlayCutscene()
	local cutscene = Cinematic.Gui().Cutscene
	local def = EffectsConfig.Cutscene
	local server = ClientState.Server
	local project = server and server.Project or "Common"
	EffectController:Shake(EffectsConfig.Shake.LastPiece)
	Audio.Play("LastPiece")
	self.InCutscene = true
	self.SkipRequested = false
	local previousType = camera.CameraType
	Cinematic.Enter()
	cutscene.Visible = true
	Ui.Tween(cutscene.Top, 0.4, { Position = UDim2.fromScale(0, 0) })
	Ui.Tween(cutscene.Bottom, 0.4, { Position = UDim2.fromScale(0, 0.88) })
	camera.CameraType = Enum.CameraType.Scriptable
	self:HideRampTop(true)
	local glowSound
	local burst = false
	for _, shot in def.Shots do
		if self.SkipRequested then
			break
		end
		local caption = shot.Caption
		if caption:find("%%s") then
			caption = caption:format(shot.Burst and self:HatchlingName(project) or string.upper(server and server.ProjectName or "EGG"))
		end
		cutscene.Caption.Text = caption
		Ui.Pop(cutscene.Caption, 1.12)
		if shot.Glow then
			glowSound = Audio.Play("EggGlow")
		end
		if shot.Crack then
			Audio.Play("EggCrack")
			EffectController:Shake({ Magnitude = 0.5, Duration = 0.4 })
		end
		if shot.Burst and not burst then
			burst = true
			self:Burst()
		end
		local started = os.clock()
		while os.clock() - started < shot.Time and not self.SkipRequested do
			local alpha = (os.clock() - started) / shot.Time
			local eased = alpha * alpha * (3 - 2 * alpha)
			local position = shot.From:Lerp(shot.To, eased)
			camera.CFrame = CFrame.lookAt(position, self:FocusPoint(shot.Focus))
			if shot.Glow then
				self:SetGlow(alpha)
			end
			RunService.RenderStepped:Wait()
		end
	end
	if glowSound then
		glowSound:Stop()
	end
	if not burst then
		self:Burst()
	end
	camera.CameraType = previousType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or previousType
	Ui.Tween(cutscene.Top, 0.3, { Position = UDim2.fromScale(0, -0.12) })
	Ui.Tween(cutscene.Bottom, 0.3, { Position = UDim2.fromScale(0, 1) }).Completed:Wait()
	cutscene.Visible = false
	Cinematic.Exit()
	self.InCutscene = false
	self:RenderHatch()
end

function EggController:HideRampTop(hidden)
	local root = Workspace:FindFirstChild(W.Root)
	local site = root and root:FindFirstChild(W.Site)
	local scaffold = site and site:FindFirstChild(W.Scaffold)
	if not scaffold then
		return
	end
	local from = GameConfig.RingCount - EffectsConfig.Cutscene.CrackRings
	for _, piece in scaffold:GetChildren() do
		local ring = piece:GetAttribute(A.Ring)
		if ring and ring > from and piece:IsA("BasePart") then
			piece.LocalTransparencyModifier = hidden and 1 or 0
		end
	end
end

function EggController:Burst()
	Audio.Play("EggBurst")
	Audio.Play("Fanfare")
	EffectController:Shake(EffectsConfig.Shake.Burst)
	local flash = Cinematic.Gui().Flash
	flash.BackgroundTransparency = 0.2
	Ui.Tween(flash, 0.6, { BackgroundTransparency = 1 })
	local top = EggConfig.Center + Vector3.new(0, EggShape.ScaffoldHeight(), 0)
	EffectController:Burst("Shards", top, 30)
	EffectController:Vfx("EggBurst", top)
	EffectController:Vfx("EggGround", EggConfig.Center + Vector3.new(0, 4, 0))
	EffectController:Vfx("EggConfetti", top + Vector3.new(0, 10, 0))
	EffectController:Fireworks(5)
	self:SetGlow(0)
	self:Crack(EffectsConfig.Cutscene.CrackRings)
	if ClientState.Server then
		self:SpawnHatchling(ClientState.Server.Project, true)
	end
end

function EggController:FlashRing(index)
	local ring = ringModels[index]
	local info = EggShape.Rings()[index]
	if not ring or not info then
		return
	end
	local color = self:ProjectColor(ClientState.Server)
	for _, segment in ring:GetChildren() do
		if segment:IsA("BasePart") and segment.Transparency < 1 then
			segment.Material = Enum.Material.Neon
			segment.Color = Color3.new(1, 1, 1)
			Ui.Tween(segment, 0.6, { Color = color })
		end
	end
	local height = (info.Bottom + info.Top) / 2
	local bandPoint = EggShape.ScaffoldPoint(height)
	EffectController:Vfx("RingComplete", bandPoint + Vector3.new(0, 3, 0))
	EffectController:Vfx("RingDust", bandPoint)
	for step = 1, 8 do
		local angle = step / 8 * math.pi * 2
		EffectController:Burst("Sparkle", EggConfig.Center + Vector3.new(math.cos(angle) * info.Radius, height - EggConfig.Center.Y, math.sin(angle) * info.Radius), 6)
	end
	task.delay(0.6, function()
		for _, segment in ring:GetChildren() do
			if segment:IsA("BasePart") and segment.Material == Enum.Material.Neon and segment.Transparency == 0 then
				segment.Material = Enum.Material.SmoothPlastic
			end
		end
	end)
end

function EggController:HatchlingBase()
	local ring = EggShape.Rings()[GameConfig.RingCount - EffectsConfig.Cutscene.CrackRings]
	return CFrame.new(EggConfig.Center.X, ring.Top - PropsConfig.HatchlingHeight * 0.2, EggConfig.Center.Z)
end

function EggController:SpawnHatchling(project, animated)
	self:RemoveHatchling()
	local folder = ReplicatedStorage:FindFirstChild("Hatchlings")
	local template = folder and folder:FindFirstChild(project)
	if not template then
		return
	end
	local model = template:Clone()
	local baseScale = model:GetScale()
	local full = PropsConfig.HatchlingHeight / PropsConfig.HatchlingBaseHeight
	local base = self:HatchlingBase() * template:GetPivot().Rotation
	model:PivotTo(base)
	model.Parent = Workspace
	local state = { Model = model, Base = base, Wings = {}, Ready = false, Started = os.clock() }
	self.Hatchling = state
	local function capture()
		local pivot = model:GetPivot()
		for name in string.gmatch(model:GetAttribute("Wings") or "", "[^,]+") do
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") and part.Name == name then
					local rel = pivot:ToObjectSpace(part.CFrame)
					local side = rel.Position.X >= 0 and 1 or -1
					local hinge = Vector3.new(rel.Position.X - side * math.abs(rel.Position.X) * 0.45, rel.Position.Y, rel.Position.Z)
					table.insert(state.Wings, { Part = part, Rel = rel, Side = side, Hinge = hinge })
				end
			end
		end
		state.Ready = true
	end
	if animated then
		model:ScaleTo(baseScale * full * 0.05)
		task.spawn(function()
			local started = os.clock()
			while os.clock() - started < PropsConfig.HatchlingRise and model.Parent do
				local alpha = (os.clock() - started) / PropsConfig.HatchlingRise
				local eased = 1 - (1 - alpha) ^ 3
				model:ScaleTo(baseScale * full * math.max(0.05, eased * (1 + 0.12 * math.sin(alpha * math.pi))))
				model:PivotTo(base)
				RunService.RenderStepped:Wait()
			end
			if model.Parent then
				model:ScaleTo(baseScale * full)
				model:PivotTo(base)
				Audio.Play("Hatch")
				EffectController:Burst("Sparkle", base.Position + Vector3.new(0, PropsConfig.HatchlingHeight * 0.6, 0), 30)
				EffectController:Vfx("Hatch", base.Position + Vector3.new(0, PropsConfig.HatchlingHeight * 0.6, 0))
				capture()
			end
		end)
	else
		model:ScaleTo(baseScale * full)
		model:PivotTo(base)
		capture()
	end
end

function EggController:RemoveHatchling()
	if self.Hatchling then
		self.Hatchling.Model:Destroy()
		self.Hatchling = nil
	end
end

function EggController:AnimateHatchling()
	local state = self.Hatchling
	if not state or not state.Ready then
		return
	end
	local t = os.clock() - state.Started
	local pivot = state.Base * CFrame.new(0, math.abs(math.sin(t * 2)) * PropsConfig.HatchlingBob, 0) * CFrame.Angles(0, math.sin(t * 0.7) * 0.35, math.sin(t * 2) * 0.04)
	state.Model:PivotTo(pivot)
	local flap = math.rad(PropsConfig.HatchlingFlap) * math.sin(t * 7)
	for _, wing in state.Wings do
		local hinge = CFrame.new(wing.Hinge)
		wing.Part.CFrame = pivot * hinge * CFrame.Angles(0, 0, wing.Side * flap) * hinge:Inverse() * wing.Rel
	end
end

return EggController
