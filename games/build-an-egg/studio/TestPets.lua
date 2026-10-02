local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
local function note(...)
	local parts = {}
	for _, value in { ... } do
		table.insert(parts, tostring(value))
	end
	table.insert(results, table.concat(parts, " "))
end

ReplicatedStorage:WaitForChild("__TestLog").OnServerEvent:Connect(function(_, message)
	note("[client]", message)
end)

local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	player.CharacterAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local PetService = require(Services.PetService)
	while not DataService:Get(player) do
		task.wait(0.2)
	end
	task.wait(2)
	local data = DataService:Get(player)
	PetService:GrantFragments(player, "Silver", 5000)
	local total = 0
	for _, count in data.Fragments do
		total += count
	end
	note("granted fragments", total)
	data.Fragments = { ["Silver:1"] = 3, ["Golden:1"] = 2, ["Gem:2"] = 1 }
	note("mixed tiers rejected", tostring((PetService:HatchFragments(player, { "Silver:1", "Silver:1", "Silver:1", "Golden:1", "Gem:2" }))))
	note("not enough rejected", tostring((PetService:HatchFragments(player, { "Silver:1", "Silver:1", "Silver:1", "Silver:1", "Golden:1" }))))
	local hatched, pet = PetService:HatchFragments(player, { "Silver:1", "Silver:1", "Silver:1", "Golden:1", "Golden:1" })
	note("hatch", tostring(hatched), pet and pet.Collection, pet and pet.Rarity, "left", data.Fragments["Silver:1"], data.Fragments["Golden:1"])
	for _ = 1, 4 do
		PetService:AddPet(player, data, "Golden", 1)
	end
	local ids = {}
	for _, owned in data.Pets do
		if owned.Rarity == 1 then
			table.insert(ids, owned.Id)
		end
	end
	local traded, better = PetService:TradeUp(player, { ids[1], ids[2], ids[3], ids[4], ids[5] })
	note("trade up", tostring(traded), better and better.Collection, better and better.Rarity, "pets", #data.Pets, "equipped", #data.Equipped)
	PetService:EquipBest(player)
	note("equip best", #data.Equipped, "attr", player:GetAttribute("Pets"))
	note("multipliers speed", PetService:Multiplier(player, "Speed"), "strength", PetService:Multiplier(player, "Strength"))
	task.wait(4)
end)
if not ok then
	note("TEST ERROR", err)
end
StudioTestService:EndTest(table.concat(results, "\n"))
