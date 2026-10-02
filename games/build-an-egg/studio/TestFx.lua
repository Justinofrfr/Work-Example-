local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	task.wait(4)
	local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")
	notify:FireClient(player, "Toast", "First toast")
	task.wait(0.3)
	notify:FireClient(player, "Toast", "Second toast")
	task.wait(0.3)
	notify:FireClient(player, "Purchased", "Golden Goose")
	task.wait(0.4)
	notify:FireClient(player, "Purchased", "+1,000 Shells")
	task.wait(5)
end)
if not ok then
	note("TEST ERROR", err)
end
StudioTestService:EndTest(table.concat(results, "\n"))
