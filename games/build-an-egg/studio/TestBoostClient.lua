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
local playerGui = player:WaitForChild("PlayerGui")

ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bubble").OnClientEvent:Connect(function(action, id, stat, gain)
	if action == "Rainbow" then
		task.wait(0.2)
		local texts = {}
		for _, child in playerGui.Bubbles.Layer:GetChildren() do
			if child.Name == "Float" and child.Visible then
				table.insert(texts, child.Text)
			end
		end
		clientLog:FireServer(("rainbow event id %s stat %s gain %s floats [%s]"):format(tostring(id), tostring(stat), tostring(gain), table.concat(texts, ", ")))
	end
end)

task.wait(4)
local hud = playerGui:WaitForChild("Main"):WaitForChild("Hud")
for _, key in { "SpeedBoost", "StrengthBoost" } do
	local button = hud.Right:FindFirstChild(key)
	if button then
		local center = button.AbsolutePosition + button.AbsoluteSize / 2
		local names = {}
		for index, object in playerGui:GetGuiObjectsAtPosition(center.X, center.Y) do
			if index > 3 then
				break
			end
			table.insert(names, object.Name)
		end
		clientLog:FireServer(("%s visible %s top objects %s"):format(key, tostring(button.Visible), table.concat(names, " > ")))
	end
end
