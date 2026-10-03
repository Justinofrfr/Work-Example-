local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local PetsConfig = require(Shared.Config.Pets)
local Names = require(Shared.Config.Names)
local PetRules = require(Shared.Util.PetRules)
local RateLimiter = require(Shared.Util.RateLimiter)

local PetService = {}

local DataService
local StateService
local BuildService
local remotes
local random = Random.new()
local limiter = RateLimiter.new(GameConfig.RequestRateLimit, GameConfig.RequestRateWindow)
local A = Names.Attributes

function PetService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	BuildService = modules.BuildService
	remotes = context.Remotes
end

function PetService:Start()
	DataService.Loaded:Connect(function(player)
		self:Apply(player)
	end)
	BuildService.HatchStarted:Connect(function(key)
		for _, player in Players:GetPlayers() do
			if BuildService:IsContributor(player) then
				self:GrantFragments(player, key, BuildService:Contribution(player))
			end
		end
	end)
	remotes[Names.Remotes.Incubate].OnServerInvoke = function(player, mode, selection)
		if not limiter:Check(player) then
			return false, "Busy"
		end
		if mode == "Fragments" then
			return self:HatchFragments(player, selection)
		elseif mode == "Pets" then
			return self:TradeUp(player, selection)
		end
		return false, "Invalid"
	end
	remotes[Names.Remotes.PetAction].OnServerInvoke = function(player, action, id)
		if not limiter:Check(player) then
			return false, "Busy"
		end
		if action == "Equip" then
			return self:Equip(player, id)
		elseif action == "Unequip" then
			return self:Unequip(player, id)
		elseif action == "EquipBest" then
			return self:EquipBest(player)
		elseif action == "Delete" then
			return self:Delete(player, id)
		end
		return false, "Invalid"
	end
	Players.PlayerRemoving:Connect(function(player)
		limiter:Remove(player)
	end)
end

local function findPet(data, id)
	if type(id) ~= "number" then
		return nil, nil
	end
	for index, pet in data.Pets do
		if pet.Id == id then
			return pet, index
		end
	end
	return nil, nil
end

function PetService:Multiplier(player, stat)
	local data = DataService:Get(player)
	if not data then
		return 1
	end
	local bonus = 0
	for _, id in data.Equipped do
		local pet = findPet(data, id)
		if pet then
			bonus += PetRules.Boost(pet.Collection, pet.Rarity, stat)
		end
	end
	return 1 + bonus
end

function PetService:Apply(player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local keys = {}
	for _, id in data.Equipped do
		local pet = findPet(data, id)
		if pet then
			table.insert(keys, PetRules.ModelName(pet.Collection, pet.Rarity))
		end
	end
	player:SetAttribute(A.Pets, table.concat(keys, ","))
	StateService:Dirty(player)
end

function PetService:GrantFragments(player, collection, pieces)
	local data = DataService:Get(player)
	if not data or not PetsConfig.Collections[collection] then
		return
	end
	local weights = PetRules.TierWeights(PetRules.Luck(pieces))
	local count = PetRules.FragmentCount(pieces)
	if not data.FirstHatchBonus and #data.Pets == 0 then
		data.FirstHatchBonus = true
		count = math.max(count, PetsConfig.FirstHatchFragments)
	end
	local granted = {}
	for _ = 1, count do
		local key = PetRules.FragmentKey(collection, PetRules.Pick(weights, random:NextNumber()))
		data.Fragments[key] = math.min((data.Fragments[key] or 0) + 1, PetsConfig.MaxFragments)
		granted[key] = (granted[key] or 0) + 1
	end
	DataService:MarkDirty(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Notify]:FireClient(player, "Fragments", count, granted)
end

function PetService:AddPet(player, data, collection, rarity)
	data.PetSerial = (data.PetSerial or 0) + 1
	local pet = { Id = data.PetSerial, Collection = collection, Rarity = rarity }
	table.insert(data.Pets, pet)
	if #data.Equipped < PetsConfig.EquipSlots then
		table.insert(data.Equipped, pet.Id)
	end
	DataService:MarkDirty(player)
	self:Apply(player)
	return pet
end

function PetService:HatchFragments(player, selection)
	local data = DataService:Get(player)
	if not data then
		return false, "Busy"
	end
	if type(selection) ~= "table" or #selection ~= PetsConfig.Inputs then
		return false, "NeedFive"
	end
	if #data.Pets >= PetsConfig.MaxPets then
		return false, "PetsFull"
	end
	local needed = {}
	local picks = {}
	for index = 1, PetsConfig.Inputs do
		local key = selection[index]
		local collection, keyTier = PetRules.ParseFragment(key)
		if not collection or not keyTier then
			return false, "NeedFive"
		end
		needed[key] = (needed[key] or 0) + 1
		table.insert(picks, { Collection = collection, Tier = keyTier })
	end
	for key, amount in needed do
		if (data.Fragments[key] or 0) < amount then
			return false, "NotEnough"
		end
	end
	for key, amount in needed do
		data.Fragments[key] -= amount
		if data.Fragments[key] <= 0 then
			data.Fragments[key] = nil
		end
	end
	local chosen = picks[random:NextInteger(1, #picks)]
	local pet = self:AddPet(player, data, chosen.Collection, chosen.Tier)
	return true, pet
end

function PetService:TradeUp(player, selection)
	local data = DataService:Get(player)
	if not data then
		return false, "Busy"
	end
	if type(selection) ~= "table" or #selection ~= PetsConfig.Inputs then
		return false, "NeedFive"
	end
	local seen = {}
	local collections = {}
	local rarity
	for index = 1, PetsConfig.Inputs do
		local id = selection[index]
		local pet = findPet(data, id)
		if not pet or seen[id] or (rarity and pet.Rarity ~= rarity) then
			return false, "NeedFive"
		end
		seen[id] = true
		rarity = pet.Rarity
		table.insert(collections, pet.Collection)
	end
	if rarity >= #PetsConfig.Rarities then
		return false, "MaxRarity"
	end
	for id in seen do
		local _, index = findPet(data, id)
		table.remove(data.Pets, index)
		local equippedIndex = table.find(data.Equipped, id)
		if equippedIndex then
			table.remove(data.Equipped, equippedIndex)
		end
	end
	local chosen = collections[random:NextInteger(1, #collections)]
	local pet = self:AddPet(player, data, chosen, rarity + 1)
	return true, pet
end

function PetService:Equip(player, id)
	local data = DataService:Get(player)
	if not data or not findPet(data, id) then
		return false, "Invalid"
	end
	if table.find(data.Equipped, id) then
		return true
	end
	if #data.Equipped >= PetsConfig.EquipSlots then
		return false, "SlotsFull"
	end
	table.insert(data.Equipped, id)
	DataService:MarkDirty(player)
	self:Apply(player)
	return true
end

function PetService:Unequip(player, id)
	local data = DataService:Get(player)
	if not data then
		return false, "Busy"
	end
	local index = table.find(data.Equipped, id)
	if index then
		table.remove(data.Equipped, index)
		DataService:MarkDirty(player)
		self:Apply(player)
	end
	return true
end

function PetService:EquipBest(player)
	local data = DataService:Get(player)
	if not data then
		return false, "Busy"
	end
	local sorted = table.clone(data.Pets)
	table.sort(sorted, function(a, b)
		return PetRules.Score(a.Collection, a.Rarity) > PetRules.Score(b.Collection, b.Rarity)
	end)
	data.Equipped = {}
	for index = 1, math.min(PetsConfig.EquipSlots, #sorted) do
		table.insert(data.Equipped, sorted[index].Id)
	end
	DataService:MarkDirty(player)
	self:Apply(player)
	return true
end

function PetService:Delete(player, id)
	local data = DataService:Get(player)
	if not data then
		return false, "Busy"
	end
	local _, index = findPet(data, id)
	if not index then
		return false, "Invalid"
	end
	table.remove(data.Pets, index)
	local equippedIndex = table.find(data.Equipped, id)
	if equippedIndex then
		table.remove(data.Equipped, equippedIndex)
	end
	DataService:MarkDirty(player)
	self:Apply(player)
	return true
end

return PetService
