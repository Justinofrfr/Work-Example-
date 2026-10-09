local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProductsConfig = require(Shared.Config.Products)
local TutorialConfig = require(Shared.Config.Tutorial)

local OfferService = {}

local DataService
local StateService

local OFFER = ProductsConfig.StarterOffer

local function unlockStep()
	for index, step in TutorialConfig.Steps do
		if step.Key == OFFER.AfterStep then
			return index
		end
	end
	return #TutorialConfig.Steps
end

local UNLOCK_STEP = unlockStep()

function OfferService:Init(modules)
	DataService = modules.DataService
	StateService = modules.StateService
end

function OfferService:Start()
	DataService.Loaded:Connect(function(player)
		self:Check(player)
	end)
end

function OfferService:Check(player)
	local data = DataService:Get(player)
	local offer = data and data.StarterOffer
	if not offer or offer.Ready > 0 or offer.Bought or (data.TutorialStep or 0) < UNLOCK_STEP then
		return
	end
	offer.Ready = os.time() + OFFER.Delay
	offer.Ends = offer.Ready + OFFER.Window
	DataService:MarkDirty(player)
	StateService:Dirty(player)
end

function OfferService:MarkBought(player, key)
	local data = DataService:Get(player)
	if not data or key ~= OFFER.Product then
		return nil
	end
	local previous = data.StarterOffer.Bought
	data.StarterOffer.Bought = true
	return previous
end

return OfferService
