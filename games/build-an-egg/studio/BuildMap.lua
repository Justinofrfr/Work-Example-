local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local MapConfig = require(Shared.Config.Map)
local EggConfig = require(Shared.Config.Egg)
local GymsConfig = require(Shared.Config.Gyms)
local GameConfig = require(Shared.Config.Game)
local EggShape = require(Shared.Util.EggShape)

local W = Names.World
local A = Names.Attributes
local P = MapConfig.Palette

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

local function part(props)
	local base = {
		Anchored = true,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
		Material = Enum.Material.SmoothPlastic,
	}
	for key, value in props do
		base[key] = value
	end
	return make("Part", base)
end

local function zone(props)
	props.Transparency = 1
	props.CanCollide = false
	props.CanTouch = false
	props.CanQuery = false
	return part(props)
end

local function text(props)
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
	return make("TextLabel", base, { make("UIStroke", { Thickness = 4, Color = Color3.fromRGB(40, 25, 15) }) })
end

local function sign(parent, name, cframe, size, title, subtitle, color)
	local board = part({
		Name = name,
		Size = size,
		CFrame = cframe,
		Color = color or P.Wood,
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	for side = -1, 1, 2 do
		part({
			Name = "Post",
			Size = Vector3.new(1.4, cframe.Position.Y + size.Y / 2, 1.4),
			CFrame = CFrame.new((cframe * CFrame.new(side * (size.X / 2 - 1), 0, 0)).Position * Vector3.new(1, 0, 1) + Vector3.new(0, (cframe.Position.Y + size.Y / 2) / 2 - 0.5, 0)),
			Color = P.WoodDark,
			Material = Enum.Material.Wood,
			Parent = parent,
		})
	end
	local gui = make("SurfaceGui", {
		Name = "Gui",
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 30,
		LightInfluence = 0.2,
		Parent = board,
	})
	text({ Name = "Title", Text = title, Size = UDim2.fromScale(0.94, subtitle and 0.55 or 0.85), Position = UDim2.fromScale(0.03, 0.06), Parent = gui })
	if subtitle then
		text({ Name = "Subtitle", Text = subtitle, Size = UDim2.fromScale(0.94, 0.3), Position = UDim2.fromScale(0.03, 0.64), TextColor3 = Color3.fromRGB(255, 230, 160), Parent = gui })
	end
	return board
end

local function prompt(parent, name, action, objectText, hold)
	return make("ProximityPrompt", {
		Name = name,
		ActionText = action,
		ObjectText = objectText or "",
		HoldDuration = hold or 0,
		KeyboardKeyCode = Enum.KeyCode.E,
		MaxActivationDistance = GameConfig.BasePromptDistance,
		RequiresLineOfSight = false,
		Parent = parent,
	})
end

local function facing(position, target)
	local flatTarget = Vector3.new(target.X, position.Y, target.Z)
	return CFrame.lookAt(position, flatTarget)
end

local existing = Workspace:FindFirstChild(W.Root)
if existing then
	existing:Destroy()
end
for _, child in Workspace:GetChildren() do
	if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
		child:Destroy()
	end
end

local root = make("Folder", { Name = W.Root, Parent = Workspace })

local terrain = Workspace.Terrain
terrain:Clear()
local groundSize = MapConfig.GroundSize
terrain:FillBlock(CFrame.new(0, MapConfig.GroundTop - groundSize.Y / 2, 0), groundSize, Enum.Material.Grass)
terrain:FillBlock(CFrame.new(0, MapConfig.GroundTop - groundSize.Y / 2 - groundSize.Y, 0), groundSize, Enum.Material.Ground)
terrain:SetMaterialColor(Enum.Material.Grass, P.Grass)
terrain:SetMaterialColor(Enum.Material.Ground, P.Dirt)
terrain:SetMaterialColor(Enum.Material.Sandstone, P.Path)
local random = Random.new(7)
for index = 1, 26 do
	local angle = index / 26 * math.pi * 2
	local radius = groundSize.X / 2 - 60 + random:NextNumber(-20, 20)
	terrain:FillBall(Vector3.new(math.cos(angle) * radius, -10, math.sin(angle) * radius), random:NextNumber(70, 120), Enum.Material.Grass)
end

local quarryConfig = MapConfig.Quarry
local quarryFolder = make("Folder", { Name = W.Quarry, Parent = root })
local pitCenter = quarryConfig.Center
local pitSize = quarryConfig.Size
terrain:FillBlock(CFrame.new(pitCenter + Vector3.new(0, -pitSize.Y / 2 + 0.01, 0)), pitSize + Vector3.new(0, 0.02, 0), Enum.Material.Air)
terrain:FillBlock(CFrame.new(pitCenter + Vector3.new(0, -pitSize.Y - 2, 0)), Vector3.new(pitSize.X, 4, pitSize.Z), Enum.Material.Sandstone)
local rampLength = 22
part({
	Name = "PitRamp",
	Size = Vector3.new(24, 1, math.sqrt(rampLength ^ 2 + pitSize.Y ^ 2)),
	CFrame = CFrame.new(pitCenter + Vector3.new(0, -pitSize.Y / 2, pitSize.Z / 2 + rampLength / 2 - 0.5)) * CFrame.Angles(-math.atan2(pitSize.Y, rampLength), 0, 0),
	Color = P.Path,
	Material = Enum.Material.Sandstone,
	Parent = quarryFolder,
})
terrain:FillBlock(CFrame.new(pitCenter + Vector3.new(0, -pitSize.Y / 2, pitSize.Z / 2 + rampLength / 2)), Vector3.new(24, pitSize.Y + 0.1, rampLength), Enum.Material.Air)
zone({
	Name = W.QuarryZone,
	Size = Vector3.new(pitSize.X, pitSize.Y + 10, pitSize.Z),
	CFrame = CFrame.new(pitCenter + Vector3.new(0, -pitSize.Y / 2 + 5, 0)),
	Parent = quarryFolder,
})
local piecesFolder = make("Folder", { Name = W.Pieces, Parent = quarryFolder })
for index = 1, quarryConfig.PieceCount do
	local position = pitCenter + Vector3.new(random:NextNumber(-pitSize.X / 2 + 5, pitSize.X / 2 - 5), -pitSize.Y + quarryConfig.PieceSize.Y / 2 - 0.4, random:NextNumber(-pitSize.Z / 2 + 5, pitSize.Z / 2 - 8))
	local piece = part({
		Name = "Piece",
		Size = quarryConfig.PieceSize,
		CFrame = CFrame.new(position) * CFrame.Angles(random:NextNumber(-0.3, 0.3), random:NextNumber(0, math.pi * 2), random:NextNumber(-0.3, 0.3)),
		Color = P.Shell,
		Parent = piecesFolder,
	})
	make("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Parent = piece })
	prompt(piece, W.PickupPrompt, "Pick Up", "Shell Piece", GameConfig.PickupHoldTime)
end
sign(quarryFolder, "QuarrySign", CFrame.new(pitCenter + Vector3.new(0, 16, -pitSize.Z / 2 - 4)), Vector3.new(40, 10, 1.2), "SHELL QUARRY", "Hold E to grab shell pieces", P.Wood)

local stands = MapConfig.Stands
local codesSign = sign(quarryFolder, "CodesSign", facing(stands.Codes + Vector3.new(0, 6, 0), pitCenter), Vector3.new(14, 8, 1), "CODES", "Press E to enter", P.Wood)
make("ProximityPrompt", { Name = W.StandPrompt, ActionText = "Codes", ObjectText = "Codes", KeyboardKeyCode = Enum.KeyCode.E, MaxActivationDistance = 12, RequiresLineOfSight = false, Parent = codesSign }):SetAttribute("Panel", "Codes")
local upgradeSign = sign(quarryFolder, W.UpgradeStand, facing(stands.Upgrades + Vector3.new(0, 6, 0), pitCenter), Vector3.new(14, 8, 1), "UPGRADES", "Spend coins", Color3.fromRGB(70, 120, 60))
make("ProximityPrompt", { Name = W.StandPrompt, ActionText = "Upgrades", ObjectText = "Upgrades", KeyboardKeyCode = Enum.KeyCode.E, MaxActivationDistance = 12, RequiresLineOfSight = false, Parent = upgradeSign }):SetAttribute("Panel", "Upgrades")

local spawnFolder = make("Folder", { Name = W.Spawn, Parent = root })
make("SpawnLocation", {
	Name = "SpawnLocation",
	Anchored = true,
	Size = Vector3.new(24, 1, 24),
	CFrame = facing(MapConfig.SpawnPosition + Vector3.new(0, 0.5, 0), EggConfig.Center),
	Color = P.Path,
	Material = Enum.Material.Sandstone,
	Duration = 0,
	Neutral = true,
	Parent = spawnFolder,
}):FindFirstChildOfClass("Decal")
local giftBoard = sign(spawnFolder, W.Gift, facing(stands.Gift + Vector3.new(0, 7, 0), stands.Gift + Vector3.new(0, 7, 60)), Vector3.new(16, 10, 1.2), "FREE GIFT", "Like + Favorite + Join Group", P.Wood)
prompt(giftBoard, W.GiftPrompt, "Claim", "Free Gift", 0)
local shopBoard = sign(spawnFolder, W.ShopStand, facing(stands.Shop + Vector3.new(0, 7, 0), stands.Shop + Vector3.new(0, 7, 60)), Vector3.new(16, 10, 1.2), "SHOP", "Boosts and passes", Color3.fromRGB(60, 140, 70))
make("ProximityPrompt", { Name = W.StandPrompt, ActionText = "Shop", ObjectText = "Shop", KeyboardKeyCode = Enum.KeyCode.E, MaxActivationDistance = 12, RequiresLineOfSight = false, Parent = shopBoard }):SetAttribute("Panel", "Shop")

local site = make("Folder", { Name = W.Site, Parent = root })
local center = EggConfig.Center
local egg = make("Model", { Name = W.Egg, Parent = site })
local ringsFolder = make("Folder", { Name = W.Rings, Parent = egg })
for _, ring in EggShape.Rings() do
	local ringModel = make("Model", { Name = ("Ring%02d"):format(ring.Index), Parent = ringsFolder })
	ringModel:SetAttribute(A.Ring, ring.Index)
	local height = ring.Top - ring.Bottom
	local slant = math.sqrt(height ^ 2 + (ring.TopRadius - ring.BottomRadius) ^ 2)
	local width = 2 * math.pi * ring.Radius / ring.Segments * 1.06
	for index = 1, ring.Segments do
		local angle = (index - 0.5) / ring.Segments * math.pi * 2
		local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
		local up = (outward * (ring.TopRadius - ring.BottomRadius) + Vector3.new(0, height, 0)).Unit
		local position = center + outward * ring.Radius + Vector3.new(0, (ring.Bottom + ring.Top) / 2 - center.Y, 0)
		local segment = part({
			Name = tostring(index),
			Size = Vector3.new(width, slant * 1.04, EggConfig.ShellThickness),
			CFrame = CFrame.fromMatrix(position, tangent, up),
			Color = P.Shell,
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
			Parent = ringModel,
		})
		segment:SetAttribute(A.Segment, ring.First + index - 1)
	end
end
make("BillboardGui", {
	Name = W.EggBoard,
	Size = UDim2.fromOffset(420, 120),
	StudsOffsetWorldSpace = Vector3.new(0, EggConfig.Height + 30, 0),
	LightInfluence = 0,
	MaxDistance = 2000,
	Parent = zone({ Name = "BoardAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(center), Parent = egg }),
}, {
	text({ Name = "Title", Text = "COMMON EGG", Size = UDim2.fromScale(1, 0.55) }),
	text({ Name = "Percent", Text = "0%", Size = UDim2.fromScale(1, 0.45), Position = UDim2.fromScale(0, 0.55), TextColor3 = Color3.fromRGB(150, 255, 150) }),
})

local nest = make("Model", { Name = "Nest", Parent = site })
part({
	Name = "Bed",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(3, EggConfig.NestOuterRadius * 2, EggConfig.NestOuterRadius * 2),
	CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = P.StrawDark,
	Material = Enum.Material.Fabric,
	Parent = nest,
})
for index = 1, 44 do
	local angle = index / 44 * math.pi * 2
	local radius = random:NextNumber(EggConfig.NestInnerRadius + 4, EggConfig.NestOuterRadius - 3)
	part({
		Name = "Straw",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(random:NextNumber(18, 26), random:NextNumber(2.5, 4), random:NextNumber(2.5, 4)),
		CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * radius, random:NextNumber(2, EggConfig.NestHeight), math.sin(angle) * radius)) * CFrame.Angles(0, -angle + random:NextNumber(-0.4, 0.4), random:NextNumber(-0.35, 0.35)),
		Color = index % 2 == 0 and P.Straw or P.StrawDark,
		Material = Enum.Material.Fabric,
		CanCollide = false,
		Parent = nest,
	})
end

local scaffold = make("Model", { Name = W.Scaffold, Parent = site })
local steps = EggConfig.ScaffoldTurns * EggConfig.ScaffoldStepsPerTurn
local rise = EggConfig.Height / steps
local stepAngle = 2 * math.pi / EggConfig.ScaffoldStepsPerTurn
local arc = stepAngle * EggConfig.ScaffoldRadius
for index = 1, steps do
	local midHeight = center.Y + (index - 0.5) * rise
	local point, angle = EggShape.ScaffoldPoint(midHeight)
	local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
	local forward = (tangent * arc + Vector3.new(0, rise, 0)).Unit
	local up = forward:Cross(outward).Unit
	if up.Y < 0 then
		up = -up
	end
	local cf = CFrame.fromMatrix(point, outward, up, -forward)
	local plank = part({
		Name = "Step",
		Size = Vector3.new(EggConfig.ScaffoldWidth, 1.2, arc * 1.08),
		CFrame = cf,
		Color = P.Wood,
		Material = Enum.Material.WoodPlanks,
		Parent = scaffold,
	})
	plank:SetAttribute("Height", midHeight)
	for side = -1, 1, 2 do
		part({
			Name = "Rail",
			Size = Vector3.new(0.6, 3, arc * 1.08),
			CFrame = cf * CFrame.new(side * (EggConfig.ScaffoldWidth / 2 - 0.3), 2, 0),
			Color = P.WoodDark,
			Material = Enum.Material.Wood,
			Parent = scaffold,
		})
	end
	if index % 3 == 0 then
		local postHeight = midHeight - center.Y
		for side = -1, 1, 2 do
			local base = point + outward * side * (EggConfig.ScaffoldWidth / 2 - 1)
			part({
				Name = "Post",
				Size = Vector3.new(1.6, postHeight, 1.6),
				CFrame = CFrame.new(Vector3.new(base.X, center.Y + postHeight / 2 - 0.6, base.Z)),
				Color = P.WoodDark,
				Material = Enum.Material.Wood,
				Parent = scaffold,
			})
		end
	end
end
local topPoint = EggShape.ScaffoldPoint(center.Y + EggConfig.Height)
part({
	Name = "TopDeck",
	Size = Vector3.new(EggConfig.ScaffoldWidth + 6, 1.2, EggConfig.ScaffoldWidth + 6),
	CFrame = CFrame.new(topPoint + Vector3.new(0, 0.4, 0)),
	Color = P.Wood,
	Material = Enum.Material.WoodPlanks,
	Parent = scaffold,
})

local band = make("Folder", { Name = W.Band, Parent = site })
for index = 1, 5 do
	local anchor = zone({ Name = "Point" .. index, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(center + Vector3.new(0, -50, 0)), Parent = band })
	prompt(anchor, W.PlacePrompt, "Place", "Shell", GameConfig.PlaceHoldTime)
end

local trail = make("Folder", { Name = W.Trail, Parent = site })
local startPoint = pitCenter + Vector3.new(0, 0.3, pitSize.Z / 2 + rampLength)
local endPoint = EggShape.ScaffoldPoint(center.Y + 0.6)
local pathVector = Vector3.new(endPoint.X, 0.3, endPoint.Z) - startPoint
local distance = pathVector.Magnitude
terrain:FillBlock(CFrame.lookAt(startPoint + pathVector / 2 - Vector3.new(0, 4.3, 0), startPoint + pathVector - Vector3.new(0, 4.3, 0)), Vector3.new(14, 8, distance), Enum.Material.Sandstone)
for index = 0, math.floor(distance / 18) do
	local position = startPoint + pathVector.Unit * (index * 18 + 6) + Vector3.new(0, 0.2, 0)
	local arrow = part({
		Name = "Arrow",
		Size = Vector3.new(5, 0.4, 6),
		CFrame = CFrame.lookAt(position, position + pathVector.Unit),
		Color = P.Trail,
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = trail,
	})
	make("SpecialMesh", { MeshType = Enum.MeshType.Wedge, Scale = Vector3.new(1, 1, 1), Parent = arrow })
end

local gyms = make("Folder", { Name = W.Gyms, Parent = root })
local gymConfig = MapConfig.Gyms
local function treadmill(parent, cframe, stat, tier)
	local model = make("Model", { Name = "Treadmill", Parent = parent })
	part({ Name = "Base", Size = Vector3.new(5, 1, 9), CFrame = cframe * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(50, 50, 55), Parent = model })
	part({ Name = "Belt", Size = Vector3.new(4, 0.2, 8), CFrame = cframe * CFrame.new(0, 1.1, 0), Color = Color3.fromRGB(25, 25, 25), Material = Enum.Material.Fabric, Parent = model })
	part({ Name = "Console", Size = Vector3.new(4.6, 1.6, 0.6), CFrame = cframe * CFrame.new(0, 4.4, -4.2) * CFrame.Angles(math.rad(-25), 0, 0), Color = MapConfig.TierColors[tier], Material = Enum.Material.Neon, Parent = model })
	for side = -1, 1, 2 do
		part({ Name = "Arm", Size = Vector3.new(0.4, 4, 0.4), CFrame = cframe * CFrame.new(side * 2.2, 2.5, -4), Color = Color3.fromRGB(180, 180, 185), Material = Enum.Material.Metal, Parent = model })
	end
	local pad = zone({ Name = W.Pad, Size = Vector3.new(5, 7, 9), CFrame = cframe * CFrame.new(0, 4, 0), Parent = model })
	pad:SetAttribute(A.Stat, stat)
	pad:SetAttribute(A.Tier, tier)
	return model
end
local function bench(parent, cframe, stat, tier)
	local model = make("Model", { Name = "Bench", Parent = parent })
	part({ Name = "Seat", Size = Vector3.new(2.4, 0.8, 7), CFrame = cframe * CFrame.new(0, 2, 0), Color = MapConfig.TierColors[tier], Material = Enum.Material.Fabric, Parent = model })
	part({ Name = "Leg", Size = Vector3.new(1.6, 1.8, 1.6), CFrame = cframe * CFrame.new(0, 0.9, 2.5), Color = Color3.fromRGB(60, 60, 65), Parent = model })
	part({ Name = "Leg", Size = Vector3.new(1.6, 1.8, 1.6), CFrame = cframe * CFrame.new(0, 0.9, -2.5), Color = Color3.fromRGB(60, 60, 65), Parent = model })
	for side = -1, 1, 2 do
		part({ Name = "Rack", Size = Vector3.new(0.4, 4.5, 0.4), CFrame = cframe * CFrame.new(side * 2, 2.25, -3), Color = Color3.fromRGB(180, 180, 185), Material = Enum.Material.Metal, Parent = model })
		part({ Name = "Plate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 3, 3), CFrame = cframe * CFrame.new(side * 3.6, 4.3, -3), Color = Color3.fromRGB(35, 35, 40), Parent = model })
	end
	part({ Name = "Bar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 0.35, 0.35), CFrame = cframe * CFrame.new(0, 4.3, -3), Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = model })
	local pad = zone({ Name = W.Pad, Size = Vector3.new(5, 7, 9), CFrame = cframe * CFrame.new(0, 4, 0), Parent = model })
	pad:SetAttribute(A.Stat, stat)
	pad:SetAttribute(A.Tier, tier)
	return model
end
for index, tier in GymsConfig.Tiers do
	local angle = math.rad(gymConfig.StartAngle + (index - 1) * gymConfig.AngleStep)
	local isAdmin = tier.Key == "GymAdmin"
	local height = isAdmin and gymConfig.AdminHeight or 0
	local position = center + Vector3.new(math.sin(angle) * gymConfig.Radius, height, -math.cos(angle) * gymConfig.Radius)
	local gym = make("Model", { Name = tier.Key, Parent = gyms })
	gym:SetAttribute(A.Tier, tier.Key)
	local base = CFrame.lookAt(position, Vector3.new(center.X, position.Y, center.Z))
	local size = gymConfig.PlatformSize
	part({
		Name = "Platform",
		Size = Vector3.new(size.X, size.Y + height, size.Z),
		CFrame = base * CFrame.new(0, -(size.Y + height) / 2 + size.Y / 2 + 0.01, 0),
		Color = MapConfig.TierColors[tier.Key],
		Material = isAdmin and Enum.Material.Marble or Enum.Material.Concrete,
		Parent = gym,
	})
	if isAdmin then
		local stairLength = 36
		part({
			Name = "Stairs",
			Size = Vector3.new(12, 1, math.sqrt(stairLength ^ 2 + height ^ 2)),
			CFrame = base * CFrame.new(0, height / 2 - 0.5 + 0.5, -size.Z / 2 - stairLength / 2 + 1) * CFrame.Angles(math.atan2(height, stairLength), 0, 0) * CFrame.new(0, -height / 2 + 0.5, 0),
			Color = MapConfig.TierColors[tier.Key],
			Material = Enum.Material.Marble,
			Parent = gym,
		})
	end
	local floor = base * CFrame.new(0, size.Y / 2 + 0.6, 0)
	local count = gymConfig.MachinesPerStat
	for machine = 1, count do
		local offset = (machine - (count + 1) / 2) * 8
		treadmill(gym, floor * CFrame.new(-size.X / 4 + offset / 2, 0, 0) * CFrame.new(offset / 2, 0, 0), "Speed", tier.Key)
		bench(gym, floor * CFrame.new(size.X / 4 + offset / 2, 0, 0) * CFrame.new(offset / 2, 0, 0), "Strength", tier.Key)
	end
	local title = isAdmin and "ADMIN GYM" or (tier.Multiplier .. "x GYM")
	local subtitle = tier.RequiredEggs == 0 and "Free" or (tier.RequiredEggs == math.huge and "Gamepass only" or ("Hatch " .. tier.RequiredEggs .. " eggs"))
	local board = sign(gym, "Sign", floor * CFrame.new(0, 9, size.Z / 2 - 1) * CFrame.Angles(0, math.pi, 0), Vector3.new(22, 7, 1), title, subtitle, MapConfig.TierColors[tier.Key])
	board:SetAttribute(A.Tier, tier.Key)
end

local interiorConfig = MapConfig.Interior
local interior = make("Model", { Name = W.Interior, Parent = root })
local inCenter = interiorConfig.Center
part({
	Name = "Floor",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(4, interiorConfig.Radius * 2 + 8, interiorConfig.Radius * 2 + 8),
	CFrame = CFrame.new(inCenter + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(235, 222, 190),
	Material = Enum.Material.Sandstone,
	Parent = interior,
})
local wallRings = 10
for ringIndex = 1, wallRings do
	local f0 = (ringIndex - 1) / wallRings
	local f1 = ringIndex / wallRings
	local function radiusAt(f)
		local t = 0.0 + f
		return interiorConfig.Radius * math.sqrt(math.max(0, 1 - t * t)) + 1
	end
	local r0, r1 = radiusAt(f0), radiusAt(f1)
	local y0, y1 = f0 * interiorConfig.Height, f1 * interiorConfig.Height
	local mid = math.max((r0 + r1) / 2, 2)
	local segments = math.max(8, math.floor(2 * math.pi * mid / 12))
	local slant = math.sqrt((y1 - y0) ^ 2 + (r1 - r0) ^ 2)
	for index = 1, segments do
		local angle = (index - 0.5) / segments * math.pi * 2
		local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
		local up = (outward * (r1 - r0) + Vector3.new(0, y1 - y0, 0)).Unit
		part({
			Name = "Wall",
			Size = Vector3.new(2 * math.pi * mid / segments * 1.08, slant * 1.05, 2),
			CFrame = CFrame.fromMatrix(inCenter + outward * mid + Vector3.new(0, (y0 + y1) / 2, 0), tangent, up),
			Color = P.InteriorWall,
			Parent = interior,
		})
	end
end
local poolSize = interiorConfig.PoolSize
part({
	Name = "PoolRim",
	Size = poolSize + Vector3.new(6, -2, 6),
	CFrame = CFrame.new(inCenter + Vector3.new(0, 0.5, 8)),
	Color = Color3.fromRGB(210, 180, 120),
	Material = Enum.Material.Sandstone,
	Parent = interior,
})
local pool = part({
	Name = W.Pool,
	Size = poolSize,
	CFrame = CFrame.new(inCenter + Vector3.new(0, 1.6, 8)),
	Color = P.Yolk,
	Material = Enum.Material.Glass,
	Transparency = 0.25,
	CanCollide = false,
	Parent = interior,
})
pool:SetAttribute(A.Stat, "Both")
pool:SetAttribute(A.Tier, "Interior")
make("PointLight", { Color = P.Yolk, Range = 40, Brightness = 2, Parent = pool })
sign(interior, "TrainingSign", CFrame.new(inCenter + Vector3.new(0, 10, -18)) * CFrame.Angles(0, math.pi, 0), Vector3.new(30, 7, 1), "2X TRAINING INSIDE", "Swim to train both stats", Color3.fromRGB(200, 150, 40))
local arrive = zone({ Name = W.InteriorArrive, Size = Vector3.new(6, 1, 6), CFrame = CFrame.new(inCenter + Vector3.new(0, 3, -30)), Parent = interior })
arrive:SetAttribute("Interior", true)
part({ Name = "Throne", Size = Vector3.new(8, 10, 6), CFrame = CFrame.new(inCenter + Vector3.new(-48, 5, 10)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Foil, Parent = interior })
for index = 1, 14 do
	part({
		Name = "Treasure",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 3, 3),
		CFrame = CFrame.new(inCenter + Vector3.new(46 + random:NextNumber(-5, 5), 0.5 + index * 0.25, 10 + random:NextNumber(-5, 5))) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 205, 60),
		Material = Enum.Material.Foil,
		Parent = interior,
	})
end
make("PointLight", { Range = 60, Brightness = 1.5, Color = Color3.fromRGB(255, 235, 200), Parent = zone({ Name = "Light", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(inCenter + Vector3.new(0, 40, 0)), Parent = interior }) })

local L = MapConfig.Lighting
Lighting.ClockTime = L.ClockTime
Lighting.GeographicLatitude = L.GeographicLatitude
Lighting.Brightness = L.Brightness
Lighting.Ambient = L.Ambient
Lighting.OutdoorAmbient = L.OutdoorAmbient
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or make("Atmosphere", { Parent = Lighting })
atmosphere.Density = L.AtmosphereDensity
atmosphere.Haze = L.AtmosphereHaze
atmosphere.Color = L.AtmosphereColor
atmosphere.Decay = L.AtmosphereDecay
local grading = Lighting:FindFirstChild("Grading") or make("ColorCorrectionEffect", { Name = "Grading", Parent = Lighting })
grading.Saturation = 0.12
grading.Contrast = 0.06
grading.TintColor = Color3.fromRGB(255, 244, 232)
Workspace.FallenPartsDestroyHeight = -600

print("Map built")
