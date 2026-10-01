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
for _, gym in gyms:GetChildren() do
	local tierColor = MapConfig.TierColors[gym.Name] or Color3.new(1, 1, 1)
	for _, machine in gym:GetChildren() do
		if machine:IsA("Model") and (machine.Name == "Treadmill" or machine.Name == "Bench") then
			local pad = machine:FindFirstChild(Names.World.Pad)
			if pad then
				for _, child in machine:GetChildren() do
					if child ~= pad then
						child:Destroy()
					end
				end
				local sourceName = machine.Name == "Treadmill" and PropsConfig.TreadmillSource or PropsConfig.BenchSource
				local source = imported:FindFirstChild(sourceName, true)
				if machine.Name == "Treadmill" then
					source = imported.Treadmills:FindFirstChild(PropsConfig.TreadmillVariant, true) or source
				end
				local visual = prepare(source, true)
				visual.Name = "Visual"
				local floor = pad.CFrame * CFrame.new(0, -pad.Size.Y / 2, 0)
				fit(visual, "Width", machine.Name == "Treadmill" and PropsConfig.TreadmillLength or PropsConfig.BenchLength, floor * CFrame.Angles(0, math.rad(machine.Name == "Treadmill" and PropsConfig.TreadmillYaw or PropsConfig.BenchYaw), 0))
				if machine.Name == "Treadmill" then
					for _, part in visual:GetDescendants() do
						if part:IsA("BasePart") and part.Material ~= Enum.Material.Neon then
							local h, s = part.Color:ToHSV()
							if s > 0.35 then
								local _, _, v = part.Color:ToHSV()
								local th, ts = tierColor:ToHSV()
								part.Color = Color3.fromHSV(th, math.max(ts, 0.2), v)
							end
						end
					end
				end
				visual.Parent = machine
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
