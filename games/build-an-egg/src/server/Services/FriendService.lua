local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)

local FriendService = {
	Pairs = {},
}

local DataService
local StateService

local function pairKey(a, b)
	local x, y = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	return x .. ":" .. y
end

function FriendService:Init(modules)
	DataService = modules.DataService
	StateService = modules.StateService
end

function FriendService:Start()
	DataService.Loaded:Connect(function(player)
		for _, other in Players:GetPlayers() do
			if other ~= player then
				local key = pairKey(player, other)
				if self.Pairs[key] == nil then
					local ok, friends = pcall(player.IsFriendsWith, player, other.UserId)
					self.Pairs[key] = ok and friends or false
				end
			end
		end
		self:Recompute()
	end)
	Players.PlayerRemoving:Connect(function(player)
		for key in self.Pairs do
			if key:find(tostring(player.UserId), 1, true) then
				self.Pairs[key] = nil
			end
		end
		task.defer(self.Recompute, self)
	end)
end

function FriendService:Recompute()
	local players = Players:GetPlayers()
	for _, player in players do
		local runtime = StateService:Get(player)
		if runtime then
			local friends = 0
			for _, other in players do
				if other ~= player and self.Pairs[pairKey(player, other)] then
					friends += 1
				end
			end
			local boost = math.min(friends * GameConfig.FriendBoostPerFriend, GameConfig.FriendBoostMax)
			if runtime.FriendBoost ~= boost then
				runtime.FriendBoost = boost
				StateService:Dirty(player)
			end
		end
	end
end

return FriendService
