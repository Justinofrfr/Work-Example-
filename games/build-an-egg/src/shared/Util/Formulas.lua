local Shared = script.Parent.Parent
local StatsConfig = require(Shared.Config.Stats)
local UpgradesConfig = require(Shared.Config.Upgrades)
local ProductsConfig = require(Shared.Config.Products)
local GymsConfig = require(Shared.Config.Gyms)
local RanksConfig = require(Shared.Config.Ranks)
local GameConfig = require(Shared.Config.Game)

local Formulas = {}

function Formulas.WalkSpeed(speed: number): number
	return math.min(StatsConfig.BaseWalkSpeed + StatsConfig.WalkSpeedCoefficient * math.log10(1 + math.max(speed, 0) / StatsConfig.WalkSpeedDivisor), StatsConfig.MaxWalkSpeed)
end

function Formulas.Capacity(strength: number): number
	return StatsConfig.BaseCarry + math.floor(strength * StatsConfig.CarryPerStrength)
end

function Formulas.UpgradeValue(key: string, level: number): number
	local upgrade = UpgradesConfig.List[key]
	if not upgrade then
		return 0
	end
	return level * upgrade.PerLevel
end

function Formulas.UpgradeCost(key: string, level: number): number?
	local upgrade = UpgradesConfig.List[key]
	if not upgrade then
		return nil
	end
	return upgrade.Costs[level + 1]
end

function Formulas.PickupAmount(level: number): number
	return 1 + Formulas.UpgradeValue("BulkPickup", level)
end

function Formulas.PlaceAmount(level: number): number
	return 1 + Formulas.UpgradeValue("BulkPlace", level)
end

function Formulas.PromptDistance(rangeLevel: number): number
	return GameConfig.BasePromptDistance * (1 + Formulas.UpgradeValue("Range", rangeLevel))
end

function Formulas.BoostValue(key: string, level: number): number
	local product = ProductsConfig.DevProducts[key]
	if not product or not product.Multiplier then
		return 1
	end
	return product.Multiplier ^ level
end

function Formulas.BoostLabel(key: string, level: number): string
	local product = ProductsConfig.DevProducts[key]
	if not product or not product.Tiers then
		return ""
	end
	if level >= #product.Tiers then
		return ("MAX %dx %s"):format(Formulas.BoostValue(key, level), product.Stat)
	end
	return ("%dx %s"):format(Formulas.BoostValue(key, level + 1), product.Stat)
end

function Formulas.GymTier(key: string)
	for _, tier in GymsConfig.Tiers do
		if tier.Key == key then
			return tier
		end
	end
	return nil
end

function Formulas.Rank(eggs: number)
	local current = RanksConfig[1]
	for _, rank in RanksConfig do
		if eggs >= rank.RequiredEggs then
			current = rank
		end
	end
	return current
end

function Formulas.NextRank(eggs: number)
	for _, rank in RanksConfig do
		if eggs < rank.RequiredEggs then
			return rank
		end
	end
	return nil
end

return Formulas
