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
local Analytics = require(script.Parent.Parent.Util.Analytics)
local Prices = require(script.Parent.Parent.Util.Prices)

local ShopController = {
	Cards = {},
	Tabs = {},
	Pages = {},
}

local ClientState
local PanelController
local NotifyController
local body
local templates

function ShopController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	NotifyController = modules.NotifyController
	body = PanelController:Get("Shop").Body
	templates = context.Gui:WaitForChild("Templates")
end

function ShopController:Start()
	for sectionIndex, section in ShopConfig.Sections do
		local tab = templates.ShopTab:Clone()
		tab.Name = section.Key
		tab.LayoutOrder = sectionIndex
		tab.Visible = true
		tab.Icon.Text = section.Icon
		Ui.SetText(tab, section.Tab)
		tab.Parent = body.Tabs
		Ui.Feel(tab, function()
			self:Select(sectionIndex)
		end)
		local page = templates.ShopPage:Clone()
		page.Name = section.Key
		page.Note.Text = section.Note
		page.Parent = body.Pages
		self.Tabs[sectionIndex] = tab
		self.Pages[sectionIndex] = page
		for itemIndex, item in section.Items do
			local card = templates[item.Featured and "ShopFeature" or "ShopItem"]:Clone()
			card.Visible = true
			card.Name = item.Key
			card.LayoutOrder = item.Featured and itemIndex + 1 or itemIndex
			card.Icon.Text = item.Icon
			card.Title.Text = item.Name
			card.Desc.Text = item.Desc
			card.Badge.Text = item.Badge or ""
			card.Badge.Visible = item.Badge ~= nil
			card.Parent = item.Featured and page or page.Grid
			Ui.Feel(card.Buy, function()
				self:Buy(item)
			end)
			self.Cards[item.Key] = { Card = card, Item = item }
		end
	end
	self:Select(1)
	self:Refresh()
	Prices.Changed:Connect(function()
		self:Refresh()
	end)
	PanelController.Opened:Connect(function(name)
		if name == "Shop" then
			Analytics.Track("Open", name)
		end
	end)
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

function ShopController:Select(index)
	for pageIndex, page in self.Pages do
		local selected = pageIndex == index
		page.Visible = selected
		if selected then
			page.CanvasPosition = Vector2.zero
		end
		Ui.SetColor(self.Tabs[pageIndex], selected and ShopConfig.Sections[pageIndex].Color or UIConfig.Colors.Locked)
	end
	self.Selected = index
end

function ShopController:ProductInfo(item)
	if item.Kind == "Pass" then
		local pass = ProductsConfig.GamePasses[item.Key]
		return pass.Id, Prices.Get(pass.Id, pass.Price, Enum.InfoType.GamePass)
	end
	local product = ProductsConfig.DevProducts[item.Key]
	if product.Tiers then
		local state = ClientState.State
		local level = state and state.BoostLevels and state.BoostLevels[item.Key] or 0
		local tier = product.Tiers[math.min(level + 1, #product.Tiers)]
		return tier.Id, Prices.Get(tier.Id, tier.Price)
	end
	return product.Id, Prices.Get(product.Id, product.Price)
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
	Analytics.Track("Buy", item.Key)
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
