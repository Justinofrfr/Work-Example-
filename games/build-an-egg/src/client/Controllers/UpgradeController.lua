local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UpgradesConfig = require(Shared.Config.Upgrades)
local ShopConfig = require(Shared.Config.Shop)
local UIConfig = require(Shared.Config.UI)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)

local ProductsConfig = require(Shared.Config.Products)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)
local Purchase = require(script.Parent.Parent.Util.Purchase)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local Prices = require(script.Parent.Parent.Util.Prices)

local function robuxProduct(key)
	local productKey = ProductsConfig.UpgradeProducts[key]
	local product = productKey and ProductsConfig.DevProducts[productKey]
	if product and product.Id ~= 0 then
		return productKey, product
	end
	return nil
end

local UpgradeController = {
	Cards = {},
}

local ClientState
local PanelController
local NotifyController
local remotes
local list
local templates
local busy = false

local function effectText(key, level)
	if key == "BulkPickup" then
		return ("Grab %d → %d shells at once"):format(Formulas.PickupAmount(level), Formulas.PickupAmount(level + 1))
	elseif key == "BulkPlace" then
		return ("Place %d → %d shells at once"):format(Formulas.PlaceAmount(level), Formulas.PlaceAmount(level + 1))
	end
	local now = math.floor(Formulas.UpgradeValue(key, level) * 100 + 0.5)
	local nextValue = math.floor(Formulas.UpgradeValue(key, level + 1) * 100 + 0.5)
	return ("+%d%% → +%d%% range"):format(now, nextValue)
end

function UpgradeController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	NotifyController = modules.NotifyController
	remotes = context.Remotes
	list = PanelController:Get("Upgrades").Body.List
	templates = context.Gui:WaitForChild("Templates")
end

function UpgradeController:Start()
	for index, key in UpgradesConfig.Order do
		local card = templates.UpgradeCard:Clone()
		card.Visible = true
		card.Name = key
		card.LayoutOrder = index
		card.Icon.Text = ShopConfig.UpgradeIcons[key] or "⬆️"
		card.Title.Text = UpgradesConfig.List[key].DisplayName
		card.Parent = list
		Ui.Feel(card.Buy, function()
			self:Buy(key, card)
		end)
		Ui.Feel(card.RobuxBuy, function()
			local productKey, product = robuxProduct(key)
			if product then
				Analytics.Track("Buy", productKey)
				Purchase.Product(product.Id)
			end
		end)
		self.Cards[key] = card
	end
	self:Refresh()
	ClientState.StateChanged:Connect(function()
		self:Refresh()
	end)
	Prices.Changed:Connect(function()
		self:Refresh()
	end)
end

function UpgradeController:Refresh()
	local state = ClientState.State
	for key, card in self.Cards do
		local level = state and state.Upgrades and state.Upgrades[key] or 0
		local cost = Formulas.UpgradeCost(key, level)
		local max = #UpgradesConfig.List[key].Costs
		card.Level.Text = ("Lv %d/%d"):format(level, max)
		local bar = card:FindFirstChild("LevelBar")
		if bar then
			bar.Fill.Size = UDim2.fromScale(math.clamp(level / math.max(max, 1), 0, 1), 1)
		end
		local _, product = robuxProduct(key)
		local showRobux = product ~= nil and cost ~= nil
		card.RobuxBuy.Visible = showRobux
		local layout = showRobux and UpgradesConfig.BuyLayout.Stacked or UpgradesConfig.BuyLayout.Solo
		card.Buy.Size = layout.Size
		card.Buy.Position = layout.Position
		if product then
			Ui.SetText(card.RobuxBuy, UpgradesConfig.RobuxText:format(Prices.Get(product.Id, product.Price)))
		end
		if cost then
			card.Effect.Text = effectText(key, level)
			Ui.SetText(card.Buy, cost == 0 and UpgradesConfig.FreeText or Format.Short(cost))
			card.Buy.Coin.Visible = cost > 0
			card.Buy.Label.Position = UDim2.fromScale(cost > 0 and 0.6 or 0.5, 0.5)
			local affordable = state and state.Coins >= cost
			Ui.SetColor(card.Buy, affordable and UIConfig.Colors.Coins or UIConfig.Colors.Locked)
		else
			card.Effect.Text = "Fully upgraded!"
			Ui.SetText(card.Buy, "MAX")
			card.Buy.Coin.Visible = false
			card.Buy.Label.Position = UDim2.fromScale(0.5, 0.5)
			Ui.SetColor(card.Buy, UIConfig.Colors.Locked)
		end
	end
end

function UpgradeController:Buy(key, card)
	if busy then
		return
	end
	busy = true
	local ok, result = remotes[Names.Remotes.BuyUpgrade]:InvokeServer(key)
	busy = false
	if ok then
		Audio.Play("Purchase")
		Ui.Pop(card, 1.05)
		NotifyController:Toast(UIConfig.Messages.Bought, UIConfig.Colors.Good)
	else
		task.spawn(Ui.Shake, card.Buy)
		local message = result == "MaxLevel" and UIConfig.Messages.MaxLevel or UIConfig.Messages.NotEnough
		NotifyController:Toast(message, UIConfig.Colors.Bad)
	end
end

return UpgradeController
