local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
ReplicatedStorage:WaitForChild("__TestLog").OnServerEvent:Connect(function(_, message)
	table.insert(results, "[client] " .. tostring(message))
end)

local hold = workspace:GetAttribute("PoseHold") or 40
local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local character = player.Character or player.CharacterAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local StateService = require(Services.StateService)
	local GymService = require(Services.GymService)
	while not DataService:Get(player) do
		task.wait(0.2)
	end
	task.wait(2)
	for _, pad in GymService.Pads do
		if pad:GetAttribute("Tier") == "Gym1" and pad:GetAttribute("Stat") == "Strength" then
			StateService:Teleport(player, pad.CFrame)
			break
		end
	end
	task.wait(hold)
	table.insert(results, "held " .. hold .. " training " .. tostring(character:GetAttribute("Training")))
end)
if not ok then
	table.insert(results, "TEST ERROR " .. tostring(err))
end
StudioTestService:EndTest(table.concat(results, "\n"))
