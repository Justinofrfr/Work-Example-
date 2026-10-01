local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local Signal = require(Shared.Util.Signal)

local ClientState = {
	State = nil,
	Server = nil,
	StateChanged = Signal.new(),
	ServerChanged = Signal.new(),
}

local remotes

function ClientState:Init(_, context)
	remotes = context.Remotes
end

function ClientState:Start()
	remotes[Names.Remotes.StateSync].OnClientEvent:Connect(function(state)
		local previous = self.State
		self.State = state
		self.StateChanged:Fire(state, previous)
	end)
	remotes[Names.Remotes.ServerSync].OnClientEvent:Connect(function(server)
		local previous = self.Server
		self.Server = server
		self.ServerChanged:Fire(server, previous)
	end)
end

function ClientState:OwnsPass(key)
	return self.State ~= nil and self.State.Passes ~= nil and self.State.Passes[key] == true
end

return ClientState
