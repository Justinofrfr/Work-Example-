local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local Names = require(Shared.Config.Names)
local RateLimiter = require(Shared.Util.RateLimiter)
local DailyRules = require(Shared.Util.DailyRules)

local DailyService = {}

local DataService
local StateService
local CarryService
local remotes

local limiter = RateLimiter.new(GameConfig.RequestRateLimit, GameConfig.RequestRateWindow)

function DailyService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	CarryService = modules.CarryService
	remotes = context.Remotes
end

function DailyService:Start()
	remotes[Names.Remotes.ClaimDaily].OnServerInvoke = function(player)
		if not limiter:Check(player) then
			return false, "Busy"
		end
		return self:Claim(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		limiter:Remove(player)
	end)
end

function DailyService:Claim(player)
	local data = DataService:Get(player)
	local runtime = StateService:Get(player)
	if not data or not runtime then
		return false, "Busy"
	end
	local today = DailyRules.Today(os.time())
	local day, ready = DailyRules.NextDay(data.DailyStreak or 0, data.DailyLast or -1, today)
	if not ready then
		return false, "Claimed"
	end
	local reward = DailyRules.Reward(day, StateService:Capacity(player), runtime.Carry, data.Speed, data.Strength)
	data.DailyStreak = day
	data.DailyLast = today
	StateService:Grant(player, { Coins = reward.Coins, Speed = reward.Speed, Strength = reward.Strength })
	if reward.Shells > 0 then
		runtime.Carry += reward.Shells
		CarryService:UpdateVisual(player)
	end
	DataService:MarkDirty(player)
	StateService:Dirty(player)
	return true, day, reward
end

return DailyService
