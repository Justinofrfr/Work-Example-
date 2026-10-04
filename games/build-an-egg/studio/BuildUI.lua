local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UIConfig = require(Shared.Config.UI)

local C = UIConfig.Colors
local FONT = Enum.Font.FredokaOne
local OUTLINE = Color3.fromRGB(28, 18, 12)

local function make(className, props, children)
	local instance = Instance.new(className)
	for key, value in props or {} do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

local function corner(radius)
	return make("UICorner", { CornerRadius = UDim.new(radius or 0.2, 0) })
end

local function stroke(thickness, color)
	return make("UIStroke", { Thickness = thickness or 3, Color = color or OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function textStroke(thickness)
	return make("UIStroke", { Thickness = thickness or 2.5, Color = OUTLINE })
end

local function shade(color, amount)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.clamp(s + amount * 0.1, 0, 1), math.clamp(v - amount, 0, 1))
end

local function gradient(color)
	return make("UIGradient", {
		Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.25), shade(color, 0.18)),
		Rotation = 90,
	})
end

local function label(props)
	local base = {
		BackgroundTransparency = 1,
		Font = FONT,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 1),
	}
	for key, value in props do
		if key ~= "StrokeThickness" then
			base[key] = value
		end
	end
	return make("TextLabel", base, { textStroke(props.StrokeThickness) })
end

local function studs(radius, transparency, color)
	return make("ImageLabel", {
		Name = "Studs",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = UIConfig.Studs.Texture,
		ImageColor3 = color or UIConfig.Studs.Color,
		ImageTransparency = transparency or UIConfig.Studs.Transparency,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(UIConfig.Studs.TileSize, UIConfig.Studs.TileSize),
		ZIndex = 0,
	}, { corner(radius) })
end

local function iconElement(props)
	if type(props.Text) == "string" and props.Text:find("^rbxassetid") then
		return make("ImageLabel", {
			Name = props.Name,
			Image = props.Text,
			ScaleType = Enum.ScaleType.Fit,
			BackgroundTransparency = 1,
			Size = props.Size or UDim2.fromScale(1, 1),
			Position = props.Position or UDim2.new(),
			AnchorPoint = props.AnchorPoint or Vector2.new(),
			ZIndex = props.ZIndex or 1,
			Parent = props.Parent,
		})
	end
	return label(props)
end

local function shine(radius)
	return make("Frame", {
		Name = "ShineFX",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.86),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		corner(radius or 0.25),
		make("UIGradient", {
			Rotation = 65,
			Offset = Vector2.new(-1, 0),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.38, 1),
				NumberSequenceKeypoint.new(0.5, 0.45),
				NumberSequenceKeypoint.new(0.62, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
end

local function panelFrame(props)
	local base = {
		BackgroundColor3 = Color3.fromRGB(255, 244, 222),
		BorderSizePixel = 0,
	}
	for key, value in props do
		base[key] = value
	end
	return make("Frame", base, { corner(0.06), stroke(4), studs(0.06, UIConfig.Studs.PanelTransparency, UIConfig.Studs.PanelColor) })
end

local function button(props)
	local color = props.Color or C.Good
	local decor = props.Bare and {} or {
		corner(props.Radius or 0.25),
		stroke(props.Stroke or 3.5),
		gradient(color),
		studs(props.Radius or 0.25),
	}
	local instance = make("TextButton", {
		Name = props.Name,
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = props.Bare and 1 or 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	}, decor)
	instance:SetAttribute("Feel", true)
	local iconSize = props.Bare and 0.8 or (props.Text and 0.62 or 0.8)
	if props.Icon then
		iconElement({
			Name = "Icon",
			Text = props.Icon,
			Size = UDim2.fromScale(iconSize, iconSize),
			Position = UDim2.fromScale(0.5, props.Text and (props.Bare and 0.4 or 0.36) or 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = instance,
		})
	end
	if props.Text then
		label({
			Name = "Label",
			Text = props.Text,
			Size = props.Icon and UDim2.fromScale(props.Bare and 1.3 or 1.1, props.Bare and 0.28 or 0.34) or UDim2.fromScale(0.86, 0.7),
			Position = props.Icon and UDim2.fromScale(0.5, props.Bare and 0.9 or 0.86) or UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			StrokeThickness = props.Bare and 3 or nil,
			Parent = instance,
		})
	end
	if not props.Bare then
		shine(props.Radius).Parent = instance
	end
	return instance
end

local function aspect(ratio)
	return make("UIAspectRatioConstraint", { AspectRatio = ratio })
end

local existing = StarterGui:FindFirstChild(Names.Gui.Main)
if existing then
	existing:Destroy()
end

local gui = make("ScreenGui", {
	Name = Names.Gui.Main,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	IgnoreGuiInset = true,
	Parent = StarterGui,
})

local hud = make("Frame", { Name = "Hud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })

local topLeft = make("Frame", {
	Name = "TopLeft",
	Size = UDim2.fromScale(0.175, 0.075),
	Position = UDim2.fromScale(0.008, 0.075),
	BackgroundTransparency = 1,
	Parent = hud,
}, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	aspect(4.6),
})
for index, def in { { "Codes", UIConfig.Icons.Codes, Color3.fromRGB(80, 170, 255) }, { "Settings", UIConfig.Icons.Settings, Color3.fromRGB(150, 150, 160) }, { "Pets", UIConfig.Icons.Pets, Color3.fromRGB(255, 150, 60) }, { "Daily", UIConfig.Icons.Daily, Color3.fromRGB(255, 110, 150) } } do
	local b = button({ Name = def[1], Icon = def[2], Color = def[3], Size = UDim2.fromScale(0.22, 1), LayoutOrder = index, Parent = topLeft })
	aspect(1).Parent = b
	if def[1] == "Daily" then
		make("Frame", { Name = "Badge", Size = UDim2.fromScale(0.36, 0.36), Position = UDim2.fromScale(0.82, -0.08), BackgroundColor3 = C.Bad, Visible = false, ZIndex = 3, Parent = b }, {
			corner(1),
			stroke(2),
			label({ Name = "Mark", Text = "!", Size = UDim2.fromScale(1, 1), ZIndex = 4 }),
		})
	end
end

local stats = make("Frame", {
	Name = "Stats",
	Size = UDim2.fromScale(0.16, 0.34),
	Position = UDim2.fromScale(0.008, 0.3),
	BackgroundTransparency = 1,
	Parent = hud,
}, {
	make("UIListLayout", { Padding = UDim.new(0.03, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	aspect(0.78),
})
for index, def in { { "Coins", "💰", C.Coins }, { "Speed", "⚡", C.Speed, "Walk Speed: 16" }, { "Strength", "💪", C.Strength, "Capacity: 0/1" }, { "Eggs", "🥚", C.Eggs } } do
	local row = make("Frame", {
		Name = def[1],
		Size = UDim2.fromScale(1, 0.22),
		BackgroundTransparency = 1,
		LayoutOrder = index,
		Parent = stats,
	})
	iconElement({ Name = "Icon", Text = UIConfig.Icons[def[1]] or def[2], Size = UDim2.fromScale(0.3, 1), Parent = row })
	aspect(1).Parent = row.Icon
	label({ Name = "Value", Text = "0", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(0.66, def[4] and 0.66 or 0.9), Position = UDim2.fromScale(0.32, def[4] and 0 or 0.05), StrokeThickness = 3, Parent = row })
	if def[4] then
		label({ Name = "Sub", Text = def[4], TextColor3 = Color3.fromRGB(235, 235, 235), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(0.66, 0.3), Position = UDim2.fromScale(0.32, 0.66), StrokeThickness = 2, Parent = row })
	end
end

local rankLabel = label({ Name = "Rank", Text = "Hatchling", Size = UDim2.fromScale(1, 0.08), Position = UDim2.fromScale(0, -0.09), TextColor3 = Color3.fromRGB(220, 220, 220), Parent = stats })
rankLabel.TextXAlignment = Enum.TextXAlignment.Left

local right = make("Frame", {
	Name = "Right",
	Size = UDim2.fromScale(0.075, 0.42),
	Position = UDim2.fromScale(0.992, 0.24),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	Parent = hud,
}, {
	make("UIListLayout", { Padding = UDim.new(0.03, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }),
	aspect(0.32),
})
local function priceBadge(parent, text)
	local badge = make("Frame", {
		Name = "Badge",
		Size = UDim2.fromScale(0.5, 0.26),
		Position = UDim2.fromScale(0.98, 0.02),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(40, 170, 70),
		ZIndex = 4,
		Parent = parent,
	}, { corner(0.5), stroke(2) })
	label({ Name = "Text", Text = text, Size = UDim2.fromScale(0.86, 0.8), Position = UDim2.fromScale(0.07, 0.1), ZIndex = 5, StrokeThickness = 1.5, Parent = badge })
	return badge
end
for index, def in { { "Shop", UIConfig.Icons.Shop, "SHOP", Color3.fromRGB(255, 90, 140) }, { "SpeedBoost", UIConfig.Icons.Speed, "2x Speed", Color3.fromRGB(80, 160, 255) }, { "StrengthBoost", UIConfig.Icons.Strength, "2x Strength", Color3.fromRGB(255, 160, 40) } } do
	local b = button({ Name = def[1], Icon = def[2], Text = def[3], Color = def[4], Size = UDim2.fromScale(1, 0.3), LayoutOrder = index, Bare = true, Parent = right })
	aspect(1).Parent = b
	if index > 1 then
		priceBadge(b, "R$0")
	end
end

local progress = make("Frame", {
	Name = "Progress",
	Size = UDim2.fromScale(0.3, 0.17),
	Position = UDim2.fromScale(0.5, 0.015),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Parent = hud,
}, { aspect(3.2) })
label({ Name = "Title", Text = "COMMON EGG", Size = UDim2.fromScale(0.6, 0.16), Position = UDim2.fromScale(0.2, 0), TextColor3 = Color3.fromRGB(255, 240, 200), Parent = progress })
local bar = make("Frame", {
	Name = "Bar",
	Size = UDim2.fromScale(1, 0.38),
	Position = UDim2.fromScale(0, 0.17),
	BackgroundColor3 = Color3.fromRGB(70, 56, 46),
	ClipsDescendants = true,
	Parent = progress,
}, { corner(0.35), stroke(4) })
make("Frame", {
	Name = "Fill",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = bar,
}, {
	corner(0.35),
	make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 248, 225), Color3.fromRGB(240, 205, 140)), Rotation = 90 }),
})
make("Frame", {
	Name = "Shine",
	Size = UDim2.fromScale(0.12, 1),
	Position = UDim2.fromScale(-0.2, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
	Parent = bar,
}, { make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }) })
label({ Name = "Percent", Text = "0 / 171,700", Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), ZIndex = 3, StrokeThickness = 3, Parent = bar })
local packs = make("Frame", {
	Name = "Packs",
	Size = UDim2.fromScale(0.9, 0.24),
	Position = UDim2.fromScale(0.05, 0.6),
	BackgroundTransparency = 1,
	Parent = progress,
}, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local ProductsConfig = require(Shared.Config.Products)
for index, key in ProductsConfig.QuickPacks do
	local product = ProductsConfig.DevProducts[key]
	local b = button({ Name = key, Text = "+" .. string.format("%d", product.Pieces):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), Color = product.Color, Size = UDim2.fromScale(0.235, 1), LayoutOrder = index, Radius = 0.2, Parent = packs })
	local badge = priceBadge(b, "R$" .. product.Price)
	badge.Size = UDim2.fromScale(0.42, 0.62)
	badge.Position = UDim2.fromScale(1.04, -0.32)
end
label({ Name = "Count", Text = "", Visible = false, Size = UDim2.fromScale(0.5, 0.12), Position = UDim2.fromScale(0, 0.86), TextXAlignment = Enum.TextXAlignment.Left, Parent = progress })
label({ Name = "Contribution", Text = "You: 0", Size = UDim2.fromScale(0.5, 0.12), Position = UDim2.fromScale(0.25, 0.86), TextColor3 = Color3.fromRGB(160, 230, 255), Parent = progress })
label({ Name = "Phase", Text = "", Visible = false, Size = UDim2.fromScale(1, 0.16), Position = UDim2.fromScale(0, 1), TextColor3 = Color3.fromRGB(255, 220, 90), Parent = progress })

local friend = make("Frame", {
	Name = "FriendBoost",
	Size = UDim2.fromScale(0.17, 0.042),
	Position = UDim2.fromScale(0.008, 0.985),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundTransparency = 1,
	Parent = hud,
}, { aspect(6) })
label({ Name = "Icon", Text = "👥", Size = UDim2.fromScale(0.17, 1), Parent = friend })
label({ Name = "Text", Text = "Friend Boost: +0%", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.19, 0.1), TextXAlignment = Enum.TextXAlignment.Left, Parent = friend })
local trainBoost = make("Frame", {
	Name = "TrainBoost",
	Size = UDim2.fromScale(0.2, 0.045),
	Position = UDim2.fromScale(0.008, 0.935),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = hud,
}, { aspect(6.5) })
label({ Name = "Text", Text = "🌈 20x TRAINING 10:00", Size = UDim2.fromScale(1, 0.9), Position = UDim2.fromScale(0, 0.05), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 225, 120), Parent = trainBoost })

local _, socialBody = panel("Social", "ENJOYING THE GAME?", UDim2.fromScale(0.42, 0.42), Color3.fromRGB(90, 170, 255), 1.6)
label({ Name = "Message", Text = "👍 LIKE the game & ⭐ FAVORITE it so you never miss an update!\nJoin the group for exclusive rewards!", Size = UDim2.fromScale(0.94, 0.42), Position = UDim2.fromScale(0.03, 0.02), Parent = socialBody })
button({ Name = "Favorite", Text = "⭐ FAVORITE", Color = Color3.fromRGB(255, 190, 40), Size = UDim2.fromScale(0.44, 0.26), Position = UDim2.fromScale(0.04, 0.5), Parent = socialBody })
button({ Name = "Group", Text = "👥 JOIN GROUP", Color = C.Good, Size = UDim2.fromScale(0.44, 0.26), Position = UDim2.fromScale(0.52, 0.5), Parent = socialBody })
label({ Name = "Note", Text = "Tap 👍 on the game page to like it!", Size = UDim2.fromScale(0.94, 0.14), Position = UDim2.fromScale(0.03, 0.82), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = socialBody })

local keys = make("Frame", {
	Name = "KeyHints",
	Size = UDim2.fromScale(0.09, 0.08),
	Position = UDim2.fromScale(0.992, 0.985),
	AnchorPoint = Vector2.new(1, 1),
	BackgroundTransparency = 1,
	Parent = hud,
}, { aspect(2.2), make("UIListLayout", { Padding = UDim.new(0.08, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
for index, def in { { "Pickup", "E", "Pick Up" }, { "Drop", "Q", "Drop" } } do
	local row = make("Frame", { Name = def[1], Size = UDim2.fromScale(1, 0.46), BackgroundTransparency = 1, LayoutOrder = index, Parent = keys })
	local cap = make("Frame", { Name = "Key", Size = UDim2.fromScale(0.26, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = row }, { corner(0.25), stroke(2.5), aspect(1) })
	make("TextLabel", { Name = "Letter", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), BackgroundTransparency = 1, Font = FONT, TextScaled = true, Text = def[2], TextColor3 = Color3.fromRGB(25, 25, 30), Parent = cap })
	label({ Name = "Label", Text = def[3], Size = UDim2.fromScale(0.7, 0.9), Position = UDim2.fromScale(0.3, 0.05), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
end

local interact = button({
	Name = "Interact",
	Icon = "✋",
	Text = "PICK UP",
	Color = Color3.fromRGB(255, 200, 60),
	Size = UDim2.fromScale(0.11, 0.11),
	Position = UDim2.fromScale(0.86, 0.72),
	AnchorPoint = Vector2.new(1, 1),
	Radius = 0.5,
	Parent = hud,
})
interact.Visible = false
aspect(1).Parent = interact

local dropButton = button({
	Name = "DropButton",
	Icon = "⬇️",
	Text = "DROP",
	Color = Color3.fromRGB(200, 90, 80),
	Size = UDim2.fromScale(0.07, 0.07),
	Position = UDim2.fromScale(0.74, 0.72),
	AnchorPoint = Vector2.new(1, 1),
	Radius = 0.5,
	Parent = hud,
})
dropButton.Visible = false
aspect(1).Parent = dropButton

local function addHint(target)
	local hint = make("Frame", {
		Name = "Hint",
		Size = UDim2.fromScale(0.4, 0.4),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(0.7, 0.3),
		BackgroundColor3 = Color3.fromRGB(30, 30, 35),
		Visible = false,
		ZIndex = 5,
		Parent = target,
	}, { corner(1), stroke(2, Color3.new(1, 1, 1)), aspect(1) })
	label({ Name = "Text", Text = "Y", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), ZIndex = 6, Parent = hint })
end
for _, target in { hud.TopLeft.Codes, hud.TopLeft.Settings, hud.Right.Shop, interact } do
	addHint(target)
end

local panels = make("Folder", { Name = "Panels", Parent = gui })

local function panel(name, titleText, size, color, ratio)
	local frame = panelFrame({
		Name = name,
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		Parent = panels,
	})
	aspect(ratio or 1.5).Parent = frame
	local header = make("Frame", {
		Name = "Header",
		Size = UDim2.fromScale(1, 0.15),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = frame,
	}, { corner(0.3), stroke(4), gradient(color), studs(0.3) })
	label({ Name = "Title", Text = titleText, Size = UDim2.fromScale(0.7, 0.8), Position = UDim2.fromScale(0.15, 0.1), Parent = header })
	shine(0.3).Parent = header
	local close = button({
		Name = "Close",
		Text = "X",
		Color = C.Bad,
		Size = UDim2.fromScale(0.12, 1.1),
		Position = UDim2.fromScale(1.02, -0.2),
		AnchorPoint = Vector2.new(1, 0),
		Radius = 0.3,
		Parent = header,
	})
	aspect(1).Parent = close
	local body = make("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(0.94, 0.78),
		Position = UDim2.fromScale(0.03, 0.19),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	return frame, body
end

local _, shopBody = panel("Shop", "SHOP", UDim2.fromScale(0.54, 0.64), Color3.fromRGB(90, 210, 90), 1.45)
make("ScrollingFrame", {
	Name = "List",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = shopBody,
}, {
	make("UIListLayout", { Padding = UDim.new(0.015, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0.01, 0), PaddingLeft = UDim.new(0.01, 0), PaddingRight = UDim.new(0.03, 0), PaddingBottom = UDim.new(0.02, 0) }),
})

local _, upgradeBody = panel("Upgrades", "UPGRADES", UDim2.fromScale(0.48, 0.54), Color3.fromRGB(255, 165, 50), 1.5)
label({ Name = "Note", Text = "🎒 Backpack size grows with 💪 Strength - train at the gym!", Size = UDim2.fromScale(1, 0.09), Position = UDim2.fromScale(0, 0.91), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = upgradeBody })
make("Frame", { Name = "List", Size = UDim2.fromScale(1, 0.88), BackgroundTransparency = 1, Parent = upgradeBody }, {
	make("UIListLayout", { Padding = UDim.new(0.03, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local _, codesBody = panel("Codes", "CODES", UDim2.fromScale(0.36, 0.36), Color3.fromRGB(80, 170, 255), 1.7)
make("TextBox", {
	Name = "Input",
	Size = UDim2.fromScale(1, 0.3),
	Position = UDim2.fromScale(0, 0.06),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Font = FONT,
	PlaceholderText = "Enter Code",
	Text = "",
	TextScaled = true,
	TextColor3 = Color3.fromRGB(40, 30, 25),
	PlaceholderColor3 = Color3.fromRGB(160, 150, 140),
	ClearTextOnFocus = false,
	Parent = codesBody,
}, { corner(0.3), stroke(3), make("UIPadding", { PaddingLeft = UDim.new(0.04, 0), PaddingRight = UDim.new(0.04, 0), PaddingTop = UDim.new(0.12, 0), PaddingBottom = UDim.new(0.12, 0) }) })
button({ Name = "Redeem", Text = "REDEEM", Color = C.Good, Size = UDim2.fromScale(0.5, 0.3), Position = UDim2.fromScale(0.5, 0.48), AnchorPoint = Vector2.new(0.5, 0), Parent = codesBody })
label({ Name = "Status", Text = "", Size = UDim2.fromScale(1, 0.18), Position = UDim2.fromScale(0, 0.82), TextColor3 = C.Good, Parent = codesBody })

local _, settingsBody = panel("Settings", "SETTINGS", UDim2.fromScale(0.38, 0.5), Color3.fromRGB(150, 150, 160), 1.35)
make("Frame", { Name = "List", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = settingsBody }, {
	make("UIListLayout", { Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local _, giftBody = panel("GiftReward", "THANK YOU!", UDim2.fromScale(0.4, 0.46), Color3.fromRGB(255, 120, 170), 1.25)
label({ Name = "Message", Text = "Thanks for favoriting! Here's your reward:", Size = UDim2.fromScale(1, 0.16), Position = UDim2.fromScale(0, 0.02), Parent = giftBody })
label({ Name = "Rewards", Text = "", Size = UDim2.fromScale(0.9, 0.5), Position = UDim2.fromScale(0.05, 0.2), TextColor3 = Color3.fromRGB(140, 255, 160), Parent = giftBody })
button({ Name = "Collect", Text = "AWESOME!", Color = C.Good, Size = UDim2.fromScale(0.5, 0.2), Position = UDim2.fromScale(0.5, 0.76), AnchorPoint = Vector2.new(0.5, 0), Parent = giftBody })

local _, dailyBody = panel("Daily", "DAILY REWARDS", UDim2.fromScale(0.64, 0.5), Color3.fromRGB(255, 110, 150), 2.1)
local days = make("Frame", { Name = "Days", Size = UDim2.fromScale(1, 0.66), BackgroundTransparency = 1, Parent = dailyBody }, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})
for index = 1, 7 do
	local day = panelFrame({ Name = "Day" .. index, Size = UDim2.fromScale(0.13, 1), LayoutOrder = index, BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = days })
	label({ Name = "Title", Text = "DAY " .. index, Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.03), Parent = day })
	label({ Name = "Reward", Text = "", Size = UDim2.fromScale(0.9, 0.7), Position = UDim2.fromScale(0.05, 0.25), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = day })
	label({ Name = "Done", Text = "✅", Size = UDim2.fromScale(0.5, 0.3), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 3, Parent = day })
end
label({ Name = "Status", Text = "", Size = UDim2.fromScale(0.6, 0.12), Position = UDim2.fromScale(0.02, 0.76), TextXAlignment = Enum.TextXAlignment.Left, Parent = dailyBody })
button({ Name = "Claim", Text = "CLAIM!", Color = C.Good, Size = UDim2.fromScale(0.3, 0.22), Position = UDim2.fromScale(0.98, 0.74), AnchorPoint = Vector2.new(1, 0), Parent = dailyBody })

local _, lockedBody = panel("Locked", "GYM LOCKED", UDim2.fromScale(0.36, 0.36), Color3.fromRGB(120, 120, 130), 1.6)
label({ Name = "Lock", Text = "🔒", Size = UDim2.fromScale(0.25, 0.4), Position = UDim2.fromScale(0.375, 0), Parent = lockedBody })
label({ Name = "Desc", Text = "Hatch 1 egg or unlock now!", Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.42), Parent = lockedBody })
button({ Name = "Buy", Text = "UNLOCK R$29", Color = C.Robux, Size = UDim2.fromScale(0.6, 0.28), Position = UDim2.fromScale(0.5, 0.7), AnchorPoint = Vector2.new(0.5, 0), Parent = lockedBody })

local function viewport(props)
	local frame = make("ViewportFrame", {
		Name = props.Name or "View",
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	make("Camera", { Name = "Camera", FieldOfView = 40, Parent = frame })
	return frame
end

local _, petsBody = panel("Pets", "PETS", UDim2.fromScale(0.56, 0.66), Color3.fromRGB(255, 150, 60), 1.45)
label({ Name = "Info", Text = "Equipped 0/3", Size = UDim2.fromScale(0.34, 0.08), Position = UDim2.fromScale(0, 0.01), TextXAlignment = Enum.TextXAlignment.Left, Parent = petsBody })
button({ Name = "EquipBest", Text = "EQUIP BEST", Color = C.Good, Size = UDim2.fromScale(0.27, 0.1), Position = UDim2.fromScale(0.36, 0), Parent = petsBody })
button({ Name = "Incubator", Text = "INCUBATOR", Color = Color3.fromRGB(190, 110, 255), Size = UDim2.fromScale(0.27, 0.1), Position = UDim2.fromScale(0.65, 0), Parent = petsBody })
label({ Name = "Boosts", Text = "", Size = UDim2.fromScale(1, 0.06), Position = UDim2.fromScale(0, 0.115), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = petsBody })
make("ScrollingFrame", {
	Name = "List",
	Size = UDim2.fromScale(1, 0.8),
	Position = UDim2.fromScale(0, 0.19),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = petsBody,
}, {
	make("UIGridLayout", { CellSize = UDim2.fromScale(0.23, 0.3), CellPadding = UDim2.fromScale(0.02, 0.02), SortOrder = Enum.SortOrder.LayoutOrder }, { make("UIAspectRatioConstraint", { AspectRatio = 0.78, DominantAxis = Enum.DominantAxis.Width }) }),
	make("UIPadding", { PaddingTop = UDim.new(0.01, 0), PaddingLeft = UDim.new(0.01, 0), PaddingRight = UDim.new(0.03, 0) }),
})
label({ Name = "Empty", Text = "No pets yet! Hatch eggs for fragments, then use the Incubator.", Size = UDim2.fromScale(0.9, 0.12), Position = UDim2.fromScale(0.05, 0.45), Parent = petsBody })

local _, incubatorBody = panel("Incubator", "INCUBATOR", UDim2.fromScale(0.6, 0.66), Color3.fromRGB(190, 110, 255), 1.5)
button({ Name = "FragmentsTab", Text = "FRAGMENTS", Color = Color3.fromRGB(255, 190, 60), Size = UDim2.fromScale(0.22, 0.1), Position = UDim2.fromScale(0, 0), Parent = incubatorBody })
button({ Name = "PetsTab", Text = "TRADE UP PETS", Color = Color3.fromRGB(150, 150, 160), Size = UDim2.fromScale(0.25, 0.1), Position = UDim2.fromScale(0.235, 0), Parent = incubatorBody })
make("ScrollingFrame", {
	Name = "Choices",
	Size = UDim2.fromScale(0.48, 0.86),
	Position = UDim2.fromScale(0, 0.13),
	BackgroundColor3 = Color3.fromRGB(240, 226, 200),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = incubatorBody,
}, {
	corner(0.04),
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0.02, 0), PaddingRight = UDim.new(0.05, 0), PaddingBottom = UDim.new(0, 6) }),
})
label({ Name = "Hint", Text = "Pick any 5 fragments. Each one adds its pet to the odds!", Size = UDim2.fromScale(0.5, 0.1), Position = UDim2.fromScale(0.5, 0.0), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = incubatorBody })
local slots = make("Frame", { Name = "Slots", Size = UDim2.fromScale(0.5, 0.16), Position = UDim2.fromScale(0.5, 0.13), BackgroundTransparency = 1, Parent = incubatorBody }, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})
for index = 1, 5 do
	local slot = button({ Name = "Slot" .. index, Text = "+", Color = Color3.fromRGB(120, 110, 100), Size = UDim2.fromScale(0.18, 1), LayoutOrder = index, Radius = 0.3, Parent = slots })
	aspect(1).Parent = slot
end
label({ Name = "Odds", Text = "Add fragments to see the odds", Size = UDim2.fromScale(0.5, 0.44), Position = UDim2.fromScale(0.5, 0.31), TextYAlignment = Enum.TextYAlignment.Top, RichText = true, StrokeThickness = 1.5, Parent = incubatorBody })
button({ Name = "Hatch", Text = "HATCH!", Color = Color3.fromRGB(190, 110, 255), Size = UDim2.fromScale(0.3, 0.16), Position = UDim2.fromScale(0.56, 0.8), Parent = incubatorBody })
button({ Name = "Clear", Text = "CLEAR", Color = C.Bad, Size = UDim2.fromScale(0.13, 0.12), Position = UDim2.fromScale(0.88, 0.82), Parent = incubatorBody })

local reveal = make("Frame", { Name = "Reveal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Visible = false, ZIndex = 60, Parent = gui })
label({ Name = "Egg", Text = "🥚", Size = UDim2.fromScale(0.3, 0.3), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 61, Parent = reveal })
viewport({ Name = "View", Size = UDim2.fromScale(0.4, 0.5), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 61, Parent = reveal })
aspect(1).Parent = reveal.View
label({ Name = "Rarity", Text = "RARE", Size = UDim2.fromScale(0.5, 0.07), Position = UDim2.fromScale(0.5, 0.1), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 62, Parent = reveal })
label({ Name = "PetName", Text = "Silver Goose", Size = UDim2.fromScale(0.5, 0.06), Position = UDim2.fromScale(0.5, 0.7), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 62, Parent = reveal })
label({ Name = "Boost", Text = "+25% Speed", Size = UDim2.fromScale(0.5, 0.045), Position = UDim2.fromScale(0.5, 0.77), AnchorPoint = Vector2.new(0.5, 0), TextColor3 = Color3.fromRGB(140, 255, 160), ZIndex = 62, Parent = reveal })
local collect = button({ Name = "Collect", Text = "AWESOME!", Color = C.Good, Size = UDim2.fromScale(0.2, 0.08), Position = UDim2.fromScale(0.5, 0.85), AnchorPoint = Vector2.new(0.5, 0), Parent = reveal })
collect.ZIndex = 62
for _, descendant in collect:GetDescendants() do
	if descendant:IsA("GuiObject") then
		descendant.ZIndex = 63
	end
end

local templates = make("Folder", { Name = "Templates", Parent = gui })

local item = panelFrame({ Name = "ShopItem", Size = UDim2.fromScale(0.31, 0.4), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
label({ Name = "Icon", Text = "⚡", Size = UDim2.fromScale(0.4, 0.34), Position = UDim2.fromScale(0.3, 0.04), Parent = item })
label({ Name = "Title", Text = "Item", Size = UDim2.fromScale(0.92, 0.17), Position = UDim2.fromScale(0.04, 0.38), TextColor3 = Color3.fromRGB(255, 255, 255), Parent = item })
label({ Name = "Desc", Text = "Description", Size = UDim2.fromScale(0.92, 0.14), Position = UDim2.fromScale(0.04, 0.55), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = item })
button({ Name = "Buy", Text = "R$0", Color = C.Robux, Size = UDim2.fromScale(0.8, 0.22), Position = UDim2.fromScale(0.5, 0.74), AnchorPoint = Vector2.new(0.5, 0), Parent = item })

local section = make("Frame", { Name = "ShopSection", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = templates }, {
	make("UIListLayout", { Padding = UDim.new(0.01, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})
aspect(16).Parent = label({ Name = "Title", Text = "SECTION", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 220, 120), LayoutOrder = 1, Parent = section })
make("Frame", { Name = "Grid", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = section }, {
	make("UIGridLayout", { CellSize = UDim2.fromScale(0.31, 1), CellPadding = UDim2.fromScale(0.02, 0.02), SortOrder = Enum.SortOrder.LayoutOrder }, { make("UIAspectRatioConstraint", { AspectRatio = 0.95, DominantAxis = Enum.DominantAxis.Width }) }),
})

local card = panelFrame({ Name = "UpgradeCard", Size = UDim2.fromScale(1, 0.3), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
label({ Name = "Icon", Text = "⬆️", Size = UDim2.fromScale(0.14, 0.8), Position = UDim2.fromScale(0.02, 0.1), Parent = card })
label({ Name = "Title", Text = "Bulk Pickup", Size = UDim2.fromScale(0.5, 0.42), Position = UDim2.fromScale(0.18, 0.08), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
label({ Name = "Effect", Text = "1 → 2 per grab", Size = UDim2.fromScale(0.5, 0.3), Position = UDim2.fromScale(0.18, 0.55), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = card })
label({ Name = "Level", Text = "Lv 0/5", Size = UDim2.fromScale(0.14, 0.4), Position = UDim2.fromScale(0.6, 0.3), TextColor3 = Color3.fromRGB(200, 240, 255), Parent = card })
local upgradeBuy = button({ Name = "Buy", Text = "50", Color = C.Coins, Size = UDim2.fromScale(0.22, 0.64), Position = UDim2.fromScale(0.97, 0.5), AnchorPoint = Vector2.new(1, 0.5), Parent = card })
upgradeBuy.Label.Size = UDim2.fromScale(0.62, 0.7)
upgradeBuy.Label.Position = UDim2.fromScale(0.6, 0.5)
local upgradeCoin = iconElement({ Name = "Coin", Text = UIConfig.Icons.Coins, Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.17, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 2, Parent = upgradeBuy })
aspect(1).Parent = upgradeCoin

local petCard = panelFrame({ Name = "PetCard", Size = UDim2.fromScale(0.23, 0.3), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
viewport({ Name = "View", Size = UDim2.fromScale(0.9, 0.5), Position = UDim2.fromScale(0.05, 0.02), Parent = petCard })
label({ Name = "PetName", Text = "Pet", Size = UDim2.fromScale(0.92, 0.11), Position = UDim2.fromScale(0.04, 0.5), Parent = petCard })
label({ Name = "Rarity", Text = "Common", Size = UDim2.fromScale(0.92, 0.09), Position = UDim2.fromScale(0.04, 0.6), StrokeThickness = 1.5, Parent = petCard })
label({ Name = "Boost", Text = "+10% Strength", Size = UDim2.fromScale(0.92, 0.08), Position = UDim2.fromScale(0.04, 0.69), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.2, Parent = petCard })
button({ Name = "Equip", Text = "EQUIP", Color = C.Good, Size = UDim2.fromScale(0.62, 0.17), Position = UDim2.fromScale(0.05, 0.8), Parent = petCard })
button({ Name = "Delete", Text = "X", Color = C.Bad, Size = UDim2.fromScale(0.24, 0.17), Position = UDim2.fromScale(0.71, 0.8), Parent = petCard })
make("Frame", { Name = "EquippedMark", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = petCard }, { corner(0.06), make("UIStroke", { Thickness = 4, Color = Color3.fromRGB(90, 255, 120) }) })

local choice = panelFrame({ Name = "Choice", Size = UDim2.fromScale(1, 0.12), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
make("UIAspectRatioConstraint", { AspectRatio = 6.5, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width, Parent = choice })
make("Frame", { Name = "Swatch", Size = UDim2.fromScale(0.1, 0.7), Position = UDim2.fromScale(0.03, 0.15), BackgroundColor3 = Color3.new(1, 1, 1), Parent = choice }, { corner(0.4), stroke(2) })
label({ Name = "Title", Text = "Silver · Shiny", Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.16, 0.06), TextXAlignment = Enum.TextXAlignment.Left, Parent = choice })
label({ Name = "Sub", Text = "+25% Speed", Size = UDim2.fromScale(0.5, 0.36), Position = UDim2.fromScale(0.16, 0.56), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.2, Parent = choice })
label({ Name = "Count", Text = "x3", Size = UDim2.fromScale(0.14, 0.6), Position = UDim2.fromScale(0.66, 0.2), Parent = choice })
button({ Name = "Add", Text = "+", Color = C.Good, Size = UDim2.fromScale(0.15, 0.8), Position = UDim2.fromScale(0.97, 0.5), AnchorPoint = Vector2.new(1, 0.5), Parent = choice })

local toggle = panelFrame({ Name = "Toggle", Size = UDim2.fromScale(1, 0.165), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
label({ Name = "Title", Text = "Music", Size = UDim2.fromScale(0.6, 0.7), Position = UDim2.fromScale(0.04, 0.15), TextXAlignment = Enum.TextXAlignment.Left, Parent = toggle })
button({ Name = "Button", Text = "ON", Color = C.Good, Size = UDim2.fromScale(0.28, 0.75), Position = UDim2.fromScale(0.97, 0.5), AnchorPoint = Vector2.new(1, 0.5), Parent = toggle })

local banner = make("Frame", {
	Name = "Banner",
	Size = UDim2.fromScale(0.5, 0.1),
	Position = UDim2.fromScale(0.5, -0.2),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	Parent = gui,
}, { corner(0.4), stroke(4), gradient(Color3.fromRGB(255, 190, 60)), studs(0.4), aspect(7) })
label({ Name = "Text", Text = "50% BUILT!", Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), Parent = banner })

local hatch = make("Frame", {
	Name = "Hatch",
	Size = UDim2.fromScale(0.2, 0.1),
	Position = UDim2.fromScale(0.5, 0.86),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
}, { aspect(3.4) })
local hatchButton = button({ Name = "Button", Text = "GO INSIDE", Color = Color3.fromRGB(120, 210, 90), Size = UDim2.fromScale(1, 0.66), Position = UDim2.fromScale(0.5, 0.66), AnchorPoint = Vector2.new(0.5, 0.5), Radius = 0.5, Parent = hatch })
hatchButton.ZIndex = 2
hatchButton.Label.Size = UDim2.fromScale(0.66, 0.6)
hatchButton.Label.Position = UDim2.fromScale(0.6, 0.5)
local hatchIcon = iconElement({ Name = "Icon", Text = "🚪", Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = hatchButton })
aspect(1).Parent = hatchIcon
addHint(hatchButton)
label({ Name = "Timer", Text = "", Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 0), TextColor3 = Color3.fromRGB(255, 240, 200), StrokeThickness = 2, Parent = hatch })

local cutscene = make("Frame", { Name = "Cutscene", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
make("Frame", { Name = "Top", Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, -0.12), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = cutscene })
make("Frame", { Name = "Bottom", Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = cutscene })
label({ Name = "Caption", Text = "", Size = UDim2.fromScale(0.8, 0.09), Position = UDim2.fromScale(0.1, 0.8), Parent = cutscene })
button({ Name = "Skip", Text = "SKIP [SPACE]", Color = Color3.fromRGB(150, 150, 160), Size = UDim2.fromScale(0.13, 0.06), Position = UDim2.fromScale(0.985, 0.03), AnchorPoint = Vector2.new(1, 0), Parent = cutscene })

local tutorial = make("Frame", { Name = "Tutorial", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 40, Parent = gui })
local TutorialConfig = require(Shared.Config.Tutorial)
make("Frame", { Name = "Hole", BackgroundTransparency = 1, Visible = false, ZIndex = 40, Size = UDim2.fromScale(0, 0), Parent = tutorial }, {
	make("UICorner", { CornerRadius = UDim.new(0, TutorialConfig.SpotlightCorner) }),
	make("UIStroke", { Thickness = TutorialConfig.SpotlightShade, Color = Color3.new(0, 0, 0), Transparency = TutorialConfig.SpotlightTransparency, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
make("Frame", { Name = "Ring", BackgroundTransparency = 1, Visible = false, ZIndex = 41, Size = UDim2.fromScale(0, 0), Parent = tutorial }, {
	make("UICorner", { CornerRadius = UDim.new(0, TutorialConfig.SpotlightCorner) }),
	make("UIStroke", { Thickness = TutorialConfig.SpotlightOutline, Color = Color3.new(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
iconElement({ Name = "Finger", Text = UIConfig.Icons.Finger, Size = UDim2.fromScale(require(Shared.Config.Tutorial).FingerSize, require(Shared.Config.Tutorial).FingerSize), AnchorPoint = Vector2.new(0.3, 0), ZIndex = 45, Parent = tutorial })
aspect(1).Parent = tutorial.Finger
local tutorialCard = panelFrame({
	Name = "Card",
	Size = UDim2.fromScale(0.36, 0.1),
	Position = UDim2.fromScale(0.5, 0.97),
	AnchorPoint = Vector2.new(0.5, 1),
	ZIndex = 42,
	Parent = tutorial,
})
aspect(5.5).Parent = tutorialCard
label({ Name = "Step", Text = "STEP 1/6", Size = UDim2.fromScale(0.3, 0.3), Position = UDim2.fromScale(0.04, 0.06), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 220, 90), ZIndex = 43, Parent = tutorialCard })
label({ Name = "Text", Text = "Walk to the quarry", Size = UDim2.fromScale(0.72, 0.55), Position = UDim2.fromScale(0.04, 0.38), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = tutorialCard })
local skip = button({ Name = "Skip", Text = "SKIP", Color = Color3.fromRGB(150, 150, 160), Size = UDim2.fromScale(0.18, 0.5), Position = UDim2.fromScale(0.97, 0.5), AnchorPoint = Vector2.new(1, 0.5), Parent = tutorialCard })
skip.ZIndex = 43

make("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50, Parent = gui })

local trainHint = label({ Name = "TrainHint", Text = "Jump to stop training", Visible = false, Size = UDim2.fromScale(0.3, 0.04), Position = UDim2.fromScale(0.5, 0.94), AnchorPoint = Vector2.new(0.5, 1), TextColor3 = Color3.fromRGB(255, 240, 200), Parent = gui })
trainHint.ZIndex = 2

for _, descendant in gui:GetDescendants() do
	local wantsScale = descendant:IsA("GuiButton") or descendant:IsA("TextBox")
		or (descendant:IsA("Frame") and (descendant.Parent == panels or descendant.Parent == templates or descendant.Name == "Carry" or descendant.Name == "Banner"))
		or (descendant:IsA("TextLabel") and descendant.Name == "Value")
	if wantsScale and not descendant:FindFirstChildOfClass("UIScale") then
		make("UIScale", { Parent = descendant })
	end
end

for _, child in templates:GetChildren() do
	child.Visible = false
end

local existingCinematic = StarterGui:FindFirstChild("Cinematic")
if existingCinematic then
	existingCinematic:Destroy()
end
local cinematic = make("ScreenGui", {
	Name = "Cinematic",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.None,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = StarterGui,
})
gui.Cutscene.Parent = cinematic
gui.Flash.Parent = cinematic
local fade = make("Frame", { Name = "Fade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 60, Parent = cinematic })
label({ Name = "Text", Text = "", Size = UDim2.fromScale(0.7, 0.08), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), TextTransparency = 1, ZIndex = 61, Parent = fade }):FindFirstChildOfClass("UIStroke").Transparency = 1
label({ Name = "InteriorTimer", Text = "", Visible = false, Size = UDim2.fromScale(0.42, 0.045), Position = UDim2.fromScale(0.5, 0.2), AnchorPoint = Vector2.new(0.5, 0), TextColor3 = Color3.fromRGB(255, 220, 90), Parent = gui.Hud })
local leaveEgg = button({ Name = "LeaveEgg", Text = "EXIT EGG", Color = C.Bad, Size = UDim2.fromScale(0.12, 0.06), Position = UDim2.fromScale(0.5, 0.255), AnchorPoint = Vector2.new(0.5, 0), Parent = gui.Hud })
leaveEgg.Visible = false
make("UIScale", { Parent = leaveEgg })

local function screen(name, order)
	local old = StarterGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	return make("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		DisplayOrder = order,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = StarterGui,
	})
end

local toastFont = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold)
local heavyFont = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
local edgeFade = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.17, 1),
	NumberSequenceKeypoint.new(0.3, 0),
	NumberSequenceKeypoint.new(0.7, 0),
	NumberSequenceKeypoint.new(0.82, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local notifyGui = screen(Names.Gui.Notify, 150)
local notifications = make("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.73),
	Size = UDim2.fromScale(1, 0.036),
	BackgroundTransparency = 1,
	Parent = notifyGui,
})
local toastTemplate = make("TextLabel", {
	Name = "Template",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.65,
	BorderSizePixel = 0,
	FontFace = toastFont,
	Text = "Message",
	TextColor3 = Color3.new(0, 0, 0),
	TextScaled = true,
	Visible = false,
	Parent = notifications,
}, {
	make("UIStroke", { Name = "Outer", Thickness = 2, Color = Color3.new(0, 0, 0) }),
	make("UIGradient", { Transparency = edgeFade }),
})
make("TextLabel", {
	Name = "bg",
	Position = UDim2.fromScale(0, -0.068),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	FontFace = toastFont,
	Text = "Message",
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
	ZIndex = 2,
	Parent = toastTemplate,
}, {
	make("UIStroke", { Name = "Outer", Thickness = 2, Color = Color3.new(0, 0, 0) }),
	make("UIGradient", { Rotation = 90 }),
})

local alertGui = screen(Names.Gui.Alert, 100)
local alertFrame = make("Frame", {
	Name = "MainFrame",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromScale(0.073, 0.11),
	BackgroundTransparency = 1,
	Parent = alertGui,
}, { aspect(1) })
for index, y in { 1.261, 0.901, 0.54, 0.18 } do
	make("TextLabel", {
		Name = "Alert" .. index,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, y),
		Size = UDim2.fromScale(10.34, 0.358),
		BackgroundTransparency = 1,
		FontFace = heavyFont,
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 1,
		TextScaled = true,
		Parent = alertFrame,
	}, {
		make("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 1 }),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(221, 255, 0), Color3.fromRGB(0, 255, 0)) }),
	})
end

local fxGui = screen(Names.Gui.Fx, 60)
local confettiLayer = make("Frame", { Name = "ConfettiLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 150, Parent = fxGui })
make("Frame", {
	Name = "Bit",
	Size = UDim2.fromScale(0.005, 0.014),
	BackgroundColor3 = Color3.fromRGB(255, 212, 64),
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 150,
	Parent = confettiLayer,
}, { make("UICorner", { CornerRadius = UDim.new(0, 2) }) })

local overlayGui = screen(Names.Gui.Overlay, 30)
make("ImageLabel", {
	Name = "PurchaseBackground",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Image = "rbxassetid://99274215381014",
	ScaleType = Enum.ScaleType.Stretch,
	Visible = false,
	ZIndex = 99,
	Parent = overlayGui,
}, {
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 4)),
			ColorSequenceKeypoint.new(0.07, Color3.fromRGB(255, 0, 212)),
			ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 0, 251)),
			ColorSequenceKeypoint.new(0.32, Color3.fromRGB(0, 26, 255)),
			ColorSequenceKeypoint.new(0.44, Color3.fromRGB(0, 251, 255)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(4, 255, 0)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.89, Color3.fromRGB(255, 149, 0)),
			ColorSequenceKeypoint.new(0.95, Color3.fromRGB(255, 113, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	}),
})

local bubblesGui = screen(Names.Gui.Bubbles, 45)
local bubbleLayer = make("Frame", { Name = "Layer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bubblesGui })
local bubble = make("TextButton", {
	Name = "Bubble",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromScale(0.075, 0.075),
	BackgroundColor3 = Color3.fromRGB(95, 195, 255),
	BackgroundTransparency = 0.1,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 5,
	Parent = bubbleLayer,
}, {
	make("UIAspectRatioConstraint", { AspectRatio = 1 }),
	make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	make("UIStroke", { Thickness = 3, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	make("UIGradient", {
		Rotation = 120,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.35) }),
	}),
	make("UIGradient", {
		Name = "Rainbow",
		Enabled = false,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 40)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 230, 100)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(70, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
		}),
	}),
})
make("Frame", {
	Name = "Shine",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.33, 0.28),
	Size = UDim2.fromScale(0.3, 0.15),
	Rotation = -35,
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	ZIndex = 6,
	Parent = bubble,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
label({ Name = "Icon", Text = "+", Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 7, Parent = bubble })
make("Frame", {
	Name = "Approach",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(2.2, 2.2),
	BackgroundTransparency = 1,
	ZIndex = 4,
	Parent = bubble,
}, {
	make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	make("UIStroke", { Thickness = 3, Color = Color3.new(1, 1, 1), Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
label({ Name = "Float", Text = "+0", Size = UDim2.fromScale(0.16, 0.05), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 8, Parent = bubbleLayer })

local Lighting = game:GetService("Lighting")
local purchaseBlur = Lighting:FindFirstChild(Names.Gui.PurchaseBlur) or make("BlurEffect", { Name = Names.Gui.PurchaseBlur, Parent = Lighting })
purchaseBlur.Size = 0
purchaseBlur.Enabled = true

print("UI built")
