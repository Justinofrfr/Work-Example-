local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UpgradesConfig = require(Shared.Config.Upgrades)
local ShopConfig = require(Shared.Config.Shop)
local UIConfig = require(Shared.Config.UI)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

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
		self.Cards[key] = card
	end
	self:Refresh()
	ClientState.StateChanged:Connect(function()
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
		if cost then
			card.Effect.Text = effectText(key, level)
			Ui.SetText(card.Buy, cost == 0 and UpgradesConfig.FreeText or ("🪙 " .. Format.Short(cost)))
			local affordable = state and state.Coins >= cost
			Ui.SetColor(card.Buy, affordable and UIConfig.Colors.Coins or UIConfig.Colors.Locked)
		else
			card.Effect.Text = "Fully upgraded!"
			Ui.SetText(card.Buy, "MAX")
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
