local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
task.wait(8)
local fx = workspace.Game.Site.FxAnchor
local attachments, guis = 0, 0
for _, child in fx:GetChildren() do
	if child.Name:match("^Popup") then
		attachments += 1
		if child:FindFirstChildOfClass("BillboardGui") then
			guis += 1
		end
	end
end
clientLog:FireServer(("attachments %d with gui %d"):format(attachments, guis))
local EffectController = require(player.PlayerScripts.Client.Controllers.EffectController)
EffectController:Handle("Pickup", 12)
RunService.Heartbeat:Wait()
local enabled = {}
for _, gui in fx:GetDescendants() do
	if gui:IsA("BillboardGui") and gui.Enabled then
		local label = gui:FindFirstChild("Text")
		table.insert(enabled, ("%s text=%s size=%s pos=%s dist=%.1f"):format(gui.Parent.Name, label and label.Text or "?", tostring(gui.Size), tostring(gui.Parent.WorldPosition), (gui.Parent.WorldPosition - root.Position).Magnitude))
	end
end
clientLog:FireServer("enabled after pickup: " .. #enabled .. " " .. table.concat(enabled, " | "))
clientLog:FireServer("done")
