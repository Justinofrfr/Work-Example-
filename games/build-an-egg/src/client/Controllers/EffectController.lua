local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local EffectsConfig = require(Shared.Config.Effects)
local EggConfig = require(Shared.Config.Egg)
local MapConfig = require(Shared.Config.Map)
local GameConfig = require(Shared.Config.Game)
local EggShape = require(Shared.Util.EggShape)

local Settings = require(script.Parent.Parent.Util.Settings)
local Audio = require(script.Parent.Parent.Util.Audio)

local EffectController = {
	ShakeUntil = 0,
	ShakeMagnitude = 0,
	LastTick = 0,
}

local ClientState
local remotes
local player
local particles
local templates
local fxPart
local popupPool = {}
local popupIndex = 0
local music
local finalMusic
local ambience
local camera = Workspace.CurrentCamera

function EffectController:Init(modules, context)
	ClientState = modules.ClientState
	remotes = context.Remotes
	player = context.Player
	particles = ReplicatedStorage:WaitForChild(Names.Effects.Folder):WaitForChild(Names.Effects.Particles)
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
end

function EffectController:Start()
	fxPart = Workspace:WaitForChild(Names.World.Root):WaitForChild(Names.World.Site):WaitForChild("FxAnchor")
	local popup = templates:WaitForChild(Names.Templates.CoinPopup)
	for index = 1, EffectsConfig.CoinPopup.PoolSize do
		local attachment = fxPart:FindFirstChild("Popup" .. index)
		if attachment then
			local clone = popup:Clone()
			clone.Enabled = false
			clone.Adornee = attachment
			clone.Parent = attachment
			popupPool[index] = { Gui = clone, Attachment = attachment }
		end
	end
	remotes[Names.Remotes.Effect].OnClientEvent:Connect(function(kind, ...)
		self:Handle(kind, ...)
	end)
	ClientState.ServerChanged:Connect(function(server, previous)
		self:OnServer(server, previous)
	end)
	Settings.Changed:Connect(function(key)
		if key == "Music" then
			self:UpdateMusic()
		end
	end)
	RunService:BindToRenderStep("EggShake", Enum.RenderPriority.Camera.Value + 1, function()
		self:ApplyShake()
	end)
	music = Audio.Loop("Music")
	finalMusic = Audio.Loop("MusicFinal")
	ambience = Audio.Loop("Ambience")
	if ambience then
		ambience:Play()
	end
	self:UpdateMusic()
end

function EffectController:Root()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function EffectController:Burst(name, position, count)
	local scale = Settings:EffectScale()
	if scale <= 0 or not fxPart then
		return
	end
	if (camera.CFrame.Position - position).Magnitude > EffectsConfig.Particles.CullDistance * 3 then
		return
	end
	local template = particles:FindFirstChild(name)
	if not template then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Parent = fxPart
	attachment.WorldPosition = position
	local emitter = template:Clone()
	emitter.Parent = attachment
	emitter:Emit(math.max(1, math.floor(math.min(count, EffectsConfig.Particles.MaxPerBurst) * scale)))
	Debris:AddItem(attachment, emitter.Lifetime.Max + 0.5)
end

function EffectController:CoinPopup(position, amount)
	if #popupPool == 0 then
		return
	end
	popupIndex = popupIndex % #popupPool + 1
	local entry = popupPool[popupIndex]
	local config = EffectsConfig.CoinPopup
	entry.Attachment.WorldPosition = position
	local label = entry.Gui:FindFirstChild("Text")
	label.Text = "+" .. amount
	label.TextTransparency = 0
	entry.Gui.StudsOffsetWorldSpace = Vector3.zero
	entry.Gui.Enabled = true
	local started = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local alpha = (os.clock() - started) / config.Duration
		if alpha >= 1 or entry.Gui:GetAttribute("Token") ~= started then
			if entry.Gui:GetAttribute("Token") == started then
				entry.Gui.Enabled = false
			end
			connection:Disconnect()
			return
		end
		entry.Gui.StudsOffsetWorldSpace = Vector3.new(0, config.Rise * alpha, 0)
		label.TextTransparency = alpha * alpha
	end)
	entry.Gui:SetAttribute("Token", started)
end

function EffectController:Shake(def)
	if not Settings:Get("Shake") or not def then
		return
	end
	local root = self:Root()
	if root and def.Range and (root.Position - EggConfig.Center).Magnitude > def.Range then
		return
	end
	self.ShakeMagnitude = def.Magnitude
	self.ShakeUntil = os.clock() + def.Duration
end

function EffectController:ApplyShake()
	local remaining = self.ShakeUntil - os.clock()
	if remaining <= 0 then
		return
	end
	local magnitude = self.ShakeMagnitude * math.clamp(remaining * 4, 0, 1)
	local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * magnitude
	camera.CFrame = camera.CFrame * CFrame.new(offset)
end

function EffectController:Fireworks(count)
	task.spawn(function()
		for index = 1, count do
			local angle = index / count * math.pi * 2
			local position = EggConfig.Center + Vector3.new(math.cos(angle) * 60, EggConfig.Height + 40, math.sin(angle) * 60)
			self:Burst("Firework", position, 30)
			Audio.PlayAt("Milestone", position, 1.4)
			task.wait(0.25)
		end
	end)
end

function EffectController:ShellRain()
	if Settings:EffectScale() <= 0 then
		return
	end
	local config = EffectsConfig.ShellRain
	local quarry = Workspace:FindFirstChild(Names.World.Root)
	quarry = quarry and quarry:FindFirstChild(Names.World.Quarry)
	local pieces = quarry and quarry:FindFirstChild(Names.World.Pieces)
	local sample = pieces and pieces:FindFirstChildWhichIsA("BasePart")
	if not sample then
		return
	end
	local center = MapConfig.Quarry.Center
	local size = MapConfig.Quarry.Size
	task.spawn(function()
		local spawned = 0
		local started = os.clock()
		while os.clock() - started < config.Duration do
			if spawned < config.MaxParts * Settings:EffectScale() then
				spawned += 1
				local piece = sample:Clone()
				for _, child in piece:GetChildren() do
					if child:IsA("ProximityPrompt") then
						child:Destroy()
					end
				end
				piece.Anchored = false
				piece.CanCollide = true
				piece.CanQuery = false
				piece.Color = Color3.fromRGB(255, 205, 60)
				piece.Material = Enum.Material.Neon
				piece.CFrame = CFrame.new(center + Vector3.new(math.random(-size.X / 2, size.X / 2), config.Height, math.random(-size.Z / 2, size.Z / 2)))
				piece.Parent = fxPart
				Debris:AddItem(piece, 6)
			end
			task.wait(config.Interval)
		end
	end)
end

function EffectController:Handle(kind, a, b)
	local root = self:Root()
	if kind == "Pickup" then
		if root then
			Audio.PlayAt("Pickup", root.Position, 1 + 0.05 * math.max(0, (a or 1) - 1))
			self:Burst("Dust", root.Position - Vector3.new(0, 2.5, 0), 6)
		end
	elseif kind == "Place" then
		local ring = b or 1
		local pitch = EffectsConfig.Sounds.Place.PitchMin + (EffectsConfig.Sounds.Place.PitchMax - EffectsConfig.Sounds.Place.PitchMin) * (ring - 1) / math.max(GameConfig.RingCount - 1, 1)
		if root then
			Audio.PlayAt("Place", root.Position, pitch)
			Audio.Play("Coin")
			self:CoinPopup(root.Position + Vector3.new(0, 3, 0), a or 1)
			local bandPoint = EggShape.ScaffoldPoint(EggShape.BandHeight(ring))
			local direction = Vector3.new(bandPoint.X - EggConfig.Center.X, 0, bandPoint.Z - EggConfig.Center.Z).Unit
			local shellRadius = EggShape.Rings()[ring].Radius
			self:Burst("Dust", EggConfig.Center + direction * shellRadius + Vector3.new(0, EggShape.BandHeight(ring) - EggConfig.Center.Y, 0), 8)
		end
	elseif kind == "TrainStart" then
		Audio.Play("TrainStart")
		if root then
			self:Burst("Sparkle", root.Position, 8)
		end
	end
end

function EffectController:OnServer(server, previous)
	local fraction = server.Target > 0 and server.Progress / server.Target or 0
	if previous and previous.Round == server.Round and server.Phase == "Building" then
		if server.Ring > previous.Ring then
			Audio.Play("RingComplete")
		end
		if fraction >= EffectsConfig.CountdownFraction and server.Progress > previous.Progress and os.clock() - self.LastTick >= 1 then
			self.LastTick = os.clock()
			Audio.Play("Countdown")
		end
	end
	self.FinalStretch = server.Phase == "Building" and fraction >= EffectsConfig.FinalMusicFraction
	self:UpdateMusic()
end

function EffectController:UpdateMusic()
	local enabled = Settings:Get("Music")
	local final = self.FinalStretch == true
	local key = tostring(enabled) .. tostring(final)
	if key == self.MusicKey then
		return
	end
	self.MusicKey = key
	for _, entry in { { music, enabled and not final }, { finalMusic, enabled and final } } do
		local sound, wanted = entry[1], entry[2]
		if sound then
			if wanted and not sound.IsPlaying then
				sound.Volume = 0
				sound:Play()
			end
			local target = wanted and (EffectsConfig.Sounds[sound.Name] and EffectsConfig.Sounds[sound.Name].Volume or 0.3) or 0
			local tween = game:GetService("TweenService"):Create(sound, TweenInfo.new(EffectsConfig.MusicCrossfade), { Volume = target })
			tween:Play()
			if not wanted then
				tween.Completed:Once(function()
					if sound.Volume == 0 then
						sound:Stop()
					end
				end)
			end
		end
	end
end

return EffectController
