local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProductsConfig = require(Shared.Config.Products)

local Ui = require(script.Parent.Parent.Util.Ui)
local Purchase = require(script.Parent.Parent.Util.Purchase)
local Analytics = require(script.Parent.Parent.Util.Analytics)

local OfferController = {}

local ClientState
local PanelController
local gui

local OFFER = ProductsConfig.StarterOffer
local PRODUCT = ProductsConfig.DevProducts[OFFER.Product]

local function clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	local rest = seconds % 60
	if hours > 0 then
		return ("%d:%02d:%02d"):format(hours, minutes, rest)
	end
	return ("%d:%02d"):format(minutes, rest)
end

function OfferController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	gui = context.Gui
end

function OfferController:Remaining()
	local state = ClientState.State
	local offer = state and state.StarterOffer
	if not PRODUCT or PRODUCT.Id == 0 or not offer or offer.Bought or offer.Ready <= 0 then
		return nil
	end
	local now = Workspace:GetServerTimeNow()
	if now < offer.Ready or now >= offer.Ends then
		return nil
	end
	return offer.Ends - now
end

function OfferController:Start()
	local hud = gui:WaitForChild("Hud")
	local button = hud:WaitForChild("Offer")
	local panel = PanelController:Get("StarterOffer")
	local body = panel.Body
	local reference = ProductsConfig.DevProducts[OFFER.ValueOf]
	body.Amount.Text = "+" .. Ui.Comma(PRODUCT.Pieces)
	body.Desc.Text = ("EGG PROGRESS + %s SHELLS"):format(Ui.Comma(PRODUCT.Coins))
	local function showPrices(price, referencePrice)
		local value = reference and math.floor(PRODUCT.Pieces / reference.Pieces * referencePrice + 0.5) or 0
		body.Value.Text = ("<s>R$%d VALUE</s>"):format(value)
		body.Value.Visible = value > price
		body.Sale.Visible = value > price
		body.Sale.Text.Text = ("-%d%%"):format(math.floor((1 - price / math.max(value, 1)) * 100))
		body.Buy.Label.Text = ("BUY R$%d"):format(price)
	end
	showPrices(PRODUCT.Price, reference and reference.Price or 0)
	task.spawn(function()
		local function localPrice(product)
			if not product or product.Id == 0 then
				return nil
			end
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, product.Id, Enum.InfoType.Product)
			return ok and info and info.PriceInRobux or nil
		end
		local price = localPrice(PRODUCT)
		if price then
			showPrices(price, localPrice(reference) or (reference and reference.Price or 0))
		end
	end)

	local topLeft = hud:WaitForChild("TopLeft")
	local function place()
		local top = topLeft.AbsolutePosition.Y - hud.AbsolutePosition.Y + topLeft.AbsoluteSize.Y
		button.Position = UDim2.new(button.Position.X.Scale, 0, 0, top + topLeft.AbsoluteSize.Y * 0.35)
	end
	place()
	topLeft:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
	topLeft:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

	Ui.Feel(button, function()
		PanelController:Open("StarterOffer")
	end)
	Ui.Feel(body.Buy, function()
		Analytics.Track("Buy", OFFER.Product)
		Purchase.Product(PRODUCT.Id)
	end)
	PanelController.Opened:Connect(function(name)
		if name == "StarterOffer" then
			Analytics.Track("Open", name)
		end
	end)

	local autoShown = false
	local wasActive = false
	task.spawn(function()
		while true do
			local remaining = self:Remaining()
			local active = remaining ~= nil
			button.Visible = active
			if active then
				local text = clock(remaining)
				button.Label.Text = text
				body.Timer.Text = "⏰ ENDS IN " .. text
				if not wasActive then
					Ui.Pop(button, 1.2)
					Analytics.Track("Shown", "StarterOffer")
				end
				if OFFER.AutoOpen and not autoShown and not PanelController.Current then
					autoShown = true
					PanelController:Open("StarterOffer")
				end
			elseif PanelController.Current == panel then
				PanelController:Close()
			end
			wasActive = active
			task.wait(0.5)
		end
	end)
end

return OfferController
