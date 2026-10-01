local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProductsConfig = require(Shared.Config.Products)
local Names = require(Shared.Config.Names)
local Signal = require(Shared.Util.Signal)

local MonetizationService = {
	PassCache = {},
	PassChanged = Signal.new(),
}

local DataService
local StateService
local BuildService
local remotes

local productLookup = {}

local function buildLookup()
	for key, product in ProductsConfig.DevProducts do
		if product.Tiers then
			for level, tier in product.Tiers do
				if tier.Id ~= 0 then
					productLookup[tier.Id] = { Key = key, Level = level }
				end
			end
		elseif product.Id ~= 0 then
			productLookup[product.Id] = { Key = key }
		end
	end
end

function MonetizationService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	BuildService = modules.BuildService
	remotes = context.Remotes
	buildLookup()
end

function MonetizationService:Start()
	DataService.Loaded:Connect(function(player)
		self:RefreshPasses(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.PassCache[player] = nil
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			for key, pass in ProductsConfig.GamePasses do
				if pass.Id == passId then
					self.PassCache[player] = self.PassCache[player] or {}
					self.PassCache[player][key] = true
					StateService:Dirty(player)
					self.PassChanged:Fire(player, key)
					remotes[Names.Remotes.Notify]:FireClient(player, "PassOwned", key)
				end
			end
		end
	end)
	MarketplaceService.ProcessReceipt = function(receipt)
		return self:ProcessReceipt(receipt)
	end
end

function MonetizationService:RefreshPasses(player)
	local owned = {}
	for key, pass in ProductsConfig.GamePasses do
		if pass.Id ~= 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			owned[key] = ok and has or false
		else
			owned[key] = false
		end
	end
	if not player.Parent then
		return
	end
	self.PassCache[player] = owned
	StateService:Dirty(player)
	self.PassChanged:Fire(player)
end

function MonetizationService:OwnsPass(player, key)
	if not key then
		return false
	end
	local cache = self.PassCache[player]
	return cache ~= nil and cache[key] == true
end

function MonetizationService:OwnedPasses(player)
	return self.PassCache[player] or {}
end

function MonetizationService:NextTierId(player, key)
	local data = DataService:Get(player)
	local product = ProductsConfig.DevProducts[key]
	if not data or not product or not product.Tiers then
		return nil
	end
	local level = data.BoostLevels[key] or 0
	local tier = product.Tiers[math.min(level + 1, #product.Tiers)]
	return tier and tier.Id ~= 0 and tier.Id or nil
end

function MonetizationService:ProcessReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService:Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(data.Purchases, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local entry = productLookup[receipt.ProductId]
	if not entry then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local product = ProductsConfig.DevProducts[entry.Key]
	local previousLevel = data.BoostLevels[entry.Key]
	local coinsGranted = 0
	if product.Tiers then
		data.BoostLevels[entry.Key] = (previousLevel or 0) + 1
	elseif product.Pieces then
		coinsGranted = product.Coins or 0
		data.Coins += coinsGranted
	end
	table.insert(data.Purchases, receipt.PurchaseId)
	while #data.Purchases > ProductsConfig.PurchaseHistoryCap do
		table.remove(data.Purchases, 1)
	end
	DataService:MarkDirty(player)
	if not DataService:Save(player, false) then
		local index = table.find(data.Purchases, receipt.PurchaseId)
		if index then
			table.remove(data.Purchases, index)
		end
		if product.Tiers then
			data.BoostLevels[entry.Key] = previousLevel
		else
			data.Coins -= coinsGranted
		end
		StateService:Dirty(player)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if product.Pieces then
		BuildService:AddPieces(player, product.Pieces, true)
		remotes[Names.Remotes.Notify]:FireAllClients("ServerPack", player.DisplayName, product.Pieces)
	end
	StateService:Dirty(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

return MonetizationService
