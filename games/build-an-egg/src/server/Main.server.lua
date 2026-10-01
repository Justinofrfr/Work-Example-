local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local Loader = require(Shared.Util.Loader)

local remotes = ReplicatedStorage:WaitForChild(Names.RemotesFolder)

Loader.Load(script.Parent:WaitForChild("Services"), {
	Remotes = remotes,
})
