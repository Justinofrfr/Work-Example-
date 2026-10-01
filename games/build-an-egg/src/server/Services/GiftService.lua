local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local GiftConfig = require(Shared.Config.Gift)
local Names = require(Shared.Config.Names)
local RateLimiter = require(Shared.Util.RateLimiter)

local GiftService = {}

local DataService
local StateService
local remotes

local limiter = RateLimiter.new(GameConfig.RequestRateLimit, GameConfig.RequestRateWindow)

function GiftService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	remotes = context.Remotes
end

function GiftService:Start()
	remotes[Names.Remotes.ClaimGift].OnServerInvoke = function(player)
		if not limiter:Check(player) then
			return false, "Busy"
		end
		return self:Claim(player)
	end
	DataService.Releasing:Connect(function(player)
		limiter:Remove(player)
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
	if data.GiftClaimed then
		return false, "Claimed"
	end
	if not self:InGroup(player) then
		return false, "Group"
	end
	data.GiftClaimed = true
	StateService:Grant(player, GiftConfig.Rewards)
	DataService:MarkDirty(player)
	return true, GiftConfig.Rewards
end

return GiftService
