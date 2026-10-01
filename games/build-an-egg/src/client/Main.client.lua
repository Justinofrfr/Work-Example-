local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local Loader = require(Shared.Util.Loader)

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild(Names.Gui.Main)
local remotes = ReplicatedStorage:WaitForChild(Names.RemotesFolder)
for _, name in Names.Remotes do
	remotes:WaitForChild(name)
end

Loader.Load(script.Parent:WaitForChild("Controllers"), {
	Remotes = remotes,
	Gui = gui,
	Player = player,
})
