local HttpService = game:GetService("HttpService")

local TARGET = "http://127.0.0.1:34878/"
local PROPS = { "Visible", "Size", "Position", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "ZIndex", "LayoutOrder", "Rotation", "ClipsDescendants", "Image", "ImageColor3", "ImageTransparency", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "Text", "TextColor3", "TextScaled", "TextSize", "TextTransparency", "TextStrokeTransparency", "TextXAlignment", "TextYAlignment", "RichText", "FontFace", "AutomaticSize", "Color", "Thickness", "Transparency", "ApplyStrokeMode", "LineJoinMode", "CornerRadius", "Offset", "AspectRatio", "AspectType", "DominantAxis", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "Padding", "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight", "Scale", "MaxSize", "MinSize", "SoundId", "Volume", "PlaybackSpeed", "DisplayOrder", "IgnoreGuiInset", "ResetOnSpawn", "ZIndexBehavior", "ScreenInsets", "Enabled", "Texture", "Lifetime", "Rate", "Speed", "SpreadAngle", "Acceleration", "Drag", "RotSpeed", "LightEmission", "Brightness", "Width0", "Width1", "TextureLength", "TextureSpeed", "TextureMode", "FaceCamera", "Segments", "CurveSize0", "CurveSize1", "MaxTextSize", "MinTextSize", "CellSize", "CellPadding", "FillDirectionMaxCells", "StartCorner", "Value", "ZOffset", "EmissionDirection", "Shape", "ShapeStyle", "ShapeInOut", "ShapePartial", "FlipbookLayout", "FlipbookMode", "FlipbookFramerate", "FlipbookStartRandom", "Orientation", "LockedToPart", "VelocityInheritance", "LightInfluence", "Squash", "TimeScale", "WindAffectsDrag", "Rotation" }

local function encode(value)
	local kind = typeof(value)
	if kind == "string" or kind == "number" or kind == "boolean" then
		return value
	end
	if kind == "Color3" then
		return { "Color3", math.floor(value.R * 255 + 0.5), math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5) }
	end
	if kind == "UDim2" then
		return { "UDim2", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
	end
	if kind == "UDim" then
		return { "UDim", value.Scale, value.Offset }
	end
	if kind == "Vector2" then
		return { "Vector2", value.X, value.Y }
	end
	if kind == "Vector3" then
		return { "Vector3", value.X, value.Y, value.Z }
	end
	if kind == "Rect" then
		return { "Rect", value.Min.X, value.Min.Y, value.Max.X, value.Max.Y }
	end
	if kind == "EnumItem" then
		return { "Enum", tostring(value.EnumType), value.Name }
	end
	if kind == "Font" then
		return { "Font", value.Family, value.Weight.Name, value.Style.Name }
	end
	if kind == "ColorSequence" then
		local keys = {}
		for _, key in value.Keypoints do
			table.insert(keys, { key.Time, math.floor(key.Value.R * 255 + 0.5), math.floor(key.Value.G * 255 + 0.5), math.floor(key.Value.B * 255 + 0.5) })
		end
		return { "ColorSequence", keys }
	end
	if kind == "NumberSequence" then
		local keys = {}
		for _, key in value.Keypoints do
			table.insert(keys, { key.Time, key.Value, key.Envelope })
		end
		return { "NumberSequence", keys }
	end
	if kind == "NumberRange" then
		return { "NumberRange", value.Min, value.Max }
	end
	return tostring(value)
end

local function serialize(instance)
	local node = { ClassName = instance.ClassName, Name = instance.Name, Props = {}, Attributes = {}, Children = {} }
	for _, prop in PROPS do
		local ok, value = pcall(function()
			return instance[prop]
		end)
		if ok and value ~= nil and typeof(value) ~= "Instance" then
			node.Props[prop] = encode(value)
		end
	end
	for key, value in instance:GetAttributes() do
		node.Attributes[key] = encode(value)
	end
	for _, child in instance:GetChildren() do
		table.insert(node.Children, serialize(child))
	end
	return node
end

local function send(name, body)
	HttpService:PostAsync(TARGET .. name, body, Enum.HttpContentType.TextPlain)
end

local sent = 0
for _, path in _G.__DumpTrees or {} do
	local instance = game
	for part in path:gmatch("[^%.]+") do
		instance = instance and instance:FindFirstChild(part)
	end
	if instance then
		send("tree_" .. path .. ".json", HttpService:JSONEncode(serialize(instance)))
		sent += 1
	end
end
for _, root in _G.__DumpSources or {} do
	local instance = game
	for part in root:gmatch("[^%.]+") do
		instance = instance and instance:FindFirstChild(part)
	end
	if instance then
		local list = instance:IsA("LuaSourceContainer") and { instance } or instance:GetDescendants()
		for _, script in list do
			if script:IsA("LuaSourceContainer") then
				send("src_" .. script:GetFullName() .. ".lua", script.Source)
				sent += 1
			end
		end
	end
end
print("sent", sent)
