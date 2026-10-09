local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Shared").Util.Signal)

local Prices = {
	Cache = {},
	Pending = {},
	Changed = Signal.new(),
}

function Prices.Get(id, fallback, infoType)
	if not id or id == 0 then
		return fallback
	end
	local cached = Prices.Cache[id]
	if cached then
		return cached
	end
	if not Prices.Pending[id] then
		Prices.Pending[id] = true
		task.spawn(function()
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType or Enum.InfoType.Product)
			if ok and info and info.PriceInRobux then
				Prices.Cache[id] = info.PriceInRobux
				Prices.Changed:Fire(id)
			end
		end)
	end
	return fallback
end

return Prices
