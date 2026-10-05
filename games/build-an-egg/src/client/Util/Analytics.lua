local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Names = require(ReplicatedStorage:WaitForChild("Shared").Config.Names)

local remote = ReplicatedStorage:WaitForChild(Names.RemotesFolder):WaitForChild(Names.Remotes.Funnel)

local Analytics = {}

function Analytics.Track(kind, key)
	remote:FireServer(kind, key)
end

return Analytics
