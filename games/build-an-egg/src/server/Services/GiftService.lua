local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local GiftConfig = require(Shared.Config.Gift)
local Names = require(Shared.Config.Names)
local RateLimiter = require(Shared.Util.RateLimiter)

local GiftService = {
	Pending = {},
}

local DataService
local StateService
local CarryService
local remotes

local limiter = RateLimiter.new(GameConfig.RequestRateLimit, GameConfig.RequestRateWindow)

function GiftService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	CarryService = modules.CarryService
	remotes = context.Remotes
end

function GiftService:Start()
	remotes[Names.Remotes.ClaimGift].OnServerInvoke = function(player)
		if not limiter:Check(player) then
			return false, "Busy"
		end
		return self:Claim(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		limiter:Remove(player)
		self.Pending[player] = nil
	end)
end

function GiftService:InGroup(player)
	if not GiftConfig.RequireGroup or GameConfig.GroupId == 0 then
		return true
	end
	local ok, result = pcall(player.IsInGroup, player, GameConfig.GroupId)
	return ok and result
end

function GiftService:Claim(player)
	local data = DataService:Get(player)
	if not data then
		return false, "Busy"
	end
	if data.GiftClaimed or self.Pending[player] then
		return false, "Claimed"
	end
	self.Pending[player] = true
	local inGroup = self:InGroup(player)
	self.Pending[player] = nil
	if not inGroup then
		return false, "Group"
	end
	if data.GiftClaimed or DataService:Get(player) ~= data then
		return false, "Claimed"
	end
	data.GiftClaimed = true
	local rewards = self:Rewards(player, data)
	StateService:Grant(player, { Speed = rewards.Speed, Strength = rewards.Strength, Coins = rewards.Coins })
	local runtime = StateService:Get(player)
	if runtime and rewards.Shells > 0 then
		runtime.Carry += rewards.Shells
		CarryService:UpdateVisual(player)
		StateService:Dirty(player)
	end
	DataService:MarkDirty(player)
	return true, rewards
end

function GiftService:Rewards(player, data)
	local R = GiftConfig.Rewards
	local capacity = StateService:Capacity(player)
	local runtime = StateService:Get(player)
	local free = math.max(0, capacity - (runtime and runtime.Carry or 0))
	return {
		Speed = math.max(R.MinStat, math.floor(data.Speed * R.StatShare)),
		Strength = math.max(R.MinStat, math.floor(data.Strength * R.StatShare)),
		Coins = math.max(R.MinCoins, math.floor(capacity * R.CoinsPerCapacity)),
		Shells = math.min(free, math.max(R.MinShells, math.floor(capacity * R.ShellShare))),
	}
end

return GiftService
