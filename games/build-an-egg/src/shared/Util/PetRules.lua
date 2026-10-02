local Shared = script.Parent.Parent
local PetsConfig = require(Shared.Config.Pets)

local PetRules = {}

function PetRules.FragmentKey(collection: string, tier: number): string
	return collection .. ":" .. tier
end

function PetRules.ParseFragment(key: any): (string?, number?)
	if type(key) ~= "string" then
		return nil, nil
	end
	local collection, tier = key:match("^(%a+):(%d+)$")
	tier = tonumber(tier)
	if not collection or not PetsConfig.Collections[collection] or not tier or not PetsConfig.Rarities[tier] then
		return nil, nil
	end
	return collection, tier
end

function PetRules.Luck(pieces: number): number
	return 1 + PetsConfig.LuckPerLog * math.log10(1 + math.max(pieces, 0))
end

function PetRules.FragmentCount(pieces: number): number
	local rule = PetsConfig.FragmentsPerHatch
	return math.clamp(rule.Base + math.floor(math.log10(1 + math.max(pieces, 0)) * rule.PerLog), 1, rule.Max)
end

function PetRules.TierWeights(luck: number): { number }
	local weights = {}
	for index, rarity in PetsConfig.Rarities do
		weights[index] = rarity.Weight * luck ^ (index - 1)
	end
	return weights
end

function PetRules.Pick(weights: { number }, roll: number): number
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local cursor = roll * total
	for index, weight in weights do
		cursor -= weight
		if cursor <= 0 then
			return index
		end
	end
	return #weights
end

function PetRules.CollectionOdds(collections: { string }): { [string]: number }
	local odds = {}
	for _, collection in collections do
		odds[collection] = (odds[collection] or 0) + 1 / #collections
	end
	return odds
end

function PetRules.Boost(collection: string, rarity: number, stat: string): number
	local def = PetsConfig.Collections[collection]
	local tier = PetsConfig.Rarities[rarity]
	if not def or not tier then
		return 0
	end
	if def.Stat == stat then
		return tier.Boost
	elseif def.Stat == "Both" then
		return tier.Boost * PetsConfig.BothShare
	end
	return 0
end

function PetRules.BoostText(collection: string, rarity: number): string
	local def = PetsConfig.Collections[collection]
	local tier = PetsConfig.Rarities[rarity]
	if not def or not tier then
		return ""
	end
	if def.Stat == "Both" then
		return ("+%d%% Speed & Strength"):format(math.floor(tier.Boost * PetsConfig.BothShare * 100 + 0.5))
	end
	return ("+%d%% %s"):format(math.floor(tier.Boost * 100 + 0.5), def.Stat)
end

function PetRules.Score(collection: string, rarity: number): number
	return PetRules.Boost(collection, rarity, "Speed") + PetRules.Boost(collection, rarity, "Strength")
end

function PetRules.ModelName(collection: string, rarity: number): string
	return collection .. "_" .. rarity
end

return PetRules
