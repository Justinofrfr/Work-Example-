local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local EffectsConfig = require(Shared.Config.Effects)
local MapConfig = require(Shared.Config.Map)

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
	Size = UDim2.fromOffset(200, 36),
	StudsOffset = Vector3.new(0, 2.8, 0),
	MaxDistance = 90,
	LightInfluence = 0,
	ResetOnSpawn = false,
	Parent = templates,
}, {
	label({ Name = "Title", Text = "Hatchling" }),
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
	Size = UDim2.fromOffset(90, 30),
	StudsOffsetWorldSpace = Vector3.new(0, 13, 0),
	MaxDistance = 70,
	LightInfluence = 0,
	Parent = root,
}, {
	label({ Name = "Text", Text = "0" }),
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

print("Core built: remotes, templates, effects")
