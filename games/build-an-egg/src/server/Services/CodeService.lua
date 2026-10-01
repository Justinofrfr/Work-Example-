local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local CodesConfig = require(Shared.Config.Codes)
local Names = require(Shared.Config.Names)
local RateLimiter = require(Shared.Util.RateLimiter)

local CodeService = {
	Pending = {},
}

local DataService
local StateService
local remotes

local globalStore
local limiter = RateLimiter.new(GameConfig.RequestRateLimit, GameConfig.RequestRateWindow)

function CodeService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	remotes = context.Remotes
	local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, GameConfig.GlobalStoreName)
	globalStore = ok and store or nil
end

function CodeService:Start()
	remotes[Names.Remotes.RedeemCode].OnServerInvoke = function(player, text)
		if not limiter:Check(player) then
			return false, "Busy"
		end
		return self:Redeem(player, text)
	end
	DataService.Releasing:Connect(function(player)
		limiter:Remove(player)
		self.Pending[player] = nil
	end)
end

function CodeService:Normalize(text)
	if type(text) ~= "string" or #text == 0 or #text > GameConfig.CodeMaxLength then
		return nil
	end
	return (text:gsub("%s+", "")):upper()
end

function CodeService:ClaimGlobalUse(code, maxUses)
	if not globalStore then
		return false
	end
	for attempt = 1, GameConfig.DataLoadRetries do
		local ok, result = pcall(function()
			local accepted = false
			globalStore:UpdateAsync("code_" .. code, function(current)
				current = tonumber(current) or 0
				if current >= maxUses then
					accepted = false
					return nil
				end
				accepted = true
				return current + 1
			end)
			return accepted
		end)
		if ok then
			return result
		end
		task.wait(GameConfig.DataRetryDelay * attempt)
	end
	return nil
end

function CodeService:Redeem(player, text)
	local code = self:Normalize(text)
	local definition = code and CodesConfig[code]
	if not definition or definition.Active == false then
		return false, "Invalid"
	end
	local data = DataService:Get(player)
	if not data or self.Pending[player] then
		return false, "Busy"
	end
	if data.Codes[code] then
		return false, "Claimed"
	end
	if definition.Expires and os.time() > definition.Expires then
		return false, "Expired"
	end
	self.Pending[player] = true
	if definition.MaxUses then
		local accepted = self:ClaimGlobalUse(code, definition.MaxUses)
		if accepted == nil then
			self.Pending[player] = nil
			return false, "Busy"
		elseif not accepted then
			self.Pending[player] = nil
			return false, "Expired"
		end
	end
	if not DataService:Get(player) then
		self.Pending[player] = nil
		return false, "Busy"
	end
	data.Codes[code] = true
	StateService:Grant(player, definition.Rewards)
	DataService:MarkDirty(player)
	self.Pending[player] = nil
	return true, definition.Rewards
end

return CodeService
