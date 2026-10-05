local CollectionService = game:GetService("CollectionService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		clientLog:FireServer("Error: " .. message)
	end
end)

local player = Players.LocalPlayer
task.spawn(function()
	local layer = player:WaitForChild("PlayerGui"):WaitForChild("Bubbles"):WaitForChild("Layer")
	local controller = require(player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("BubbleController"))
	repeat
		task.wait(0.1)
	until player.Character and player.Character:GetAttribute("Training") == "Speed"
	task.spawn(function()
		local root = player.Character.HumanoidRootPart
		local nearest, nearestDistance
		for _, rib in workspace.Game.Gyms:GetDescendants() do
			if rib.Name == "BeltRib" then
				local distance = (rib.Position - root.Position).Magnitude
				if not nearest or distance < nearestDistance then
					nearest, nearestDistance = rib, distance
				end
			end
		end
		task.wait(1.5)
		local start = nearest and nearest.Position
		task.wait(0.3)
		clientLog:FireServer(("belt rib found %s moved %.2f in 0.3s"):format(tostring(nearest ~= nil), (nearest and start) and (nearest.Position - start).Magnitude or -1))
	end)
	local bubble
	repeat
		task.wait(0.1)
		for _, child in layer:GetChildren() do
			if child.Name:match("^Bubble%d+$") then
				bubble = child
			end
		end
	until bubble
	task.wait(0.4)
	local id = tonumber(bubble.Name:match("%d+"))
	clientLog:FireServer(("bubble ui %s visible %s abs %s pos %s approach %.2f icon %s"):format(bubble.Name, tostring(bubble.Visible), tostring(bubble.AbsoluteSize), tostring(bubble.AbsolutePosition), bubble.Approach.Size.X.Scale, bubble.Icon.Text))
	controller:Pop(id)
	local float
	for _ = 1, 20 do
		task.wait(0.05)
		for _, child in layer:GetChildren() do
			if child.Name == "Float" and child.Visible then
				float = child
			end
		end
		if float then
			break
		end
	end
	clientLog:FireServer("float " .. (float and float.Text or "none") .. " bubble gone " .. tostring(bubble.Parent == nil or bubble.BackgroundTransparency > 0.5))
end)
task.spawn(function()
	local reported = false
	while not reported do
		task.wait(0.3)
		local character = player.Character
		if character and character:GetAttribute("Training") == "Strength" then
			task.wait(1)
			local right = character:FindFirstChild("RightHand")
			local left = character:FindFirstChild("LeftHand")
			local rack, rackDistance
			for _, candidate in CollectionService:GetTagged("RackBarbell") do
				local distance = (candidate.Position - character.HumanoidRootPart.Position).Magnitude
				if not rack or distance < rackDistance then
					rack, rackDistance = candidate, distance
				end
			end
			local held = workspace:FindFirstChild("Barbell")
			local handsMid = (right and left) and (right.Position + left.Position) / 2
			local samples = {}
			for _ = 1, 4 do
				table.insert(samples, right and string.format("%.2f", right.Position.Y) or "?")
				task.wait(0.25)
			end
			clientLog:FireServer(("rack found %s dist %.1f rackLTM while lifting %s held is mesh %s held to hands %.2f rightHand Y %s"):format(tostring(rack ~= nil), rackDistance or -1, rack and tostring(rack.LocalTransparencyModifier) or "-", tostring(held ~= nil and held:IsA("MeshPart")), (held and handsMid) and (held.Position - handsMid).Magnitude or -1, table.concat(samples, ",")))
			repeat
				task.wait(0.05)
			until character:GetAttribute("Training") ~= "Strength"
			task.wait(0.15)
			local midway = workspace:FindFirstChild("Barbell")
			local midDistance = (midway and rack) and (midway.Position - rack.Position).Magnitude or -1
			task.wait(0.8)
			clientLog:FireServer(("after stop: returning dist to rack %.2f, held gone %s, rackLTM %s"):format(midDistance, tostring(workspace:FindFirstChild("Barbell") == nil), rack and tostring(rack.LocalTransparencyModifier) or "-"))
			reported = true
		end
	end
end)
