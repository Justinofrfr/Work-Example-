local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIConfig = require(Shared.Config.UI)
local ProductsConfig = require(Shared.Config.Products)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)
local Prices = require(script.Parent.Parent.Util.Prices)

local HudController = {}

local ClientState
local PanelController
local ShopController
local gui
local hud
local progress
local shown = {}

function HudController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	ShopController = modules.ShopController
	gui = context.Gui
	hud = gui:WaitForChild("Hud")
	progress = hud:WaitForChild("Progress")
end

function HudController:Start()
	for _, name in { "Codes", "Settings" } do
		hud.TopLeft[name].Activated:Connect(function()
			PanelController:Toggle(name)
		end)
	end
	hud.Right.Shop.Activated:Connect(function()
		PanelController:Toggle("Shop")
	end)
	for _, key in ProductsConfig.QuickBoosts do
		local quickButton = hud.Right:FindFirstChild(key)
		if quickButton then
			quickButton.Activated:Connect(function()
				ShopController:BuyKey(key)
			end)
		end
	end
	for _, key in ProductsConfig.QuickPacks do
		local packButton = progress.Packs:FindFirstChild(key)
		if packButton then
			packButton.Activated:Connect(function()
				ShopController:BuyKey(key)
			end)
		end
	end
	ClientState.StateChanged:Connect(function(state, previous)
		self:RenderState(state, previous)
	end)
	self:RenderPackPrices()
	Prices.Changed:Connect(function()
		self:RenderPackPrices()
		if ClientState.State then
			self:RenderState(ClientState.State, nil)
		end
	end)
	ClientState.ServerChanged:Connect(function(server, previous)
		self:RenderServer(server, previous)
	end)
	if ClientState.State then
		self:RenderState(ClientState.State, nil)
	end
	if ClientState.Server then
		self:RenderServer(ClientState.Server, nil)
	end
	local function renderHints()
		hud.KeyHints.Visible = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
	end
	renderHints()
	UserInputService.LastInputTypeChanged:Connect(renderHints)
	RunService.Heartbeat:Connect(function()
		self:RenderTimer()
	end)
	local GuiService = game:GetService("GuiService")
	local function placeTopLeft()
		local inset = GuiService.TopbarInset
		local top = inset.Height > 0 and inset.Max.Y or 0
		hud.TopLeft.Position = UDim2.new(hud.TopLeft.Position.X.Scale, 0, 0, top + 8)
	end
	placeTopLeft()
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeTopLeft)
	task.spawn(function()
		while true do
			local state = ClientState.State
			local remaining = state and (state.TrainBoostUntil or 0) - Workspace:GetServerTimeNow() or 0
			hud.TrainBoost.Visible = remaining > 0
			if remaining > 0 then
				hud.TrainBoost.Text.Text = ("🌈 %dx TRAINING %d:%02d"):format(ProductsConfig.DevProducts.TrainBoost20.TrainMultiplier, math.floor(remaining / 60), math.floor(remaining % 60))
			end
			task.wait(1)
		end
	end)
	task.spawn(function()
		local shine = progress.Bar.Shine
		while true do
			task.wait(UIConfig.BarShineInterval)
			shine.Position = UDim2.fromScale(-0.2, 0)
			Ui.Tween(shine, 0.8, { Position = UDim2.fromScale(1.1, 0) }, Enum.EasingStyle.Sine)
		end
	end)
end

function HudController:SetStat(name, value)
	local row = hud.Stats:FindFirstChild(name)
	if not row then
		return
	end
	local old = shown[name]
	shown[name] = value
	row.Value.Text = Format.Short(value)
	if old and value > old then
		Ui.Pop(row.Value)
		if name ~= "Coins" and math.floor(math.log10(math.max(value, 1))) > math.floor(math.log10(math.max(old, 1))) then
			Audio.Play("StatMilestone")
		end
	end
end

function HudController:RenderState(state, previous)
	self:SetStat("Coins", state.Coins)
	self:SetStat("Speed", state.Speed)
	self:SetStat("Strength", state.Strength)
	self:SetStat("Eggs", state.Eggs)
	local stats = hud.Stats
	stats.Speed.Sub.Text = ("Walk Speed: %d"):format(math.floor(Formulas.WalkSpeed(state.Speed)))
	stats.Strength.Sub.Text = ("Capacity: %s/%s"):format(Format.Short(state.Carry), Format.Short(state.Capacity))
	stats.Strength.Sub.TextColor3 = state.Carry >= state.Capacity and state.Carry > 0 and UIConfig.Colors.Bad or Color3.fromRGB(235, 235, 235)
	if previous and state.Carry ~= previous.Carry then
		Ui.Pop(stats.Strength.Sub, 1.12)
	end
	local rank = Formulas.Rank(state.Eggs)
	stats.Rank.Text = rank.Name
	stats.Rank.TextColor3 = rank.Color
	progress.Contribution.Text = ("You: %s"):format(Ui.Comma(state.RoundPieces or 0))
	hud.FriendBoost.Text.Text = ("Friend Boost: +%d%%"):format(math.floor((state.FriendBoost or 0) * 100 + 0.5))
	gui.TrainHint.Visible = state.Training ~= nil and state.Training ~= "Both"
	for _, key in ProductsConfig.QuickBoosts do
		local quickButton = hud.Right:FindFirstChild(key)
		local badge = quickButton and quickButton:FindFirstChild("Badge")
		local level = state.BoostLevels and state.BoostLevels[key] or 0
		local statRow = stats:FindFirstChild(ProductsConfig.DevProducts[key].Stat)
		local boostPill = statRow and statRow:FindFirstChild("Boost")
		if boostPill then
			boostPill.Visible = level > 0
			boostPill.Text = ("x%d"):format(Formulas.BoostValue(key, level))
		end
		local maxed = level >= #ProductsConfig.DevProducts[key].Tiers
		if badge then
			local _, price = ShopController:ProductInfo({ Key = key, Kind = "Product" })
			badge.Text.Text = maxed and "MAX" or ("R$" .. tostring(price))
		end
		if quickButton then
			Ui.SetText(quickButton, Formulas.BoostLabel(key, level))
		end
	end
end

function HudController:RenderPackPrices()
	for _, key in ProductsConfig.QuickPacks do
		local packButton = progress.Packs:FindFirstChild(key)
		local badge = packButton and packButton:FindFirstChild("Badge")
		local product = ProductsConfig.DevProducts[key]
		if badge and product then
			badge.Text.Text = "R$" .. tostring(Prices.Get(product.Id, product.Price))
		end
	end
end

function HudController:RenderServer(server)
	local fraction = server.Target > 0 and server.Progress / server.Target or 0
	progress.Title.Text = string.upper(server.ProjectName)
	Ui.Tween(progress.Bar.Fill, UIConfig.BarTweenTime, { Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) })
	progress.Bar.Percent.Text = ("%s / %s"):format(Ui.Comma(server.Progress), Ui.Comma(server.Target))
end

function HudController:RenderTimer()
	local server = ClientState.Server
	local phase = progress.Phase
	if not server or server.Phase == "Building" then
		phase.Visible = false
		return
	end
	local remaining = math.max(0, math.floor(server.PhaseEndsAt - Workspace:GetServerTimeNow()))
	phase.Visible = true
	if server.Phase == "Cutscene" then
		phase.Text = "THE EGG IS HATCHING!"
	else
		phase.Text = ("NEXT EGG IN %d:%02d"):format(remaining // 60, remaining % 60)
	end
end

return HudController
