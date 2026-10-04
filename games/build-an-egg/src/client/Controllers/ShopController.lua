local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProductsConfig = require(Shared.Config.Products)
local Formulas = require(Shared.Util.Formulas)
local ShopConfig = require(Shared.Config.Shop)
local UIConfig = require(Shared.Config.UI)
local Names = require(Shared.Config.Names)

local Ui = require(script.Parent.Parent.Util.Ui)
local Purchase = require(script.Parent.Parent.Util.Purchase)

local ShopController = {
	Cards = {},
}

local ClientState
local PanelController
local NotifyController
local list
local templates

function ShopController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	NotifyController = modules.NotifyController
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
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == Names.World.GoosePrompt then
			local pass = prompt:GetAttribute("Pass")
			if pass then
				self:BuyKey(pass)
			end
		end
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
			entry.Card.Title.Text = Formulas.BoostLabel(key, level)
			entry.Card.Desc.Text = level > 0 and ("Now x%d gains · stacks every buy"):format(Formulas.BoostValue(key, level)) or entry.Item.Desc
		end
	end
end

function ShopController:Buy(item)
	if item.Kind == "Pass" and ClientState:OwnsPass(item.Key) then
		local pass = ProductsConfig.GamePasses[item.Key]
		NotifyController:Toast(UIConfig.Messages.AlreadyOwned:format(pass and pass.Name or item.Key), UIConfig.Colors.Good)
		return
	end
	local id = self:ProductInfo(item)
	if not id or id == 0 then
		NotifyController:Toast(UIConfig.Messages.ComingSoon)
		return
	end
	if item.Kind == "Pass" then
		Purchase.Pass(id)
	else
		Purchase.Product(id)
	end
end

function ShopController:BuyKey(key)
	local kind = ProductsConfig.GamePasses[key] and "Pass" or "Product"
	self:Buy({ Key = key, Kind = kind })
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
