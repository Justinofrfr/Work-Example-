local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
local player = Players.LocalPlayer
local controllers = player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")
local PanelController = require(controllers.PanelController)

local custom = workspace:GetAttribute("ShotsOrder")
local order = custom and string.split(custom, ",") or { "Shop", "Upgrades", "Pets", "Incubator", "Settings", "Codes", "StarterOffer", "Daily" }
task.wait(tonumber(workspace:GetAttribute("ShotsLead")) or 12)
for index, entry in order do
	local name, tab = table.unpack(string.split(entry, ":"))
	PanelController:Open(name)
	if tab then
		require(controllers.ShopController):Select(tonumber(tab))
	end
	clientLog:FireServer(("t=%.1f open %s"):format(workspace.DistributedGameTime, name))
	task.wait(tonumber(workspace:GetAttribute("ShotsStep")) or 6)
end
PanelController:Close()
