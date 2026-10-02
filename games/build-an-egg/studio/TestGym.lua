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
	local character = player.Character or player.CharacterAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local StateService = require(Services.StateService)
	local GymService = require(Services.GymService)
	while not DataService:Get(player) do
		task.wait(0.2)
	end
	task.wait(2)
	for _, stat in { "Strength", "Speed" } do
		local pad
		for _, candidate in GymService.Pads do
			if candidate:GetAttribute("Tier") == "Gym1" and candidate:GetAttribute("Stat") == stat then
				pad = candidate
				break
			end
		end
		StateService:Teleport(player, pad.CFrame)
		task.wait(1.5)
		local root = character.HumanoidRootPart
		local head = character.Head
		local rel = pad.CFrame:PointToObjectSpace(root.Position)
		local headRel = pad.CFrame:PointToObjectSpace(head.Position)
		local visual = pad.Parent:FindFirstChild("Visual")
		local rack = visual and visual:FindFirstChild("RackBar")
		local rackRel = rack and pad.CFrame:PointToObjectSpace(rack.Position)
		local belt = visual and visual:FindFirstChild("Belt")
		local beltTop = belt and (belt.Position.Y + belt.Size.Y / 2)
		note(stat, "training", StateService:Get(player).Training and StateService:Get(player).Training.Stat, "anchored", root.Anchored)
		note("  root rel pad", rel, "head rel pad", headRel, "look", root.CFrame.LookVector, "up", root.CFrame.UpVector)
		if rackRel then
			note("  rack rel pad", rackRel)
		end
		if beltTop then
			local foot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
			note("  belt top", beltTop, "foot bottom", foot and (foot.Position.Y - foot.Size.Y / 2))
		end
		task.wait(2)
		GymService:Stop(player, true)
		task.wait(0.5)
	end
end)
if not ok then
	note("TEST ERROR", err)
end
task.wait(0.5)
StudioTestService:EndTest(table.concat(results, "\n"))
