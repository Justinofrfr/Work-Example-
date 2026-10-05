local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GymsConfig = require(Shared.Config.Gyms)
local StatsConfig = require(Shared.Config.Stats)
local MapConfig = require(Shared.Config.Map)
local Names = require(Shared.Config.Names)
local Formulas = require(Shared.Util.Formulas)
local RateLimiter = require(Shared.Util.RateLimiter)
local ProductsConfig = require(Shared.Config.Products)

local GymService = {
	BubbleSerial = 0,
	Pads = {},
	Stopped = {},
	LockNotified = {},
	HiddenRacks = {},
}

local DataService
local StateService
local MonetizationService
local BuildService
local remotes

local templates
local stopLimiter = RateLimiter.new(4, 1)
local popLimiter = RateLimiter.new(GymsConfig.Bubbles.PopRate, 1)
local random = Random.new()
local B = GymsConfig.Bubbles
local A = Names.Attributes

function GymService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	MonetizationService = modules.MonetizationService
	BuildService = modules.BuildService
	remotes = context.Remotes
end

function GymService:Start()
	local world = Workspace:WaitForChild(Names.World.Root)
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:GetAttribute(A.Stat) and descendant:GetAttribute(A.Tier) then
			table.insert(self.Pads, descendant)
			CollectionService:AddTag(descendant, "GymPad")
		end
	end
	remotes[Names.Remotes.GymStop].OnServerEvent:Connect(function(player)
		local runtime = StateService:Get(player)
		local swimming = runtime and runtime.Training and runtime.Training.Stat == "Both"
		if stopLimiter:Check(player) and not swimming then
			self:Stop(player, true)
		end
	end)
	remotes[Names.Remotes.PopBubble].OnServerEvent:Connect(function(player, id)
		if popLimiter:Check(player) then
			self:PopBubble(player, id)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		popLimiter:Remove(player)
		self.Stopped[player] = nil
		self.LockNotified[player] = nil
		stopLimiter:Remove(player)
	end)
	task.spawn(function()
		while true do
			task.wait(GymsConfig.PadCheckInterval)
			for player, runtime in StateService.Runtime do
				self:CheckPlayer(player, runtime)
			end
			for pad, owner in self.HiddenRacks do
				local runtime = StateService.Runtime[owner]
				if not owner.Parent or not runtime or not runtime.Training or runtime.Training.Pad ~= pad then
					self:SetRack(pad, true)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(StatsConfig.RepInterval)
			for player, runtime in StateService.Runtime do
				if runtime.Training then
					self:Rep(player, runtime.Training)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(B.Tick)
			local now = os.clock()
			for player, runtime in StateService.Runtime do
				if runtime.Training then
					self:TickBubbles(player, runtime.Training, now)
				end
			end
		end
	end)
end

function GymService:TickBubbles(player, training, now)
	local active = 0
	for id, bubble in training.Bubbles do
		if now > bubble.Expires + B.Grace then
			training.Bubbles[id] = nil
		else
			active += 1
		end
	end
	local rainbow = B.Rainbow
	local rainbowProduct = ProductsConfig.DevProducts[B.Kinds[rainbow.Kind].Product]
	if training.NextRainbow and now >= training.NextRainbow then
		training.NextRainbow = now + random:NextNumber(rainbow.Every[1], rainbow.Every[2])
		if self:TrainBoost(player) == 1 and rainbowProduct and (rainbowProduct.Id ~= 0 or RunService:IsStudio()) then
			self.BubbleSerial += 1
			local id = self.BubbleSerial
			training.Bubbles[id] = { Kind = rainbow.Kind, Spawned = now, Expires = now + B.Kinds[rainbow.Kind].Lifetime, Offer = true }
			local runtime = StateService:Get(player)
			if runtime then
				runtime.RainbowOffer = { Id = id, Stat = training.Stat, Multiplier = training.Multiplier }
			end
			remotes[Names.Remotes.Bubble]:FireClient(player, "Spawn", id, rainbow.Kind)
			return
		end
	end
	if now < training.NextBubble or active >= B.MaxActive then
		return
	end
	training.NextBubble = now + random:NextNumber(B.Interval[1], B.Interval[2])
	local kind = "Normal"
	local roll = random:NextNumber()
	for _, key in B.Special do
		local chance = B.Kinds[key].Chance
		if roll < chance then
			kind = key
			break
		end
		roll -= chance
	end
	self.BubbleSerial += 1
	local id = self.BubbleSerial
	training.Bubbles[id] = { Kind = kind, Spawned = now, Expires = now + B.Kinds[kind].Lifetime }
	remotes[Names.Remotes.Bubble]:FireClient(player, "Spawn", id, kind)
end

function GymService:PopBubble(player, id)
	local runtime = StateService:Get(player)
	local training = runtime and runtime.Training
	local bubble = training and type(id) == "number" and training.Bubbles[id]
	if not bubble then
		return false
	end
	training.Bubbles[id] = nil
	local now = os.clock()
	if bubble.Offer or now > bubble.Expires + B.Grace or now - bubble.Spawned < B.MinReaction then
		return false
	end
	local amount = StatsConfig.BaseGainPerRep * training.Multiplier * B.Kinds[bubble.Kind].Reps * self:TrainBoost(player)
	local gain
	if training.Stat == "Both" then
		gain = StateService:AwardStat(player, "Speed", amount)
		StateService:AwardStat(player, "Strength", amount)
	else
		gain = StateService:AwardStat(player, training.Stat, amount)
	end
	remotes[Names.Remotes.Bubble]:FireClient(player, "Popped", id, training.Stat, gain)
	return true
end

function GymService:RainbowReward(player, multiplier)
	local runtime = StateService:Get(player)
	local offer = runtime and (runtime.RainbowOffer or runtime.Training)
	local stat = offer and offer.Stat or B.Rainbow.DefaultStat
	local amount = StatsConfig.BaseGainPerRep * (offer and offer.Multiplier or 1) * B.Kinds[B.Rainbow.Kind].RewardReps * multiplier
	if runtime then
		runtime.RainbowOffer = nil
	end
	local gain
	if stat == "Both" then
		gain = StateService:AwardStat(player, "Speed", amount)
		StateService:AwardStat(player, "Strength", amount)
	else
		gain = StateService:AwardStat(player, stat, amount)
	end
	return stat, gain, offer and offer.Id
end

function GymService:TrainBoost(player)
	local data = DataService:Get(player)
	local product = ProductsConfig.DevProducts.TrainBoost20
	if data and (data.TrainBoostUntil or 0) > os.time() then
		return product.TrainMultiplier
	end
	return 1
end

function GymService:TierUnlocked(player, tier)
	local data = DataService:Get(player)
	if not data then
		return false
	end
	return data.Eggs >= tier.RequiredEggs or MonetizationService:OwnsPass(player, tier.PassKey)
end

function GymService:BestMultiplier(player)
	local best = 1
	for _, tier in GymsConfig.Tiers do
		if self:TierUnlocked(player, tier) and tier.Multiplier > best then
			best = tier.Multiplier
		end
	end
	return best
end

function GymService:PadAt(position)
	for _, pad in self.Pads do
		local localPosition = pad.CFrame:PointToObjectSpace(position)
		local half = pad.Size / 2
		if math.abs(localPosition.X) <= half.X and math.abs(localPosition.Z) <= half.Z and math.abs(localPosition.Y) <= half.Y + GymsConfig.PadMargin then
			return pad
		end
	end
	return nil
end

function GymService:CheckPlayer(player, runtime)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		if runtime.Training then
			self:Stop(player, false)
		end
		return
	end
	local pad = self:PadAt(rootPart.Position)
	if self.Stopped[player] and self.Stopped[player] ~= pad and humanoid.FloorMaterial ~= Enum.Material.Air then
		self.Stopped[player] = nil
	end
	if self.LockNotified[player] and self.LockNotified[player] ~= pad then
		self.LockNotified[player] = nil
	end
	local training = runtime.Training
	if training and training.Pad == pad then
		return
	end
	if training then
		self:Stop(player, false)
	end
	if pad and self.Stopped[player] ~= pad then
		self:Begin(player, runtime, pad)
	end
end

function GymService:Begin(player, runtime, pad)
	local stat = pad:GetAttribute(A.Stat)
	local tierKey = pad:GetAttribute(A.Tier)
	local multiplier
	if tierKey == "Interior" then
		if BuildService.Phase ~= "Interior" then
			return
		end
		multiplier = GymsConfig.InteriorMultiplier * self:BestMultiplier(player)
	else
		local tier = Formulas.GymTier(tierKey)
		if not tier then
			return
		end
		if not self:TierUnlocked(player, tier) then
			if self.LockNotified[player] ~= pad then
				self.LockNotified[player] = pad
				remotes[Names.Remotes.Notify]:FireClient(player, "GymLocked", tier.Key)
			end
			return
		end
		multiplier = tier.Multiplier
	end
	runtime.Training = {
		Pad = pad,
		Stat = stat,
		Tier = tierKey,
		Multiplier = multiplier,
		Bubbles = {},
		NextBubble = os.clock() + B.FirstDelay,
		NextRainbow = os.clock() + B.Rainbow.FirstDelay,
	}
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart and templates and stat ~= "Both" then
		local aura = templates:FindFirstChild(Names.Templates.TrainAura)
		if aura and not rootPart:FindFirstChild(Names.Templates.TrainAura) then
			local clone = aura:Clone()
			local emitter = clone:FindFirstChildOfClass("ParticleEmitter")
			if emitter then
				emitter.Color = ColorSequence.new(MapConfig.TierColors[tierKey] or Color3.new(1, 1, 1))
			end
			clone.Parent = rootPart
		end
	end
	if character then
		character:SetAttribute(A.Training, stat)
	end
	if rootPart and stat ~= "Both" then
		self:Snap(player, rootPart, pad, stat)
	end
	StateService:ApplyWalkSpeed(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "TrainStart", stat, tierKey)
end

function GymService:SetRack(pad, visible, owner)
	local machine = pad and pad.Parent
	if not machine then
		return
	end
	self.HiddenRacks[pad] = not visible and owner or nil
	for _, descendant in machine:GetDescendants() do
		if descendant:IsA("BasePart") and GymsConfig.RackParts[descendant.Name] then
			if descendant:GetAttribute("RackTransparency") == nil then
				descendant:SetAttribute("RackTransparency", descendant.Transparency)
			end
			descendant.Transparency = visible and descendant:GetAttribute("RackTransparency") or 1
		end
	end
end

function GymService:Snap(player, rootPart, pad, stat)
	local floor = pad.CFrame * CFrame.new(0, -pad.Size.Y / 2, 0)
	local target
	if stat == "Strength" then
		local seat = pad.Parent:FindFirstChildWhichIsA("Seat", true)
		local top = seat and (seat.Position.Y + seat.Size.Y / 2) or (floor.Position.Y + GymsConfig.BenchHeight)
		local position = Vector3.new(floor.Position.X, top + GymsConfig.LieHeightOffset, floor.Position.Z)
		target = CFrame.fromMatrix(position, -pad.CFrame.RightVector, pad.CFrame.LookVector)
	else
		local position = floor.Position + Vector3.new(0, GymsConfig.TreadmillStandHeight, 0)
		local belt = pad.Parent:FindFirstChild("Belt", true)
		local humanoid = rootPart.Parent:FindFirstChildOfClass("Humanoid")
		if belt and humanoid then
			local hip = humanoid.RigType == Enum.HumanoidRigType.R15 and humanoid.HipHeight or GymsConfig.R6HipHeight
			position = Vector3.new(belt.Position.X, belt.Position.Y + belt.Size.Y / 2 + hip + rootPart.Size.Y / 2, belt.Position.Z)
		end
		target = CFrame.lookAt(position, position + pad.CFrame.LookVector)
	end
	if stat == "Strength" then
		self:SetRack(pad, false, player)
	end
	StateService:Teleport(player, target)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.Anchored = true
end

function GymService:Release(player, pad)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart.Anchored then
		return
	end
	rootPart.Anchored = false
	if pad and (rootPart.Position - pad.Position).Magnitude <= pad.Size.Magnitude + GymsConfig.StepOffDistance then
		local height = -pad.Size.Y / 2 + 3
		local offsets = {
			Vector3.new(0, height, pad.Size.Z / 2 + GymsConfig.StepOffDistance),
			Vector3.new(0, height, -(pad.Size.Z / 2 + GymsConfig.StepOffDistance)),
			Vector3.new(pad.Size.X / 2 + GymsConfig.StepOffDistance, height, 0),
			Vector3.new(-(pad.Size.X / 2 + GymsConfig.StepOffDistance), height, 0),
		}
		local chosen = pad.CFrame * offsets[1]
		for _, offset in offsets do
			local candidate = pad.CFrame * offset
			if not self:PadAt(candidate) then
				chosen = candidate
				break
			end
		end
		local away = Vector3.new(chosen.X - pad.Position.X, 0, chosen.Z - pad.Position.Z)
		StateService:Teleport(player, CFrame.lookAt(chosen, chosen + (away.Magnitude > 0.01 and away.Unit or pad.CFrame.LookVector)))
	end
end

function GymService:Stop(player, byJump)
	local runtime = StateService:Get(player)
	if not runtime or not runtime.Training then
		return
	end
	local pad = runtime.Training.Pad
	if byJump then
		self.Stopped[player] = pad
	end
	runtime.Training = nil
	if player.Parent then
		remotes[Names.Remotes.Bubble]:FireClient(player, "Clear")
	end
	self:SetRack(pad, true)
	self:Release(player, pad)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local aura = rootPart and rootPart:FindFirstChild(Names.Templates.TrainAura)
	if aura then
		aura:Destroy()
	end
	if character then
		character:SetAttribute(A.Training, nil)
	end
	StateService:ApplyWalkSpeed(player)
	StateService:Dirty(player)
end

function GymService:Rep(player, training)
	if training.Tier == "Interior" and BuildService.Phase ~= "Interior" then
		self:Stop(player, false)
		return
	end
	local gain = StatsConfig.BaseGainPerRep * training.Multiplier * self:TrainBoost(player)
	if training.Stat == "Both" then
		StateService:AwardStat(player, "Speed", gain)
		StateService:AwardStat(player, "Strength", gain)
	else
		StateService:AwardStat(player, training.Stat, gain)
	end
end

function GymService:CheckUnlocks(player, before, after)
	for _, tier in GymsConfig.Tiers do
		if before < tier.RequiredEggs and after >= tier.RequiredEggs and not MonetizationService:OwnsPass(player, tier.PassKey) then
			remotes[Names.Remotes.Notify]:FireClient(player, "GymUnlocked", tier.Key)
		end
	end
end

return GymService
