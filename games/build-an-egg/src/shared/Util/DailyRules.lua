local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DailyConfig = require(Shared.Config.Daily)

local DailyRules = {}

function DailyRules.Today(now: number): number
	return math.floor(now / DailyConfig.DayLength)
end

function DailyRules.NextDay(streak: number, last: number, today: number): (number, boolean)
	if last == today then
		return streak % #DailyConfig.Days + 1, false
	elseif last == today - 1 then
		return streak % #DailyConfig.Days + 1, true
	end
	return 1, true
end

function DailyRules.Reward(day: number, capacity: number, carry: number, speed: number, strength: number)
	local def = DailyConfig.Days[day]
	local free = math.max(0, capacity - carry)
	local reward = {
		Coins = math.floor(math.max(DailyConfig.BaseCoins, capacity * DailyConfig.CoinsPerCapacity) * def.Coins),
		Shells = math.min(free, math.max(DailyConfig.MinShells, math.floor(capacity * def.Shells))),
		Speed = 0,
		Strength = 0,
	}
	if def.Stats > 0 then
		reward.Speed = math.max(DailyConfig.MinStat, math.floor(speed * def.Stats))
		reward.Strength = math.max(DailyConfig.MinStat, math.floor(strength * def.Stats))
	end
	return reward
end

return DailyRules
