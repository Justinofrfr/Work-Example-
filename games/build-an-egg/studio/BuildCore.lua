local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local PropsConfig = require(Shared.Config.Props)
local EffectsConfig = require(Shared.Config.Effects)
local MapConfig = require(Shared.Config.Map)
local GameConfig = require(Shared.Config.Game)

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

local function fresh(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	return make(className, { Name = name, Parent = parent })
end

local remotes = ReplicatedStorage:FindFirstChild(Names.RemotesFolder) or make("Folder", { Name = Names.RemotesFolder, Parent = ReplicatedStorage })
for key, name in Names.Remotes do
	local kind = Names.RemoteKinds[key]
	local existing = remotes:FindFirstChild(name)
	if existing and existing.ClassName ~= kind then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		make(kind, { Name = name, Parent = remotes })
	end
end

local templates = fresh(ReplicatedStorage, "Folder", Names.Templates.Folder)

local function label(props)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 1),
	}
	for key, value in props do
		base[key] = value
	end
	return make("TextLabel", base, { make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(30, 20, 15) }) })
end

make("BillboardGui", {
	Name = Names.Templates.RankTag,
	Size = UDim2.fromScale(5.5, 2.1),
	StudsOffset = Vector3.new(0, 2.6, 0),
	MaxDistance = 90,
	LightInfluence = 0,
	ResetOnSpawn = false,
	Parent = templates,
}, {
	label({ Name = "Count", Text = "🥚 0", Size = UDim2.fromScale(1, 0.3), TextColor3 = Color3.fromRGB(255, 235, 170) }),
	label({ Name = "Title", Text = "HATCHLING", Size = UDim2.fromScale(1, 0.33), Position = UDim2.fromScale(0, 0.3) }),
	label({ Name = "PlayerName", Text = "Player", Size = UDim2.fromScale(1, 0.37), Position = UDim2.fromScale(0, 0.63) }),
})

local stack = make("Model", { Name = Names.Templates.CarryStack, Parent = templates })
local root = make("Part", {
	Name = "Root",
	Size = Vector3.new(1, 1, 1),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Massless = true,
	Parent = stack,
})
stack.PrimaryPart = root
make("WeldConstraint", { Name = "Weld", Part0 = root, Parent = root })
local pieces = make("Folder", { Name = "Pieces", Parent = stack })
for index = 1, 10 do
	local piece = make("Part", {
		Name = tostring(index),
		Size = Vector3.new(2.3, 1.4, 1.9),
		Color = MapConfig.Palette.Shell,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Massless = true,
		Transparency = 1,
		CFrame = root.CFrame * CFrame.new(0, (index - 1) * 1.15, 0) * CFrame.Angles(0, math.rad(index * 37), 0),
		Parent = pieces,
	})
	make("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Parent = piece })
	make("WeldConstraint", { Part0 = root, Part1 = piece, Parent = piece })
end
make("BillboardGui", {
	Name = "Count",
	Enabled = false,
	Size = UDim2.fromOffset(90, 30),
	StudsOffsetWorldSpace = Vector3.new(0, 13, 0),
	MaxDistance = 70,
	LightInfluence = 0,
	Parent = root,
}, {
	label({ Name = "Text", Text = "0" }),
})

local imported = game:GetService("ServerStorage"):FindFirstChild("Imported")
local eggMesh = imported and imported:FindFirstChild("Egg") and imported.Egg:FindFirstChildWhichIsA("MeshPart", true)
local SH = PropsConfig.Shells
local shellFolder = make("Folder", { Name = Names.Templates.Shells, Parent = templates })
local shellSource = imported and imported:FindFirstChild(SH.Source)
for _, mesh in shellSource and shellSource:GetDescendants() or {} do
	if mesh:IsA("MeshPart") then
		local shell = mesh:Clone()
		for _, child in shell:GetChildren() do
			child:Destroy()
		end
		local key = mesh.Name:match("^(EggShell%a)") or mesh.Name
		shell.Name = key
		shell.Size = shell.Size / math.max(shell.Size.X, shell.Size.Y, shell.Size.Z)
		shell.Color = SH.Colors[1]
		shell.Material = Enum.Material.SmoothPlastic
		shell.Anchored = false
		shell.CanCollide = false
		shell.CanQuery = false
		shell.CanTouch = false
		shell.Massless = true
		shell:SetAttribute("OpenDown", SH.OpenDown[key] == true)
		make("SurfaceAppearance", { Name = "Shell", ColorMap = mesh.TextureID, AlphaMode = Enum.AlphaMode.Overlay, Parent = shell })
		shell.Parent = shellFolder
	end
end
local outlineTemplate = make("Highlight", {
	Name = Names.Templates.ShellOutline,
	OutlineColor = SH.Outline.Color,
	OutlineTransparency = SH.Outline.Transparency,
	FillTransparency = SH.Outline.FillTransparency,
	DepthMode = Enum.HighlightDepthMode.Occluded,
	Parent = templates,
})
local shellStack = make("Model", { Name = Names.Templates.ShellStack, Parent = templates })
outlineTemplate:Clone().Parent = shellStack
local firstShell = shellFolder:FindFirstChild("EggShellA") or shellFolder:FindFirstChildWhichIsA("MeshPart")
local function shellChunk(name, size)
	local chunk
	if firstShell then
		chunk = firstShell:Clone()
		chunk.Name = name
		chunk.Size = firstShell.Size * (size or SH.ChunkSize)
		return chunk
	elseif eggMesh then
		chunk = eggMesh:Clone()
		for _, child in chunk:GetChildren() do
			child:Destroy()
		end
	else
		chunk = Instance.new("Part")
		chunk.Shape = Enum.PartType.Ball
	end
	chunk.Name = name
	chunk.Size = Vector3.new(2.2, 2.6, 2.2)
	chunk.Color = MapConfig.Palette.Shell
	chunk.Material = Enum.Material.SmoothPlastic
	chunk.CanCollide = false
	chunk.CanQuery = false
	chunk.CanTouch = false
	return chunk
end

local carryBlock = shellChunk(Names.Templates.CarryBlock)
carryBlock.Massless = true
carryBlock.Transparency = 1
carryBlock.Parent = templates
make("Weld", { Name = "Weld", Part1 = carryBlock, Parent = carryBlock })
make("BillboardGui", {
	Name = "Count",
	Size = UDim2.fromScale(3, 1.2),
	StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
	MaxDistance = 70,
	LightInfluence = 0,
	Enabled = false,
	Parent = carryBlock,
}, {
	label({ Name = "Text", Text = "0" }),
})

local BP = GameConfig.Backpack
local backpack = make("Model", { Name = Names.Templates.Backpack, Parent = templates })
local backpackBody = make("Part", {
	Name = "Body",
	Size = BP.Size,
	Color = BP.BodyColor,
	Material = Enum.Material.Plastic,
	TopSurface = Enum.SurfaceType.Studs,
	BottomSurface = Enum.SurfaceType.Inlet,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Massless = true,
	Parent = backpack,
})
backpack.PrimaryPart = backpackBody
local function backpackPiece(name, size, offset, color, shape, studs)
	local piece = make("Part", {
		Name = name,
		Shape = shape or Enum.PartType.Block,
		Size = size,
		CFrame = backpackBody.CFrame * CFrame.new(offset),
		Color = color,
		Material = Enum.Material.Plastic,
		TopSurface = studs and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Massless = true,
		Parent = backpack,
	})
	make("WeldConstraint", { Part0 = backpackBody, Part1 = piece, Parent = piece })
	return piece
end
local meshSource = BP.Mesh and imported and imported:FindFirstChild(BP.Mesh.Source)
local meshTemplate = meshSource and meshSource:FindFirstChild(BP.Mesh.Part, true)
if meshTemplate then
	backpackBody.Transparency = 1
	local shell = meshTemplate:Clone()
	shell.Name = "Mesh"
	shell.Anchored = false
	shell.CanCollide = false
	shell.CanQuery = false
	shell.CanTouch = false
	shell.Massless = true
	shell.CFrame = backpackBody.CFrame * CFrame.new(BP.Mesh.Offset)
	shell.Parent = backpack
	make("WeldConstraint", { Part0 = backpackBody, Part1 = shell, Parent = shell })
else
	local X, Y, Z = BP.Size.X, BP.Size.Y, BP.Size.Z
	backpackPiece("Lid", Vector3.new(X + 0.12, 0.3, Z + 0.12), Vector3.new(0, Y / 2 + 0.1, 0), BP.TrimColor, nil, true)
	backpackPiece("Flap", Vector3.new(X * 0.82, Y * 0.42, 0.14), Vector3.new(0, Y * 0.24, Z / 2 + 0.08), BP.TrimColor)
	backpackPiece("Buckle", Vector3.new(0.34, 0.3, 0.1), Vector3.new(0, Y * 0.06, Z / 2 + 0.19), BP.BuckleColor)
	backpackPiece("Pocket", Vector3.new(X * 0.62, Y * 0.36, 0.34), Vector3.new(0, -Y * 0.24, Z / 2 + 0.16), BP.PocketColor, nil, true)
	backpackPiece("Emblem", Vector3.new(0.42, 0.52, 0.1), Vector3.new(0, -Y * 0.24, Z / 2 + 0.36), BP.EmblemColor, Enum.PartType.Ball)
	for side = -1, 1, 2 do
		backpackPiece("SidePocket", Vector3.new(0.3, Y * 0.5, Z * 0.7), Vector3.new(side * (X / 2 + 0.14), -Y * 0.15, 0), BP.PocketColor, nil, true)
		backpackPiece("Strap", Vector3.new(0.32, Y + 0.3, 0.22), Vector3.new(side * X * 0.3, 0, -Z / 2 - 0.1), BP.StrapColor)
		backpackPiece("Band", Vector3.new(0.2, 0.86, 0.86), Vector3.new(side * X * 0.32, Y / 2 + 0.6, 0), BP.BandColor, Enum.PartType.Cylinder)
	end
	backpackPiece("Bedroll", Vector3.new(X + 0.5, 0.8, 0.8), Vector3.new(0, Y / 2 + 0.6, 0), BP.BedrollColor, Enum.PartType.Cylinder)
end
make("Weld", { Name = "Mount", Part1 = backpackBody, Parent = backpackBody })

local stackPiece = shellChunk(Names.Templates.StackPiece, SH.StackSize)
stackPiece.Massless = true
stackPiece.Parent = templates

make("BillboardGui", {
	Name = Names.Templates.StackLabel,
	Size = UDim2.fromScale(4, 1.6),
	MaxDistance = 220,
	LightInfluence = 0,
	AlwaysOnTop = true,
	Parent = templates,
}, {
	label({ Name = "Text", Text = "0" }),
})

local fragments = make("Folder", { Name = Names.Templates.Fragment, Parent = templates })
local shardSource = imported and imported:FindFirstChild("EggShards")
local shardMeshes = {}
for _, mesh in shardSource and shardSource:GetDescendants() or {} do
	if mesh:IsA("MeshPart") then
		table.insert(shardMeshes, mesh)
	end
end
if #shardMeshes == 0 then
	table.insert(shardMeshes, make("Part", { Name = "Shard", Size = Vector3.new(1, 1, 1) }))
end
for index, source in shardMeshes do
	local shard = source:Clone()
	for _, child in shard:GetChildren() do
		child:Destroy()
	end
	shard.Name = "Shard" .. index
	local longest = math.max(shard.Size.X, shard.Size.Y, shard.Size.Z)
	shard.Size = shard.Size / longest * EffectsConfig.Cutscene.Fragments.Size
	shard.Material = Enum.Material.SmoothPlastic
	shard.Color = Color3.new(1, 1, 1)
	shard.Anchored = true
	shard.CanCollide = false
	shard.CanQuery = false
	shard.CanTouch = false
	shard.CastShadow = false
	shard.Parent = fragments
	local trailTop = make("Attachment", { Name = "A0", Position = Vector3.new(0, 0.4, 0), Parent = shard })
	local trailBottom = make("Attachment", { Name = "A1", Position = Vector3.new(0, -0.4, 0), Parent = shard })
	make("Trail", {
		Name = "Trail",
		Attachment0 = trailTop,
		Attachment1 = trailBottom,
		Lifetime = 0.35,
		LightEmission = 1,
		FaceCamera = true,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
		Parent = shard,
	})
	make("PointLight", { Name = "Glow", Range = 7, Brightness = 1.6, Parent = shard })
	make("ParticleEmitter", {
		Name = "Sparkle",
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Rate = 6,
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
		LightEmission = 1,
		Parent = shard,
	})
end

local pile = shellChunk(Names.Templates.DroppedPile, SH.PileSize)
pile.Anchored = true
pile.CanCollide = false
pile.CanQuery = true
pile.Parent = templates
make("ProximityPrompt", {
	Name = "PilePrompt",
	ActionText = "Pick Up",
	ObjectText = "Shells",
	HoldDuration = 0,
	KeyboardKeyCode = Enum.KeyCode.E,
	MaxActivationDistance = 10,
	RequiresLineOfSight = false,
	Parent = pile,
})
make("BillboardGui", {
	Name = "Count",
	Size = UDim2.fromScale(3, 1.2),
	StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
	MaxDistance = 80,
	LightInfluence = 0,
	Parent = pile,
}, {
	label({ Name = "Text", Text = "0" }),
})

make("BillboardGui", {
	Name = Names.Templates.PurchaseTag,
	Size = UDim2.fromScale(10, 1.6),
	StudsOffset = Vector3.new(0, 5.5, 0),
	MaxDistance = 150,
	LightInfluence = 0,
	AlwaysOnTop = true,
	Parent = templates,
}, {
	label({ Name = "Text", Text = "Purchased!", TextColor3 = Color3.fromRGB(255, 225, 90) }),
})

local barbell = make("Model", { Name = "Barbell", Parent = templates })
local bar = make("Part", {
	Name = "Bar",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(7, 0.3, 0.3),
	Color = Color3.fromRGB(200, 205, 215),
	Material = Enum.Material.Metal,
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Parent = barbell,
})
barbell.PrimaryPart = bar
for side = -1, 1, 2 do
	make("Part", {
		Name = "Plate",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 2.2, 2.2),
		CFrame = bar.CFrame * CFrame.new(side * 2.9, 0, 0),
		Color = Color3.fromRGB(40, 40, 46),
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = barbell,
	})
end

local TutorialConfig = require(Shared.Config.Tutorial)
make("Beam", {
	Name = "GuideBeam",
	Texture = TutorialConfig.BeamTexture,
	TextureMode = Enum.TextureMode.Static,
	TextureLength = TutorialConfig.BeamTextureLength,
	TextureSpeed = TutorialConfig.BeamTextureSpeed,
	Color = ColorSequence.new(TutorialConfig.BeamColor),
	LightEmission = 0,
	LightInfluence = 0,
	Width0 = TutorialConfig.BeamWidth,
	Width1 = TutorialConfig.BeamWidth,
	FaceCamera = true,
	Segments = 20,
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.1, 0), NumberSequenceKeypoint.new(1, 0) }),
	Parent = templates,
})
make("Attachment", { Name = "GuideAttachment", Position = Vector3.new(0, -2.6, 0), Parent = templates })
local guideTarget = make("Part", {
	Name = "GuideTarget",
	Size = Vector3.new(1, 1, 1),
	Transparency = 1,
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Parent = templates,
})
make("Attachment", { Name = "Target", Parent = guideTarget })
make("BillboardGui", {
	Name = "Marker",
	Size = UDim2.fromScale(6, 6),
	StudsOffsetWorldSpace = Vector3.new(0, TutorialConfig.MarkerHeight, 0),
	AlwaysOnTop = true,
	LightInfluence = 0,
	MaxDistance = 2000,
	Parent = guideTarget,
}, {
	label({ Name = "Arrow", Text = "⬇", TextColor3 = TutorialConfig.BeamColor }),
})

local auraAttachment = make("Attachment", { Name = Names.Templates.GooseAura, Parent = templates })
make("ParticleEmitter", {
	Name = "Aura",
	Rate = 3,
	Lifetime = NumberRange.new(1, 1.6),
	Speed = NumberRange.new(1, 2),
	SpreadAngle = Vector2.new(180, 180),
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
	Color = ColorSequence.new(Color3.fromRGB(255, 210, 60)),
	LightEmission = 0.8,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Parent = auraAttachment,
})

local trainAttachment = make("Attachment", { Name = Names.Templates.TrainAura, Parent = templates })
make("ParticleEmitter", {
	Name = "Aura",
	Rate = 6,
	Lifetime = NumberRange.new(0.6, 1),
	Speed = NumberRange.new(2, 4),
	SpreadAngle = Vector2.new(25, 25),
	EmissionDirection = Enum.NormalId.Top,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
	LightEmission = 0.6,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Parent = trainAttachment,
})

make("BillboardGui", {
	Name = Names.Templates.CoinPopup,
	Size = UDim2.fromOffset(80, 30),
	AlwaysOnTop = true,
	LightInfluence = 0,
	MaxDistance = 120,
	Parent = templates,
}, {
	label({ Name = "Text", Text = "+1", TextColor3 = Color3.fromRGB(255, 210, 70) }),
})

local effects = fresh(ReplicatedStorage, "Folder", Names.Effects.Folder)
local sounds = make("Folder", { Name = Names.Effects.Sounds, Parent = effects })
for key, def in EffectsConfig.Sounds do
	make("Sound", {
		Name = key,
		SoundId = def.Id,
		Volume = def.Volume or 0.5,
		Looped = def.Looped == true,
		RollOffMaxDistance = 200,
		Parent = sounds,
	})
end

local particles = make("Folder", { Name = Names.Effects.Particles, Parent = effects })
local function emitter(name, props)
	local base = {
		Name = name,
		Enabled = false,
		Rate = 0,
		Lifetime = NumberRange.new(0.35, 0.6),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
		Parent = particles,
	}
	for key, value in props do
		base[key] = value
	end
	return make("ParticleEmitter", base)
end
emitter("Dust", {
	Color = ColorSequence.new(Color3.fromRGB(235, 220, 190)),
	Texture = "rbxasset://textures/particles/smoke_main.dds",
	Speed = NumberRange.new(4, 8),
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 2) }),
})
emitter("Sparkle", {
	Color = ColorSequence.new(Color3.fromRGB(255, 240, 160)),
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	LightEmission = 1,
})
emitter("Confetti", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 60)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 230, 110)),
	}),
	Lifetime = NumberRange.new(1.5, 2.5),
	Speed = NumberRange.new(30, 60),
	Acceleration = Vector3.new(0, -40, 0),
	Rotation = NumberRange.new(0, 360),
	RotSpeed = NumberRange.new(-200, 200),
	Size = NumberSequence.new(0.8),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) }),
})
emitter("Firework", {
	Color = ColorSequence.new(Color3.fromRGB(255, 230, 120)),
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	LightEmission = 1,
	Lifetime = NumberRange.new(1, 1.5),
	Speed = NumberRange.new(40, 60),
	Drag = 3,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0) }),
})
emitter("Shards", {
	Color = ColorSequence.new(MapConfig.Palette.Shell),
	Lifetime = NumberRange.new(1.5, 2.2),
	Speed = NumberRange.new(40, 80),
	Acceleration = Vector3.new(0, -60, 0),
	Rotation = NumberRange.new(0, 360),
	RotSpeed = NumberRange.new(-120, 120),
	Size = NumberSequence.new(2.5),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) }),
})
emitter("Bubbles", {
	Color = ColorSequence.new(Color3.fromRGB(255, 240, 180)),
	Lifetime = NumberRange.new(1.5, 2.5),
	Speed = NumberRange.new(2, 4),
	EmissionDirection = Enum.NormalId.Top,
	SpreadAngle = Vector2.new(10, 10),
	Size = NumberSequence.new(0.5),
})

local VfxConfig = require(Shared.Config.Vfx)
local vfxFolder = make("Folder", { Name = Names.Effects.Vfx, Parent = effects })
for presetName, list in VfxConfig.Presets do
	local preset = make("Folder", { Name = presetName, Parent = vfxFolder })
	for index, def in list do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = tostring(index)
		emitter.Enabled = false
		emitter.Rate = 0
		for key, value in def.Props do
			pcall(function()
				emitter[key] = value
			end)
		end
		emitter:SetAttribute("Count", def.Count)
		emitter:SetAttribute("Delay", def.Delay)
		emitter.Parent = preset
	end
end

local gustFolder = make("Folder", { Name = "WindGusts", Parent = templates })
local windPack = imported and imported:FindFirstChild("WindPack")
for _, source in windPack and windPack:GetChildren() or {} do
	if source:IsA("Model") and source.Name ~= "OriginalPack" then
		local gust = source:Clone()
		for _, descendant in gust:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 1
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
				descendant.CastShadow = false
			end
		end
		gust.WorldPivot = gust:GetBoundingBox()
		gust.Parent = gustFolder
	end
end
local windStreak = make("Part", {
	Name = "WindStreak",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 1,
	Size = Vector3.new(0.2, 0.2, 0.2),
	Parent = templates,
})
local streakTop = make("Attachment", { Name = "Top", Position = Vector3.new(0, 0.18, 0), Parent = windStreak })
local streakBottom = make("Attachment", { Name = "Bottom", Position = Vector3.new(0, -0.18, 0), Parent = windStreak })
make("Trail", {
	Name = "Trail",
	Attachment0 = streakTop,
	Attachment1 = streakBottom,
	Lifetime = 0.8,
	FaceCamera = true,
	LightEmission = 0.6,
	Color = ColorSequence.new(Color3.new(1, 1, 1)),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
	WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
	Parent = windStreak,
})
local leaves = make("Part", {
	Name = "WindLeaves",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 1,
	Size = Vector3.new(140, 1, 140),
	Parent = templates,
})
make("ParticleEmitter", {
	Name = "Leaves",
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Rate = 6,
	Lifetime = NumberRange.new(6, 9),
	Speed = NumberRange.new(1, 3),
	Acceleration = Vector3.new(4, -2.2, 1.4),
	Drag = 0.6,
	SpreadAngle = Vector2.new(40, 40),
	EmissionDirection = Enum.NormalId.Bottom,
	Size = NumberSequence.new(0.55),
	Squash = NumberSequence.new(0.55),
	Rotation = NumberRange.new(0, 360),
	RotSpeed = NumberRange.new(-120, 120),
	Color = ColorSequence.new(Color3.fromRGB(150, 215, 90), Color3.fromRGB(110, 180, 70)),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) }),
	LightInfluence = 1,
	Shape = Enum.ParticleEmitterShape.Box,
	ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	Parent = leaves,
})

print("Core built: remotes, templates, effects")
