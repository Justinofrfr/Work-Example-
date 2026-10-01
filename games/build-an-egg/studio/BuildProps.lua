local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local MapConfig = require(Shared.Config.Map)
local EggConfig = require(Shared.Config.Egg)
local ProjectsConfig = require(Shared.Config.Projects)
local PropsConfig = require(Shared.Config.Props)

local imported = ServerStorage:WaitForChild("Imported")
local world = Workspace:WaitForChild(Names.World.Root)
local random = Random.new(11)

local function make(className, props)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	instance.Parent = props.Parent
	return instance
end

local function prepare(source, collide)
	local model = source:Clone()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Camera") or descendant:IsA("MaterialVariant") or descendant:IsA("Humanoid") or descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		elseif descendant:IsA("Seat") then
			descendant.Disabled = true
		end
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			if descendant.Name == "HumanoidRootPart" then
				descendant:Destroy()
			else
				descendant.Anchored = true
				descendant.CanCollide = collide == true
				descendant.CanTouch = false
				descendant.CanQuery = collide == true
			end
		end
	end
	if not model:IsA("Model") then
		local wrapper = Instance.new("Model")
		wrapper.Name = model.Name
		model.Parent = wrapper
		model = wrapper
	end
	return model
end

local function baseOnBottom(model)
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	return size
end

local function fit(model, measure, target, cframe)
	local size = baseOnBottom(model)
	local current = measure == "Height" and size.Y or math.max(size.X, size.Z)
	if current > 0 then
		model:ScaleTo(model:GetScale() * target / current)
	end
	baseOnBottom(model)
	if cframe then
		model:PivotTo(cframe)
	end
	return model
end

local function recolor(model, rules)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			for _, rule in rules do
				local matches = (rule.Name and part.Name:find(rule.Name)) or (rule.From and (part.Color.R - rule.From.R) ^ 2 + (part.Color.G - rule.From.G) ^ 2 + (part.Color.B - rule.From.B) ^ 2 < 0.01)
				if matches then
					if rule.To then
						part.Color = rule.To
					end
					if rule.Material then
						part.Material = rule.Material
					end
					break
				end
			end
		end
	end
end

local function sparkles(parent, color, rate)
	local attachment = make("Attachment", { Name = "Sparkles", Parent = parent })
	make("ParticleEmitter", {
		Name = "Glow",
		Rate = rate or 6,
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Color = ColorSequence.new(color),
		LightEmission = 1,
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Parent = attachment,
	})
end

local function primaryPart(model)
	local _, size = model:GetBoundingBox()
	local root = make("Part", {
		Name = "Root",
		Size = Vector3.new(1, 1, 1),
		CFrame = model.WorldPivot,
		Transparency = 1,
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Parent = model,
	})
	model.PrimaryPart = root
	return root, size
end

local hatchlings = ReplicatedStorage:FindFirstChild("Hatchlings")
if hatchlings then
	hatchlings:Destroy()
end
hatchlings = make("Folder", { Name = "Hatchlings", Parent = ReplicatedStorage })

for key, def in PropsConfig.Hatchlings do
	local model = prepare(imported:WaitForChild(def.Source))
	model.Name = key
	recolor(model, def.Recolor or {})
	for _, part in model:GetDescendants() do
		if part:IsA("SpecialMesh") and def.VertexColor then
			part.VertexColor = def.VertexColor
		end
	end
	fit(model, "Height", PropsConfig.HatchlingBaseHeight, CFrame.new() * CFrame.Angles(0, math.rad(def.Yaw or 0), 0))
	local root = primaryPart(model)
	if def.Sparkle then
		sparkles(root, def.Sparkle, 10)
	end
	model:SetAttribute("Wings", table.concat(def.Wings or {}, ","))
	model.Parent = hatchlings
end

local site = world:WaitForChild(Names.World.Site)
local oldNest = site:FindFirstChild("Nest")
if oldNest then
	oldNest:Destroy()
end
local nest = prepare(imported.Nest, true)
nest.Name = "Nest"
fit(nest, "Width", PropsConfig.NestWidth, CFrame.new(EggConfig.Center + Vector3.new(0, PropsConfig.NestSink, 0)))
local bed = PropsConfig.NestBed
make("Part", {
	Name = "Bed",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(bed.Height, bed.Radius * 2, bed.Radius * 2),
	CFrame = CFrame.new(EggConfig.Center + Vector3.new(0, bed.Top - bed.Height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = bed.Color,
	Material = Enum.Material.Fabric,
	Anchored = true,
	Parent = nest,
})
nest.Parent = site

local displays = world:FindFirstChild("EggDisplays")
if displays then
	displays:Destroy()
end
displays = make("Folder", { Name = "EggDisplays", Parent = world })
local displayConfig = PropsConfig.Displays
for index, key in ProjectsConfig.Order do
	local project = ProjectsConfig.List[key]
	local look = displayConfig.Looks[key]
	local position = displayConfig.Origin + Vector3.new((index - (#ProjectsConfig.Order + 1) / 2) * displayConfig.Spacing, 0, 0)
	local stand = make("Model", { Name = key, Parent = displays })
	make("Part", {
		Name = "Pedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(displayConfig.PedestalHeight, 9, 9),
		CFrame = CFrame.new(position + Vector3.new(0, displayConfig.PedestalHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = MapConfig.Palette.WoodDark,
		Material = Enum.Material.Wood,
		Anchored = true,
		Parent = stand,
	})
	local egg = prepare(imported.Egg)
	egg.Name = "Egg"
	fit(egg, "Height", displayConfig.EggHeight, CFrame.new(position + Vector3.new(0, displayConfig.PedestalHeight + 0.3, 0)))
	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color = project.Color
			part.Material = look.Material
		end
	end
	primaryPart(egg)
	if look.Sparkle then
		sparkles(egg.PrimaryPart, look.Sparkle, 4)
		egg.PrimaryPart.Sparkles.Position = Vector3.new(0, displayConfig.EggHeight / 2, 0)
	end
	egg.Parent = stand
	CollectionService:AddTag(egg, "Wobble")
	local gui = make("BillboardGui", {
		Name = "Label",
		Size = UDim2.fromOffset(220, 50),
		StudsOffsetWorldSpace = Vector3.new(0, displayConfig.EggHeight + 3, 0),
		MaxDistance = 140,
		LightInfluence = 0,
		Parent = egg.PrimaryPart,
	})
	local label = make("TextLabel", {
		Name = "Text",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		Text = string.upper(project.DisplayName),
		TextColor3 = project.Color:Lerp(Color3.new(1, 1, 1), 0.3),
		Parent = gui,
	})
	make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(30, 20, 15), Parent = label })
end

local gyms = world:WaitForChild(Names.World.Gyms)
local G = PropsConfig.GymLook
local function gymPart(parent, props)
	local base = {
		Anchored = true,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	}
	for key, value in props do
		base[key] = value
	end
	return make("Part", base)
end
local function buildTreadmill(visual, floor, color)
	gymPart(visual, { Name = "Base", Size = Vector3.new(G.TreadmillWidth, 1, G.TreadmillLength), CFrame = floor * CFrame.new(0, 0.5, 0), Color = G.MachineDark })
	gymPart(visual, { Name = "Belt", Size = Vector3.new(G.TreadmillWidth - 1, 0.3, G.TreadmillLength - 0.6), CFrame = floor * CFrame.new(0, 1.15, 0), Color = Color3.fromRGB(25, 25, 30), Material = Enum.Material.Fabric })
	for side = -1, 1, 2 do
		gymPart(visual, { Name = "Rail", Size = Vector3.new(0.5, 0.6, G.TreadmillLength), CFrame = floor * CFrame.new(side * (G.TreadmillWidth / 2 - 0.25), 1.3, 0), Color = color })
		gymPart(visual, { Name = "Post", Size = Vector3.new(0.5, 4.2, 0.5), CFrame = floor * CFrame.new(side * (G.TreadmillWidth / 2 - 0.25), 3.1, -(G.TreadmillLength / 2 - 0.6)), Color = G.MachineLight, Material = Enum.Material.Metal })
		gymPart(visual, { Name = "Handle", Size = Vector3.new(0.4, 0.4, 2.4), CFrame = floor * CFrame.new(side * (G.TreadmillWidth / 2 - 0.25), 4.2, -(G.TreadmillLength / 2 - 1.8)), Color = color })
	end
	gymPart(visual, { Name = "Console", Size = Vector3.new(G.TreadmillWidth - 0.4, 1.6, 0.6), CFrame = floor * CFrame.new(0, 5.2, -(G.TreadmillLength / 2 - 0.6)) * CFrame.Angles(math.rad(-25), 0, 0), Color = color, Material = Enum.Material.Neon })
end
local function buildBench(visual, floor, color)
	local benchTop = G.BenchHeight
	gymPart(visual, { Name = "Pad", Size = Vector3.new(2.6, 0.7, G.BenchLength), CFrame = floor * CFrame.new(0, benchTop - 0.35, 0.6), Color = color, Material = Enum.Material.Fabric })
	gymPart(visual, { Name = "Frame", Size = Vector3.new(1.2, benchTop - 0.7, G.BenchLength - 1.6), CFrame = floor * CFrame.new(0, (benchTop - 0.7) / 2, 0.6), Color = G.MachineDark })
	for side = -1, 1, 2 do
		gymPart(visual, { Name = "RackPost", Size = Vector3.new(0.5, G.RackHeight, 0.5), CFrame = floor * CFrame.new(side * 2.6, G.RackHeight / 2, -(G.BenchLength / 2 - 0.4)), Color = G.MachineLight, Material = Enum.Material.Metal })
		gymPart(visual, { Name = "Plate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.6, 2.6), CFrame = floor * CFrame.new(side * 3.6, G.RackHeight - 0.2, -(G.BenchLength / 2 - 0.4)), Color = G.MachineDark })
	end
	gymPart(visual, { Name = "RackBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 0.35, 0.35), CFrame = floor * CFrame.new(0, G.RackHeight - 0.2, -(G.BenchLength / 2 - 0.4)), Color = G.MachineLight, Material = Enum.Material.Metal })
	local seat = make("Seat", { Name = "SeatRef", Size = Vector3.new(1, 0.2, 1), Transparency = 1, Anchored = true, CanCollide = false, Disabled = true, CFrame = floor * CFrame.new(0, benchTop - 0.1, 0.6), Parent = visual })
	return seat
end
for _, gym in gyms:GetChildren() do
	local tierColor = MapConfig.TierColors[gym.Name] or Color3.new(1, 1, 1)
	local platform = gym:FindFirstChild("Platform")
	if platform then
		platform.Color = G.FloorColor
		platform.Material = Enum.Material.SmoothPlastic
		local size = platform.Size
		local topCF = platform.CFrame * CFrame.new(0, size.Y / 2, 0)
		for _, edge in { { 0, size.Z / 2, size.X, G.BorderWidth }, { 0, -size.Z / 2, size.X, G.BorderWidth }, { size.X / 2, 0, G.BorderWidth, size.Z }, { -size.X / 2, 0, G.BorderWidth, size.Z } } do
			gymPart(gym, { Name = "Border", Size = Vector3.new(edge[3], 0.3, edge[4]), CFrame = topCF * CFrame.new(edge[1], 0.15, edge[2]), Color = tierColor, Material = Enum.Material.Neon, CanCollide = false })
		end
	end
	for _, machine in gym:GetChildren() do
		if machine:IsA("Model") and (machine.Name == "Treadmill" or machine.Name == "Bench") then
			local pad = machine:FindFirstChild(Names.World.Pad)
			if pad then
				for _, child in machine:GetChildren() do
					if child ~= pad then
						child:Destroy()
					end
				end
				local visual = make("Model", { Name = "Visual", Parent = machine })
				local floor = pad.CFrame * CFrame.new(0, -pad.Size.Y / 2, 0)
				if machine.Name == "Treadmill" then
					buildTreadmill(visual, floor, tierColor)
				else
					buildBench(visual, floor, tierColor)
				end
			end
		end
	end
end

local interior = world:WaitForChild(Names.World.Interior)
for _, child in interior:GetChildren() do
	if child.Name == "Throne" or child.Name == "Treasure" then
		child:Destroy()
	end
end
local interiorCenter = MapConfig.Interior.Center
local throne = prepare(imported.Throne, true)
throne.Name = "Throne"
fit(throne, "Height", PropsConfig.ThroneHeight, CFrame.lookAt(interiorCenter + Vector3.new(-48, 0, 10), interiorCenter + Vector3.new(0, 0, 10)))
throne.Parent = interior
local chest = prepare(imported.Chest, true)
chest.Name = "Treasure"
fit(chest, "Width", PropsConfig.ChestWidth, CFrame.lookAt(interiorCenter + Vector3.new(48, 0, 10), interiorCenter + Vector3.new(0, 0, 10)))
chest.Parent = interior
for index = 1, PropsConfig.CoinPiles do
	local coins = prepare(imported.Coins)
	coins.Name = "Treasure"
	local angle = index / PropsConfig.CoinPiles * math.pi * 2
	fit(coins, "Width", PropsConfig.CoinPileWidth, CFrame.new(interiorCenter + Vector3.new(48 + math.cos(angle) * 9, 0, 10 + math.sin(angle) * 9)) * CFrame.Angles(0, angle, 0))
	coins.Parent = interior
end

local spawnFolder = world:WaitForChild(Names.World.Spawn)
local oldGift = spawnFolder:FindFirstChild("GiftBox")
if oldGift then
	oldGift:Destroy()
end
local gift = prepare(imported.Gift, true)
gift.Name = "GiftBox"
local giftPosition = MapConfig.Stands.Gift + PropsConfig.GiftOffset
fit(gift, "Height", PropsConfig.GiftHeight, CFrame.new(giftPosition) * CFrame.Angles(0, math.rad(20), 0))
primaryPart(gift)
CollectionService:AddTag(gift, "Wobble")
gift.Parent = spawnFolder

local scenery = world:FindFirstChild("Scenery")
if scenery then
	scenery:Destroy()
end
scenery = make("Folder", { Name = "Scenery", Parent = world })

local MaterialService = game:GetService("MaterialService")
for _, variant in imported.Trees:GetDescendants() do
	if variant:IsA("MaterialVariant") and not MaterialService:FindFirstChild(variant.Name) then
		variant:Clone().Parent = MaterialService
	end
end

local function packModels(packFolderName)
	local list = {}
	local pack = imported.Trees:FindFirstChild(packFolderName, true)
	local models = pack and pack:FindFirstChild("Models")
	if models then
		for _, model in models:GetChildren() do
			if model:IsA("Model") then
				local _, size = model:GetBoundingBox()
				if size.Y < PropsConfig.Scenery.MaxSourceHeight then
					table.insert(list, model)
				end
			end
		end
	end
	return list
end

local treeSources = packModels("Models_Trees")
table.insert(treeSources, imported.Tree)
local rockSources, bushSources = {}, {}
for _, child in imported.Nature:GetDescendants() do
	if child.Parent and (child:IsA("Model") or child:IsA("MeshPart")) then
		local lower = child.Name:lower()
		if lower:find("rock") and child.Parent:IsA("Model") and child.Parent.Name ~= "Rocks" then
			table.insert(rockSources, child)
		elseif lower:find("bush") or lower:find("shrub") then
			table.insert(bushSources, child)
		end
	end
end
for _, bush in packModels("Models_Bushes") do
	table.insert(bushSources, bush)
end

local function blocked(position)
	for _, zoneDef in PropsConfig.Scenery.Keepout do
		local flat = Vector2.new(position.X - zoneDef.Center.X, position.Z - zoneDef.Center.Z)
		if flat.Magnitude < zoneDef.Radius then
			return true
		end
	end
	return false
end

local function scatter(sources, count, minHeight, maxHeight, minRadius, maxRadius, collide)
	if #sources == 0 then
		return 0
	end
	local placed, attempts = 0, 0
	while placed < count and attempts < count * 20 do
		attempts += 1
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(minRadius, maxRadius)
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if not blocked(position) then
			local source = sources[random:NextInteger(1, #sources)]
			local model = prepare(source, collide)
			fit(model, "Height", random:NextNumber(minHeight, maxHeight), CFrame.new(position + Vector3.new(0, -0.3, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0))
			model.Parent = scenery
			placed += 1
		end
	end
	return placed
end

local S = PropsConfig.Scenery
local trees = scatter(treeSources, S.Trees, S.TreeHeight[1], S.TreeHeight[2], S.Ring[1], S.Ring[2], true)
local rocks = scatter(rockSources, S.Rocks, S.RockHeight[1], S.RockHeight[2], S.InnerRing[1], S.Ring[2], true)
local bushes = scatter(bushSources, S.Bushes, S.BushHeight[1], S.BushHeight[2], S.InnerRing[1], S.Ring[2], false)

local ambient = world:FindFirstChild("Ambient")
if ambient then
	ambient:Destroy()
end
ambient = make("Folder", { Name = "Ambient", Parent = world })
for _, def in PropsConfig.Ambient do
	for index = 1, def.Count do
		local model = prepare(imported[def.Source])
		model.Name = def.Source
		local position = def.Area + Vector3.new(random:NextNumber(-def.Spread, def.Spread), 0, random:NextNumber(-def.Spread, def.Spread))
		fit(model, "Height", def.Height, CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0))
		primaryPart(model)
		model:SetAttribute("Home", def.Area)
		model:SetAttribute("Spread", def.Spread)
		model:SetAttribute("Speed", def.Speed)
		model:SetAttribute("Yaw", def.Yaw or 0)
		CollectionService:AddTag(model, "Wander")
		model.Parent = ambient
	end
end

local eggMesh = imported.Egg:FindFirstChildWhichIsA("MeshPart", true)
local function shellPart(old)
	local piece = eggMesh:Clone()
	for _, child in piece:GetChildren() do
		child:Destroy()
	end
	piece.Name = old.Name
	piece.Size = old.Size * PropsConfig.ShellPieceScale
	piece.CFrame = old.CFrame
	piece.Color = old.Color
	piece.Material = Enum.Material.SmoothPlastic
	piece.Anchored = old.Anchored
	piece.CanCollide = old.CanCollide
	piece.CanQuery = old.CanQuery
	piece.CanTouch = old.CanTouch
	piece.Massless = old.Massless
	piece.Transparency = old.Transparency
	for _, child in old:GetChildren() do
		if not child:IsA("DataModelMesh") and not child:IsA("WeldConstraint") then
			child.Parent = piece
		end
	end
	piece.Parent = old.Parent
	old:Destroy()
	return piece
end
local pieces = world:WaitForChild(Names.World.Quarry):WaitForChild(Names.World.Pieces)
for _, old in pieces:GetChildren() do
	if old:IsA("Part") then
		local piece = shellPart(old)
		piece.CFrame = piece.CFrame * CFrame.Angles(math.rad(random:NextNumber(60, 110)), 0, 0)
	end
end
local stack = ReplicatedStorage:WaitForChild(Names.Templates.Folder):WaitForChild(Names.Templates.CarryStack)
for _, old in stack.Pieces:GetChildren() do
	if old:IsA("Part") then
		local piece = shellPart(old)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = stack.PrimaryPart
		weld.Part1 = piece
		weld.Parent = piece
	end
end

local npcs = world:FindFirstChild(Names.World.NPCs)
if npcs then
	npcs:Destroy()
end
npcs = make("Folder", { Name = Names.World.NPCs, Parent = world })
local ProductsConfig = require(Shared.Config.Products)
for _, def in PropsConfig.NPCs do
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = def.Body.Skin
	description.LeftArmColor = def.Body.Skin
	description.RightArmColor = def.Body.Skin
	description.TorsoColor = def.Body.Torso
	description.LeftLegColor = def.Body.Legs
	description.RightLegColor = def.Body.Legs
	local ok, npc = pcall(function()
		return game:GetService("Players"):CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if ok and npc then
		npc.Name = def.Name
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		local root = npc:FindFirstChild("HumanoidRootPart")
		npc.PrimaryPart = root
		npc:PivotTo(CFrame.lookAt(def.Position + Vector3.new(0, 3, 0), Vector3.new(def.FaceTarget.X, 3, def.FaceTarget.Z)))
		for _, part in npc:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = part == root
			end
		end
		make("Part", {
			Name = "Ring",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 9, 9),
			CFrame = CFrame.new(def.Position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = def.RingColor,
			Material = Enum.Material.Neon,
			Transparency = 0.25,
			Anchored = true,
			CanCollide = false,
			Parent = npc,
		})
		local tag = make("BillboardGui", {
			Name = "Tag",
			Size = UDim2.fromScale(12, 3.6),
			StudsOffset = Vector3.new(0, 5.2, 0),
			MaxDistance = 160,
			LightInfluence = 0,
			Parent = root,
		})
		local title = make("TextLabel", { Name = "Title", Size = UDim2.fromScale(1, 0.55), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, Text = def.Title, TextColor3 = def.TitleColor, Parent = tag })
		make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(30, 20, 15), Parent = title })
		local subtitle = make("TextLabel", { Name = "Subtitle", Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 0.55), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, Text = def.Subtitle, TextColor3 = Color3.new(1, 1, 1), Parent = tag })
		make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(30, 20, 15), Parent = subtitle })
		if def.PriceTag then
			local price = make("TextLabel", { Name = "Price", Size = UDim2.fromScale(0.4, 0.25), Position = UDim2.fromScale(0.3, -0.27), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, Text = "R$ " .. ProductsConfig.GamePasses[def.PriceTag].Price, TextColor3 = Color3.fromRGB(120, 255, 120), Parent = tag })
			make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(30, 20, 15), Parent = price })
		end
		local prompt = make("ProximityPrompt", {
			Name = def.Prompt.Name,
			ActionText = def.Prompt.Action,
			ObjectText = def.Title,
			HoldDuration = 0,
			KeyboardKeyCode = Enum.KeyCode.E,
			MaxActivationDistance = 12,
			RequiresLineOfSight = false,
			Parent = root,
		})
		if def.Prompt.Panel then
			prompt:SetAttribute("Panel", def.Prompt.Panel)
		end
		if def.Prompt.Pass then
			prompt:SetAttribute("Pass", def.Prompt.Pass)
		end
		if def.Aura then
			local aura = ReplicatedStorage:WaitForChild(Names.Templates.Folder):FindFirstChild(Names.Templates.GooseAura)
			if aura then
				aura:Clone().Parent = root
			end
		end
		CollectionService:AddTag(npc, "NPC")
		npc.Parent = npcs
	else
		warn("NPC build failed: " .. tostring(npc))
	end
end

for _, rootName in MapConfig.PersistentRoots do
	local container = world:FindFirstChild(rootName)
	if container and not container:IsA("Model") then
		local model = Instance.new("Model")
		model.Name = rootName
		for _, child in container:GetChildren() do
			child.Parent = model
		end
		container:Destroy()
		model.Parent = world
		container = model
	end
	if container then
		container.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end
end
for _, model in scenery:GetChildren() do
	if model:IsA("Model") then
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end
end

print(("Props built: trees=%d rocks=%d bushes=%d"):format(trees, rocks, bushes))
