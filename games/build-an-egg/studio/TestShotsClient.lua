local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
local player = Players.LocalPlayer
local controllers = player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")
local PanelController = require(controllers.PanelController)

local order = { "Shop", "Upgrades", "Pets", "Incubator", "Settings", "Codes", "StarterOffer", "Daily" }
task.wait(tonumber(workspace:GetAttribute("ShotsLead")) or 12)
for index, name in order do
	PanelController:Open(name)
	clientLog:FireServer(("t=%.1f open %s"):format(workspace.DistributedGameTime, name))
	task.wait(tonumber(workspace:GetAttribute("ShotsStep")) or 6)
end
PanelController:Close()
