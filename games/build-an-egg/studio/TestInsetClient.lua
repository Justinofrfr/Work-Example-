local GuiService = game:GetService("GuiService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
for _, entry in LogService:GetLogHistory() do
	if entry.messageType == Enum.MessageType.MessageWarning or entry.messageType == Enum.MessageType.MessageError then
		clientLog:FireServer("history " .. entry.messageType.Name .. ": " .. entry.message)
	end
end
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		clientLog:FireServer(messageType.Name .. ": " .. message)
	end
end)

local gui = Players.LocalPlayer.PlayerGui:WaitForChild("Main")
local hud = gui:WaitForChild("Hud")
for _, delay in { 2, 6 } do
	task.wait(delay)
	local inset = GuiService.TopbarInset
	clientLog:FireServer(("t+%d inset min=%s max=%s h=%s | gui insets=%s ignore=%s guiY=%d hudY=%d | topLeft pos=%s abs=%d trainBoostLabel=%s"):format(delay, tostring(inset.Min), tostring(inset.Max), tostring(inset.Height), tostring(gui.ScreenInsets), tostring(gui.IgnoreGuiInset), gui.AbsolutePosition.Y, hud.AbsolutePosition.Y, tostring(hud.TopLeft.Position), hud.TopLeft.AbsolutePosition.Y, tostring(hud:FindFirstChild("TrainBoost") and hud.TrainBoost.Visible)))
end
