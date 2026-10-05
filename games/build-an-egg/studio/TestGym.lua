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
		local belt = pad.Parent:FindFirstChild("Belt", true)
		local beltTop = belt and (belt.Position.Y + belt.Size.Y / 2)
		note(stat, "training", StateService:Get(player).Training and StateService:Get(player).Training.Stat, "anchored", root.Anchored)
		note("  root rel pad", rel, "head rel pad", headRel, "look", root.CFrame.LookVector, "up", root.CFrame.UpVector)
		if rackRel then
			note("  rack rel pad", rackRel, "rack transparency while training", rack.Transparency)
		end
		if beltTop then
			local lowest = math.huge
			for _ = 1, 30 do
				for _, name in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
					local foot = character:FindFirstChild(name)
					if foot then
						lowest = math.min(lowest, foot.Position.Y - foot.Size.Y / 2)
					end
				end
				task.wait(0.05)
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			note("  belt top", beltTop, "lowest foot bottom", lowest, "hipHeight", humanoid and humanoid.HipHeight, "rootHalf", root.Size.Y / 2)
		end
		local training = StateService:Get(player).Training
		local waited = 0
		while training and next(training.Bubbles) == nil and waited < 4 do
			task.wait(0.1)
			waited += 0.1
		end
		local id, bubble = next(training and training.Bubbles or {})
		if stat == "Speed" then
			task.wait(2)
		elseif id then
			task.wait(0.2)
			local before = DataService:Get(player)[stat]
			local popped = GymService:PopBubble(player, id)
			note("  bubble", id, bubble.Kind, "popped", popped, "gain", DataService:Get(player)[stat] - before, "double pop", GymService:PopBubble(player, id))
		else
			note("  NO BUBBLE SPAWNED")
		end
		GymService.BubbleSerial += 1
		local fakeId = GymService.BubbleSerial
		training.Bubbles[fakeId] = { Kind = "Rare", Spawned = os.clock() - 5, Expires = os.clock() - 3 }
		note("  expired pop rejected", not GymService:PopBubble(player, fakeId), "bogus id rejected", not GymService:PopBubble(player, "x"))
		task.wait(1)
		GymService:Stop(player, true)
		task.wait(0.5)
		if rack then
			local after = StateService:Get(player).Training
			note("  rack transparency after stop", rack.Transparency, "root anchored", character.HumanoidRootPart.Anchored, "training", after and (after.Stat .. " " .. after.Pad:GetFullName()), "same pad", after and after.Pad == pad, "rel", pad.CFrame:PointToObjectSpace(character.HumanoidRootPart.Position))
		end
	end
end)
if not ok then
	note("TEST ERROR", err)
end
task.wait(0.5)
StudioTestService:EndTest(table.concat(results, "\n"))
