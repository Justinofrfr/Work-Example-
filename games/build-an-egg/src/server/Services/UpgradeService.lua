local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local UpgradesConfig = require(Shared.Config.Upgrades)
local Names = require(Shared.Config.Names)
local Formulas = require(Shared.Util.Formulas)
local RateLimiter = require(Shared.Util.RateLimiter)

local UpgradeService = {}

local DataService
local StateService
local remotes

local limiter = RateLimiter.new(GameConfig.RequestRateLimit, GameConfig.RequestRateWindow)

function UpgradeService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	remotes = context.Remotes
end

function UpgradeService:Start()
	remotes[Names.Remotes.BuyUpgrade].OnServerInvoke = function(player, key)
		if not limiter:Check(player) then
			return false, "Busy"
		end
		return self:Buy(player, key)
	end
	DataService.Releasing:Connect(function(player)
		limiter:Remove(player)
	end)
end

function UpgradeService:Buy(player, key)
	if type(key) ~= "string" or not UpgradesConfig.List[key] then
		return false, "Invalid"
	end
	local data = DataService:Get(player)
	if not data then
		return false, "Busy"
	end
	local level = data.Upgrades[key] or 0
	local cost = Formulas.UpgradeCost(key, level)
	if not cost then
		return false, "MaxLevel"
	end
	if data.Coins < cost then
		return false, "NotEnough"
	end
	data.Coins -= cost
	data.Upgrades[key] = level + 1
	DataService:MarkDirty(player)
	StateService:Dirty(player)
	return true, level + 1
end

return UpgradeService
