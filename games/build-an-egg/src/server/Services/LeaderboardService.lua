local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local LeaderboardsConfig = require(Shared.Config.Leaderboards)
local Names = require(Shared.Config.Names)
local Format = require(Shared.Util.Format)

local LeaderboardService = {
	Stores = {},
	NameCache = {},
}

local DataService

function LeaderboardService:Init(modules)
	DataService = modules.DataService
end

function LeaderboardService:Start()
	if RunService:IsStudio() and not GameConfig.SaveInStudio then
		return
	end
	for _, board in LeaderboardsConfig.Boards do
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, LeaderboardsConfig.StorePrefix .. board.Key)
		if ok then
			self.Stores[board.Key] = store
		end
	end
	DataService.Releasing:Connect(function(player)
		self:Submit(player)
	end)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				self:Submit(player)
			end
			self:Refresh()
			task.wait(LeaderboardsConfig.RefreshInterval)
		end
	end)
end

function LeaderboardService:Submit(player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	for _, board in LeaderboardsConfig.Boards do
		local store = self.Stores[board.Key]
		local value = math.floor(tonumber(data[board.Field]) or 0)
		if store and value > 0 then
			pcall(store.SetAsync, store, tostring(player.UserId), value)
		end
	end
end

function LeaderboardService:DisplayName(userId)
	local cached = self.NameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	cached = ok and name or "???"
	self.NameCache[userId] = cached
	return cached
end

function LeaderboardService:Refresh()
	local world = Workspace:FindFirstChild(Names.World.Root)
	local spawnFolder = world and world:FindFirstChild(Names.World.Spawn)
	local boards = spawnFolder and spawnFolder:FindFirstChild("Leaderboards")
	if not boards then
		return
	end
	for _, board in LeaderboardsConfig.Boards do
		local store = self.Stores[board.Key]
		local part = boards:FindFirstChild(board.Key)
		local list = part and part:FindFirstChild("List", true)
		if store and list then
			local ok, pages = pcall(store.GetSortedAsync, store, false, LeaderboardsConfig.Rows)
			if ok then
				local entries = pages:GetCurrentPage()
				for rank = 1, LeaderboardsConfig.Rows do
					local row = list:FindFirstChild("Row" .. rank)
					local entry = entries[rank]
					if row then
						row.Visible = entry ~= nil
						if entry then
							row.Player.Text =("#%d %s"):format(rank, self:DisplayName(tonumber(entry.key)))
							row.Value.Text = Format.Short(entry.value)
						end
					end
				end
			end
		end
	end
end

return LeaderboardService
