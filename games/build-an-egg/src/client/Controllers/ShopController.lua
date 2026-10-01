local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProductsConfig = require(Shared.Config.Products)
local ShopConfig = require(Shared.Config.Shop)
local UIConfig = require(Shared.Config.UI)

local Ui = require(script.Parent.Parent.Util.Ui)

local ShopController = {
	Cards = {},
}

local ClientState
local PanelController
local NotifyController
local player
local list
local templates

function ShopController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	NotifyController = modules.NotifyController
	player = context.Player
	list = PanelController:Get("Shop").Body.List
	templates = context.Gui:WaitForChild("Templates")
end

function ShopController:Start()
	for sectionIndex, section in ShopConfig.Sections do
		local block = templates.ShopSection:Clone()
		block.Visible = true
		block.Name = section.Title
		block.LayoutOrder = sectionIndex
		block.Title.Text = section.Title
		block.Parent = list
		for itemIndex, item in section.Items do
			local card = templates.ShopItem:Clone()
			card.Visible = true
			card.Name = item.Key
			card.LayoutOrder = itemIndex
			card.Icon.Text = item.Icon
			card.Title.Text = item.Name
			card.Desc.Text = item.Desc
			card.Parent = block.Grid
			Ui.Feel(card.Buy, function()
				self:Buy(item)
			end)
			self.Cards[item.Key] = { Card = card, Item = item }
		end
	end
	self:Refresh()
	ClientState.StateChanged:Connect(function()
		self:Refresh()
	end)
end

function ShopController:ProductInfo(item)
	if item.Kind == "Pass" then
		local pass = ProductsConfig.GamePasses[item.Key]
		return pass.Id, pass.Price
	end
	local product = ProductsConfig.DevProducts[item.Key]
	if product.Tiers then
		local state = ClientState.State
		local level = state and state.BoostLevels and state.BoostLevels[item.Key] or 0
		local tier = product.Tiers[math.min(level + 1, #product.Tiers)]
		return tier.Id, tier.Price
	end
	return product.Id, product.Price
end

function ShopController:Refresh()
	for key, entry in self.Cards do
		local _, price = self:ProductInfo(entry.Item)
		local owned = entry.Item.Kind == "Pass" and ClientState:OwnsPass(key)
		Ui.SetText(entry.Card.Buy, owned and "OWNED" or ("R$" .. price))
		Ui.SetColor(entry.Card.Buy, owned and UIConfig.Colors.Locked or UIConfig.Colors.Robux)
		if entry.Item.Kind == "Product" and ProductsConfig.DevProducts[key].Tiers then
			local state = ClientState.State
			local level = state and state.BoostLevels and state.BoostLevels[key] or 0
			entry.Card.Title.Text = entry.Item.Name .. (level > 0 and (" (x" .. level .. ")") or "")
		end
	end
end

function ShopController:Buy(item)
	if item.Kind == "Pass" and ClientState:OwnsPass(item.Key) then
		return
	end
	local id = self:ProductInfo(item)
	if not id or id == 0 then
		NotifyController:Toast(UIConfig.Messages.ComingSoon)
		return
	end
	if item.Kind == "Pass" then
		MarketplaceService:PromptGamePassPurchase(player, id)
	else
		MarketplaceService:PromptProductPurchase(player, id)
	end
end

function ShopController:PromptPass(key)
	for _, entry in self.Cards do
		if entry.Item.Key == key then
			self:Buy(entry.Item)
			return
		end
	end
end

return ShopController
