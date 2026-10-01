local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local StatsConfig = require(Shared.Config.Stats)
local Signal = require(Shared.Util.Signal)

local DataService = {
	Profiles = {},
	Loaded = Signal.new(),
	Releasing = Signal.new(),
}

local store

local function template()
	return {
		Version = 1,
		Coins = StatsConfig.StartingStats.Coins,
		Speed = StatsConfig.StartingStats.Speed,
		Strength = StatsConfig.StartingStats.Strength,
		Eggs = 0,
		PiecesPlaced = 0,
		Upgrades = { BulkPickup = 0, BulkPlace = 0, Range = 0 },
		BoostLevels = { SpeedBoost = 0, StrengthBoost = 0 },
		Codes = {},
		GiftClaimed = false,
		Purchases = {},
	}
end

local function reconcile(data, base)
	for key, value in base do
		if data[key] == nil then
			data[key] = type(value) == "table" and table.clone(value) or value
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
	return data
end

local function waitForBudget(requestType)
	local waited = 0
	while DataStoreService:GetRequestBudgetForRequestType(requestType) < 1 and waited < 10 do
		task.wait(0.5)
		waited += 0.5
	end
end

local function retry(fn)
	local lastErr
	for attempt = 1, GameConfig.DataLoadRetries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(GameConfig.DataRetryDelay * attempt)
	end
	return false, lastErr
end

local function key(player)
	return "u_" .. player.UserId
end

function DataService:Init()
	local ok, result = pcall(function()
		local candidate = DataStoreService:GetDataStore(GameConfig.DataStoreName)
		if RunService:IsStudio() then
			candidate:GetAsync("__probe")
		end
		return candidate
	end)
	store = ok and result or nil
	if not ok then
		warn("[DataService] DataStore unavailable, running without saves: " .. tostring(result))
	end
end

function DataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayer(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(self.LoadPlayer, self, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		self:ReleasePlayer(player)
	end)
	game:BindToClose(function()
		local pending = 0
		for player in self.Profiles do
			pending += 1
			task.spawn(function()
				self:ReleasePlayer(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveInterval)
			for player, profile in self.Profiles do
				if profile.Dirty then
					task.spawn(self.Save, self, player, false)
				end
			end
		end
	end)
end

function DataService:LoadPlayer(player)
	local data
	if store then
		waitForBudget(Enum.DataStoreRequestType.UpdateAsync)
		local ok, result = retry(function()
			return store:UpdateAsync(key(player), function(current)
				current = current or template()
				local lock = current.SessionLock
				if lock and lock.JobId ~= game.JobId and os.time() - lock.Time < GameConfig.SessionLockTimeout then
					return nil
				end
				current.SessionLock = { JobId = game.JobId, Time = os.time() }
				return current
			end)
		end)
		if not ok or result == nil then
			if player.Parent then
				player:Kick("Your data is still loading in another server. Please rejoin in a moment.")
			end
			return
		end
		data = result
	else
		data = template()
	end
	if not player.Parent then
		return
	end
	reconcile(data, template())
	self.Profiles[player] = { Data = data, Dirty = false }
	self.Loaded:Fire(player, data)
end

function DataService:Save(player, release)
	local profile = self.Profiles[player]
	if not profile or not store then
		return
	end
	local data = profile.Data
	waitForBudget(Enum.DataStoreRequestType.UpdateAsync)
	local ok, err = retry(function()
		return store:UpdateAsync(key(player), function(current)
			if current and current.SessionLock and current.SessionLock.JobId ~= game.JobId then
				return nil
			end
			local copy = table.clone(data)
			copy.SessionLock = not release and { JobId = game.JobId, Time = os.time() } or nil
			return copy
		end)
	end)
	if ok then
		profile.Dirty = false
	else
		warn("[DataService] save failed for " .. player.UserId .. ": " .. tostring(err))
	end
end

function DataService:ReleasePlayer(player)
	if not self.Profiles[player] then
		return
	end
	self.Releasing:Fire(player)
	self:Save(player, true)
	self.Profiles[player] = nil
end

function DataService:Get(player)
	local profile = self.Profiles[player]
	return profile and profile.Data
end

function DataService:MarkDirty(player)
	local profile = self.Profiles[player]
	if profile then
		profile.Dirty = true
	end
end

function DataService:Add(player, field, amount)
	local data = self:Get(player)
	if not data or type(data[field]) ~= "number" then
		return
	end
	data[field] += amount
	self:MarkDirty(player)
end

return DataService
