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

local function panelFrame(props)
	local base = {
		BackgroundColor3 = Color3.fromRGB(255, 244, 222),
		BorderSizePixel = 0,
	}
	for key, value in props do
		base[key] = value
	end
	return make("Frame", base, { corner(0.06), stroke(4) })
end

local function button(props)
	local color = props.Color or C.Good
	local instance = make("TextButton", {
		Name = props.Name,
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	}, {
		corner(props.Radius or 0.25),
		stroke(props.Stroke or 3.5),
		gradient(color),
	})
	instance:SetAttribute("Feel", true)
	if props.Icon then
		label({
			Name = "Icon",
			Text = props.Icon,
			Size = UDim2.fromScale(props.Text and 0.62 or 0.8, props.Text and 0.62 or 0.8),
			Position = UDim2.fromScale(0.5, props.Text and 0.36 or 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = instance,
		})
	end
	if props.Text then
		label({
			Name = "Label",
			Text = props.Text,
			Size = props.Icon and UDim2.fromScale(1.1, 0.34) or UDim2.fromScale(0.86, 0.7),
			Position = props.Icon and UDim2.fromScale(0.5, 0.86) or UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = instance,
		})
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
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	Parent = StarterGui,
})

local hud = make("Frame", { Name = "Hud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })

local topLeft = make("Frame", {
	Name = "TopLeft",
	Size = UDim2.fromScale(0.16, 0.09),
	Position = UDim2.new(0, 8, 0, 6),
	BackgroundTransparency = 1,
	Parent = hud,
}, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
for index, def in { { "Codes", "🎟️", Color3.fromRGB(80, 170, 255) }, { "Settings", "⚙️", Color3.fromRGB(150, 150, 160) } } do
	local b = button({ Name = def[1], Icon = def[2], Color = def[3], Size = UDim2.fromScale(0.3, 1), LayoutOrder = index, Parent = topLeft })
	aspect(1).Parent = b
end

local stats = make("Frame", {
	Name = "Stats",
	Size = UDim2.fromScale(0.17, 0.3),
	Position = UDim2.new(0, 10, 0.3, 0),
	BackgroundTransparency = 1,
	Parent = hud,
}, {
	make("UIListLayout", { Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UISizeConstraint", { MaxSize = Vector2.new(260, 260) }),
})
for index, def in { { "Coins", "🪙", C.Coins }, { "Speed", "⚡", C.Speed }, { "Strength", "💪", C.Strength }, { "Eggs", "🥚", C.Eggs } } do
	local row = make("Frame", {
		Name = def[1],
		Size = UDim2.fromScale(1, 0.21),
		BackgroundColor3 = Color3.fromRGB(30, 22, 18),
		BackgroundTransparency = 0.35,
		LayoutOrder = index,
		Parent = stats,
	}, { corner(0.5), stroke(2.5) })
	label({ Name = "Icon", Text = def[2], Size = UDim2.fromScale(0.22, 1.15), Position = UDim2.fromScale(-0.04, -0.075), Parent = row })
	label({ Name = "Value", Text = "0", TextColor3 = def[3], TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(0.72, 0.8), Position = UDim2.fromScale(0.22, 0.1), Parent = row })
end

local rankLabel = label({ Name = "Rank", Text = "Hatchling", Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, -0.15), TextColor3 = Color3.fromRGB(220, 220, 220), Parent = stats })
rankLabel.TextXAlignment = Enum.TextXAlignment.Left

local right = make("Frame", {
	Name = "Right",
	Size = UDim2.fromScale(0.09, 0.36),
	Position = UDim2.new(1, -10, 0.5, 0),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundTransparency = 1,
	Parent = hud,
}, {
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }),
})
for index, def in { { "Shop", "🛒", "SHOP", Color3.fromRGB(90, 210, 90) }, { "Upgrades", "⬆️", "UPGRADES", Color3.fromRGB(255, 165, 50) } } do
	local b = button({ Name = def[1], Icon = def[2], Text = def[3], Color = def[4], Size = UDim2.fromScale(1, 0.45), LayoutOrder = index, Parent = right })
	aspect(1).Parent = b
end

local progress = make("Frame", {
	Name = "Progress",
	Size = UDim2.fromScale(0.42, 0.13),
	Position = UDim2.new(0.5, 0, 0, 6),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Parent = hud,
}, { make("UISizeConstraint", { MaxSize = Vector2.new(620, 120) }) })
label({ Name = "Title", Text = "COMMON EGG", Size = UDim2.fromScale(1, 0.3), Parent = progress })
local bar = make("Frame", {
	Name = "Bar",
	Size = UDim2.fromScale(1, 0.34),
	Position = UDim2.fromScale(0, 0.32),
	BackgroundColor3 = Color3.fromRGB(40, 30, 24),
	ClipsDescendants = true,
	Parent = progress,
}, { corner(0.5), stroke(3.5) })
local fill = make("Frame", {
	Name = "Fill",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = bar,
}, {
	corner(0.5),
	make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(140, 255, 120), Color3.fromRGB(40, 190, 70)), Rotation = 90 }),
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
label({ Name = "Percent", Text = "0%", Size = UDim2.fromScale(1, 0.86), Position = UDim2.fromScale(0, 0.07), ZIndex = 3, Parent = bar })
label({ Name = "Count", Text = "0 / 171,700", Size = UDim2.fromScale(0.5, 0.22), Position = UDim2.fromScale(0, 0.7), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 240, 200), Parent = progress })
label({ Name = "Contribution", Text = "You: 0", Size = UDim2.fromScale(0.5, 0.22), Position = UDim2.fromScale(0.5, 0.7), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(160, 230, 255), Parent = progress })
label({ Name = "Phase", Text = "", Visible = false, Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 1), TextColor3 = Color3.fromRGB(255, 220, 90), Parent = progress })

local carry = make("Frame", {
	Name = "Carry",
	Size = UDim2.fromScale(0.16, 0.06),
	Position = UDim2.new(0.5, 0, 1, -100),
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = Color3.fromRGB(30, 22, 18),
	BackgroundTransparency = 0.3,
	Parent = hud,
}, { corner(0.5), stroke(3), make("UISizeConstraint", { MinSize = Vector2.new(150, 34), MaxSize = Vector2.new(260, 54) }) })
label({ Name = "Text", Text = "🥚 0 / 1", Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), Parent = carry })

local interact = button({
	Name = "Interact",
	Icon = "✋",
	Text = "PICK UP",
	Color = Color3.fromRGB(255, 200, 60),
	Size = UDim2.fromScale(0.13, 0.13),
	Position = UDim2.new(1, -20, 1, -150),
	AnchorPoint = Vector2.new(1, 1),
	Radius = 0.5,
	Parent = hud,
})
interact.Visible = false
aspect(1).Parent = interact

local panels = make("Folder", { Name = "Panels", Parent = gui })

local function panel(name, titleText, size, color)
	local frame = panelFrame({
		Name = name,
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		Parent = panels,
	})
	make("UISizeConstraint", { MaxSize = Vector2.new(760, 560) }).Parent = frame
	local header = make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0.15, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = frame,
	}, { corner(0.3), stroke(4), gradient(color) })
	label({ Name = "Title", Text = titleText, Size = UDim2.fromScale(0.7, 0.8), Position = UDim2.fromScale(0.15, 0.1), Parent = header })
	local close = button({
		Name = "Close",
		Text = "X",
		Color = C.Bad,
		Size = UDim2.fromScale(0.12, 1.1),
		Position = UDim2.new(1, 8, 0, -12),
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

local _, shopBody = panel("Shop", "SHOP", UDim2.fromScale(0.6, 0.7), Color3.fromRGB(90, 210, 90))
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
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 10) }),
})

local _, upgradeBody = panel("Upgrades", "UPGRADES", UDim2.fromScale(0.55, 0.6), Color3.fromRGB(255, 165, 50))
make("Frame", { Name = "List", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = upgradeBody }, {
	make("UIListLayout", { Padding = UDim.new(0.03, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local _, codesBody = panel("Codes", "CODES", UDim2.fromScale(0.4, 0.42), Color3.fromRGB(80, 170, 255))
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

local _, settingsBody = panel("Settings", "SETTINGS", UDim2.fromScale(0.42, 0.55), Color3.fromRGB(150, 150, 160))
make("Frame", { Name = "List", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = settingsBody }, {
	make("UIListLayout", { Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local _, lockedBody = panel("Locked", "GYM LOCKED", UDim2.fromScale(0.4, 0.42), Color3.fromRGB(120, 120, 130))
label({ Name = "Lock", Text = "🔒", Size = UDim2.fromScale(0.25, 0.4), Position = UDim2.fromScale(0.375, 0), Parent = lockedBody })
label({ Name = "Desc", Text = "Hatch 1 egg or unlock now!", Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.42), Parent = lockedBody })
button({ Name = "Buy", Text = "UNLOCK R$29", Color = C.Robux, Size = UDim2.fromScale(0.6, 0.28), Position = UDim2.fromScale(0.5, 0.7), AnchorPoint = Vector2.new(0.5, 0), Parent = lockedBody })

local templates = make("Folder", { Name = "Templates", Parent = gui })

local item = panelFrame({ Name = "ShopItem", Size = UDim2.new(0.31, 0, 0, 150), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
label({ Name = "Icon", Text = "⚡", Size = UDim2.fromScale(0.4, 0.34), Position = UDim2.fromScale(0.3, 0.04), Parent = item })
label({ Name = "Title", Text = "Item", Size = UDim2.fromScale(0.92, 0.17), Position = UDim2.fromScale(0.04, 0.38), TextColor3 = Color3.fromRGB(255, 255, 255), Parent = item })
label({ Name = "Desc", Text = "Description", Size = UDim2.fromScale(0.92, 0.14), Position = UDim2.fromScale(0.04, 0.55), TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = item })
button({ Name = "Buy", Text = "R$0", Color = C.Robux, Size = UDim2.fromScale(0.8, 0.22), Position = UDim2.fromScale(0.5, 0.74), AnchorPoint = Vector2.new(0.5, 0), Parent = item })

local section = make("Frame", { Name = "ShopSection", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = templates }, {
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
label({ Name = "Title", Text = "SECTION", Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 220, 120), LayoutOrder = 1, Parent = section })
make("Frame", { Name = "Grid", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = section }, {
	make("UIGridLayout", { CellSize = UDim2.new(0.31, 0, 0, 150), CellPadding = UDim2.new(0.02, 0, 0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local card = panelFrame({ Name = "UpgradeCard", Size = UDim2.fromScale(1, 0.3), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
label({ Name = "Icon", Text = "⬆️", Size = UDim2.fromScale(0.14, 0.8), Position = UDim2.fromScale(0.02, 0.1), Parent = card })
label({ Name = "Title", Text = "Bulk Pickup", Size = UDim2.fromScale(0.5, 0.42), Position = UDim2.fromScale(0.18, 0.08), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
label({ Name = "Effect", Text = "1 → 2 per grab", Size = UDim2.fromScale(0.5, 0.3), Position = UDim2.fromScale(0.18, 0.55), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 236, 190), StrokeThickness = 1.5, Parent = card })
label({ Name = "Level", Text = "Lv 0/5", Size = UDim2.fromScale(0.14, 0.4), Position = UDim2.fromScale(0.6, 0.3), TextColor3 = Color3.fromRGB(200, 240, 255), Parent = card })
button({ Name = "Buy", Text = "🪙 50", Color = C.Coins, Size = UDim2.fromScale(0.22, 0.64), Position = UDim2.fromScale(0.97, 0.5), AnchorPoint = Vector2.new(1, 0.5), Parent = card })

local toggle = panelFrame({ Name = "Toggle", Size = UDim2.fromScale(1, 0.2), BackgroundColor3 = Color3.fromRGB(255, 252, 240), Parent = templates })
label({ Name = "Title", Text = "Music", Size = UDim2.fromScale(0.6, 0.7), Position = UDim2.fromScale(0.04, 0.15), TextXAlignment = Enum.TextXAlignment.Left, Parent = toggle })
button({ Name = "Button", Text = "ON", Color = C.Good, Size = UDim2.fromScale(0.28, 0.75), Position = UDim2.fromScale(0.97, 0.5), AnchorPoint = Vector2.new(1, 0.5), Parent = toggle })

local toast = make("Frame", { Name = "Toast", Size = UDim2.fromScale(1, 0.22), BackgroundColor3 = Color3.fromRGB(30, 22, 18), BackgroundTransparency = 0.25 }, { corner(0.5), stroke(2.5) })
label({ Name = "Text", Text = "Message", Size = UDim2.fromScale(0.94, 0.75), Position = UDim2.fromScale(0.03, 0.125), Parent = toast })
toast.Parent = templates

local toasts = make("Frame", {
	Name = "Toasts",
	Size = UDim2.fromScale(0.34, 0.2),
	Position = UDim2.new(0.5, 0, 1, -160),
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	make("UIListLayout", { Padding = UDim.new(0.04, 0), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }),
})

local banner = make("Frame", {
	Name = "Banner",
	Size = UDim2.fromScale(0.5, 0.1),
	Position = UDim2.fromScale(0.5, -0.2),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	Parent = gui,
}, { corner(0.4), stroke(4), gradient(Color3.fromRGB(255, 190, 60)), make("UISizeConstraint", { MaxSize = Vector2.new(720, 90) }) })
label({ Name = "Text", Text = "50% BUILT!", Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), Parent = banner })

local hatch = make("Frame", {
	Name = "Hatch",
	Size = UDim2.fromScale(0.3, 0.32),
	Position = UDim2.fromScale(0.5, 0.62),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
}, { aspect(1.2) })
local hatchButton = button({ Name = "Button", Icon = "🥚", Text = "HATCH!", Color = Color3.fromRGB(255, 200, 60), Size = UDim2.fromScale(0.7, 0.75), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0.5), Radius = 0.3, Parent = hatch })
hatchButton.ZIndex = 2
label({ Name = "Timer", Text = "", Size = UDim2.fromScale(1, 0.18), Position = UDim2.fromScale(0, 0.82), Parent = hatch })

local cutscene = make("Frame", { Name = "Cutscene", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
make("Frame", { Name = "Top", Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, -0.12), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = cutscene })
make("Frame", { Name = "Bottom", Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = cutscene })
label({ Name = "Caption", Text = "", Size = UDim2.fromScale(0.8, 0.09), Position = UDim2.fromScale(0.1, 0.8), Parent = cutscene })
button({ Name = "Skip", Text = "SKIP", Color = Color3.fromRGB(150, 150, 160), Size = UDim2.fromScale(0.09, 0.06), Position = UDim2.new(1, -16, 0, 16), AnchorPoint = Vector2.new(1, 0), Parent = cutscene })

make("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50, Parent = gui })

local trainHint = label({ Name = "TrainHint", Text = "Jump to stop training", Visible = false, Size = UDim2.fromScale(0.3, 0.04), Position = UDim2.new(0.5, 0, 1, -60), AnchorPoint = Vector2.new(0.5, 1), TextColor3 = Color3.fromRGB(255, 240, 200), Parent = gui })
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

print("UI built")
