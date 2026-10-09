local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
ReplicatedStorage:WaitForChild("__TestLog").OnServerEvent:Connect(function(_, message)
	table.insert(results, "[client] " .. message)
end)

local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local StateService = require(Services.StateService)
	local PetService = require(Services.PetService)
	local TutorialConfig = require(ReplicatedStorage.Shared.Config.Tutorial)
	local PetsConfig = require(ReplicatedStorage.Shared.Config.Pets)
	while not DataService:Get(player) do
		task.wait(0.25)
	end
	local data = DataService:Get(player)
	data.TutorialStep = #TutorialConfig.Steps
	data.Coins = 125000
	for collection in PetsConfig.Collections do
		for _ = 1, 3 do
			PetService:GrantFragments(player, collection, 200000)
		end
	end
	data.StarterOffer.Ready = os.time() - 1
	data.StarterOffer.Ends = os.time() + 1800
	StateService:Dirty(player)
end)
if not ok then
	table.insert(results, "TEST ERROR " .. tostring(err))
end
task.wait(tonumber(workspace:GetAttribute("ShotsDuration")) or 70)
StudioTestService:EndTest(table.concat(results, "\n"))
