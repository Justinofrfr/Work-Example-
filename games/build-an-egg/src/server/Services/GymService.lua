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

local GymService = {
	Pads = {},
	Stopped = {},
	LockNotified = {},
}

local DataService
local StateService
local MonetizationService
local BuildService
local remotes

local templates
local stopLimiter = RateLimiter.new(4, 1)
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
		if stopLimiter:Check(player) then
			self:Stop(player, true)
		end
	end)
	DataService.Releasing:Connect(function(player)
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
	if self.Stopped[player] and self.Stopped[player] ~= pad then
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
		if BuildService.Phase ~= "Interior" or not BuildService:IsContributor(player) then
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
	StateService:ApplyWalkSpeed(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "TrainStart", stat, tierKey)
end

function GymService:Stop(player, byJump)
	local runtime = StateService:Get(player)
	if not runtime or not runtime.Training then
		return
	end
	if byJump then
		self.Stopped[player] = runtime.Training.Pad
	end
	runtime.Training = nil
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
	local gain = StatsConfig.BaseGainPerRep * training.Multiplier
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
