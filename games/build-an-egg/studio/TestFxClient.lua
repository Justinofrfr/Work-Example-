local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		clientLog:FireServer("Error: " .. message)
	end
end)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
task.spawn(function()
	local holder = playerGui:WaitForChild("Notify"):WaitForChild("Notifications")
	local alert = playerGui:WaitForChild("Alert"):WaitForChild("MainFrame")
	local layer = playerGui:WaitForChild("Fx"):WaitForChild("ConfettiLayer")
	task.wait(5.6)
	local toasts = {}
	for _, child in holder:GetChildren() do
		if child.Name == "Toast" then
			table.insert(toasts, child.bg.Text .. "@" .. string.format("%.3f", child.Position.Y.Scale) .. " t=" .. string.format("%.2f", child.TextTransparency))
		end
	end
	local alerts = {}
	for _, child in alert:GetChildren() do
		if child:IsA("TextLabel") and child.Text ~= "" then
			table.insert(alerts, child.Name .. ":" .. child.Text .. " t=" .. string.format("%.2f", child.TextTransparency) .. " y=" .. string.format("%.2f", child.Position.Y.Scale))
		end
	end
	local bits = 0
	for _, child in layer:GetChildren() do
		if child.Name == "Bit" and child.Visible then
			bits += 1
		end
	end
	clientLog:FireServer("toasts " .. #toasts .. " " .. table.concat(toasts, " | "))
	clientLog:FireServer("alerts " .. table.concat(alerts, " | "))
	clientLog:FireServer("confetti bits " .. bits)
	local shine = playerGui.Main:FindFirstChild("ShineFX", true)
	clientLog:FireServer("shine frames present " .. tostring(shine ~= nil) .. " bg " .. tostring(playerGui.Overlay.PurchaseBackground.Visible))
end)
