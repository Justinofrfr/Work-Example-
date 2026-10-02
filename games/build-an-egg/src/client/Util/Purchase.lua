local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Shared").Util.Signal)

local Purchase = {
	Prompted = Signal.new(),
	Finished = Signal.new(),
	Active = nil,
}

local player = Players.LocalPlayer

local function begin(kind, id)
	Purchase.Active = { Kind = kind, Id = id, At = os.clock() }
	Purchase.Prompted:Fire(kind, id)
end

local function finish(kind, id, purchased)
	Purchase.Active = nil
	Purchase.Finished:Fire(kind, id, purchased == true)
end

function Purchase.Product(id)
	if type(id) ~= "number" or id == 0 then
		return false
	end
	begin("Product", id)
	local ok = pcall(function()
		MarketplaceService:PromptProductPurchase(player, id)
	end)
	if not ok then
		finish("Product", id, false)
	end
	return ok
end

function Purchase.Pass(id)
	if type(id) ~= "number" or id == 0 then
		return false
	end
	begin("Pass", id)
	local ok = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, id)
	end)
	if not ok then
		finish("Pass", id, false)
	end
	return ok
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
	if userId == player.UserId then
		finish("Product", productId, purchased)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(buyer, passId, purchased)
	if buyer == player then
		finish("Pass", passId, purchased)
	end
end)

return Purchase
