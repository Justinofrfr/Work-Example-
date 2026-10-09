local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local MapConfig = require(Shared.Config.Map)
local EggConfig = require(Shared.Config.Egg)
local GymsConfig = require(Shared.Config.Gyms)
local GameConfig = require(Shared.Config.Game)
local PropsConfig = require(Shared.Config.Props)
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
		TopSurface = Enum.SurfaceType.Studs,
		BottomSurface = Enum.SurfaceType.Inlet,
		Material = Enum.Material.Plastic,
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
			CFrame = CFrame.new((cframe * CFrame.new(side * (size.X / 2 + 0.7), 0, 0)).Position * Vector3.new(1, 0, 1) + Vector3.new(0, (cframe.Position.Y + size.Y / 2) / 2 - 0.5, 0)),
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

local function outline(parent)
	local O = PropsConfig.Shells.Outline
	return make("Highlight", {
		Name = "Outline",
		OutlineColor = O.Color,
		OutlineTransparency = O.Transparency,
		FillTransparency = O.FillTransparency,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Parent = parent,
	})
end

local root = make("Folder", { Name = W.Root, Parent = Workspace })
outline(make("Model", { Name = W.Piles, Parent = root }))

Workspace.Terrain:Clear()
local random = Random.new(7)
local groundSize = MapConfig.GroundSize
local groundFolder = make("Folder", { Name = "Ground", Parent = root })

local function studded(props)
	props.TopSurface = Enum.SurfaceType.Studs
	props.BottomSurface = Enum.SurfaceType.Inlet
	props.Material = props.Material or Enum.Material.Plastic
	return part(props)
end

local function slab(name, x0, x1, z0, z1, top, thickness, color)
	if x1 - x0 <= 0 or z1 - z0 <= 0 then
		return nil
	end
	return studded({
		Name = name,
		Size = Vector3.new(x1 - x0, thickness, z1 - z0),
		CFrame = CFrame.new((x0 + x1) / 2, top - thickness / 2, (z0 + z1) / 2),
		Color = color,
		Parent = groundFolder,
	})
end

local quarryConfig = MapConfig.Quarry
local quarryFolder = make("Folder", { Name = W.Quarry, Parent = root })
local pitCenter = quarryConfig.Center
local pitSize = quarryConfig.Size
local rampLength = 22
local rampHalf = 12
local half = groundSize.X / 2
local top = MapConfig.GroundTop
local thick = groundSize.Y
local px0, px1 = pitCenter.X - pitSize.X / 2, pitCenter.X + pitSize.X / 2
local pz0, pz1 = pitCenter.Z - pitSize.Z / 2, pitCenter.Z + pitSize.Z / 2
local rz1 = pz1 + rampLength
slab("Ground", -half, half, rz1, half, top, thick, P.Grass)
slab("Ground", -half, half, -half, pz0, top, thick, P.Grass)
slab("Ground", -half, px0, pz0, rz1, top, thick, P.Grass)
slab("Ground", px1, half, pz0, rz1, top, thick, P.Grass)
slab("Ground", px0, pitCenter.X - rampHalf, pz1, rz1, top, thick, P.Grass)
slab("Ground", pitCenter.X + rampHalf, px1, pz1, rz1, top, thick, P.Grass)
slab("PitFloor", px0, px1, pz0, pz1, top - pitSize.Y, 4, P.Path).Parent = quarryFolder
for side = -1, 1, 2 do
	for index = 1, 6 do
		local x = side < 0 and px0 or px1
		studded({
			Name = "PitRock",
			Size = Vector3.new(random:NextNumber(6, 10), random:NextNumber(6, 11), random:NextNumber(8, 12)),
			CFrame = CFrame.new(x, top - pitSize.Y / 2, pz0 + (index - 0.5) * pitSize.Z / 6) * CFrame.Angles(random:NextNumber(-0.3, 0.3), random:NextNumber(0, math.pi), random:NextNumber(-0.3, 0.3)),
			Color = index % 2 == 0 and P.Rock or P.RockDark,
			Parent = quarryFolder,
		})
	end
end

for index = 1, MapConfig.Hills.Count do
	local angle = index / MapConfig.Hills.Count * math.pi * 2
	local radius = MapConfig.Hills.Radius + random:NextNumber(-30, 30)
	local height = random:NextNumber(MapConfig.Hills.Height[1], MapConfig.Hills.Height[2])
	local width = random:NextNumber(MapConfig.Hills.Width[1], MapConfig.Hills.Width[2])
	local position = Vector3.new(math.cos(angle) * radius, top + height / 2 - 0.5, math.sin(angle) * radius)
	local wedge = Instance.new("WedgePart")
	wedge.Name = "Hill"
	wedge.Anchored = true
	wedge.Size = Vector3.new(width, height, MapConfig.Hills.Depth)
	wedge.CFrame = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
	wedge.Color = index % 3 == 0 and P.GrassDark or (index % 3 == 1 and P.Grass or P.GrassLight)
	wedge.Material = Enum.Material.Plastic
	wedge.TopSurface = Enum.SurfaceType.Studs
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Parent = groundFolder
	studded({
		Name = "HillTop",
		Size = Vector3.new(width, height, MapConfig.Hills.Depth),
		CFrame = wedge.CFrame * CFrame.new(0, 0, MapConfig.Hills.Depth),
		Color = wedge.Color,
		Parent = groundFolder,
	})
end

part({
	Name = "PitRamp",
	Size = Vector3.new(24, 1, math.sqrt(rampLength ^ 2 + pitSize.Y ^ 2)),
	CFrame = CFrame.new(pitCenter + Vector3.new(0, -pitSize.Y / 2, pitSize.Z / 2 + rampLength / 2 - 0.5)) * CFrame.Angles(-math.atan2(pitSize.Y, rampLength), 0, 0),
	Color = P.Path,
	Material = Enum.Material.Sandstone,
	Parent = quarryFolder,
})
zone({
	Name = W.QuarryZone,
	Size = Vector3.new(pitSize.X, pitSize.Y + 10, pitSize.Z),
	CFrame = CFrame.new(pitCenter + Vector3.new(0, -pitSize.Y / 2 + 5, 0)),
	Parent = quarryFolder,
})
local piecesFolder = make("Model", { Name = W.Pieces, Parent = quarryFolder })
outline(piecesFolder)
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
local giftBoard = sign(spawnFolder, W.Gift, facing(stands.Gift + Vector3.new(0, 7, 0), stands.Gift + Vector3.new(0, 7, -60)), Vector3.new(16, 10, 1.2), "FREE GIFT", "Like + Favorite + Join Group", P.Wood)
prompt(giftBoard, W.GiftPrompt, "Claim", "Free Gift", 0)
local shopBoard = sign(spawnFolder, W.ShopStand, facing(stands.Shop + Vector3.new(0, 7, 0), stands.Shop + Vector3.new(0, 7, -60)), Vector3.new(16, 10, 1.2), "SHOP", "Boosts and passes", Color3.fromRGB(60, 140, 70))
make("ProximityPrompt", { Name = W.StandPrompt, ActionText = "Shop", ObjectText = "Shop", KeyboardKeyCode = Enum.KeyCode.E, MaxActivationDistance = 12, RequiresLineOfSight = false, Parent = shopBoard }):SetAttribute("Panel", "Shop")

local LeaderboardsConfig = require(Shared.Config.Leaderboards)
local boardsFolder = make("Folder", { Name = "Leaderboards", Parent = spawnFolder })
for index, def in LeaderboardsConfig.Boards do
	local size = LeaderboardsConfig.BoardSize
	local position = LeaderboardsConfig.Positions[index] + Vector3.new(0, size.Y / 2 + 2, 0)
	local board = part({
		Name = def.Key,
		Size = size,
		CFrame = facing(position, LeaderboardsConfig.FacingTarget),
		Color = P.WoodDark,
		Material = Enum.Material.Wood,
		Parent = boardsFolder,
	})
	part({
		Name = "Post",
		Size = Vector3.new(2, size.Y / 2 + 2, 2),
		CFrame = CFrame.new(position.X, (size.Y / 2 + 2) / 2, position.Z) * facing(position, LeaderboardsConfig.FacingTarget).Rotation * CFrame.new(0, 0, 1.5),
		Color = P.WoodDark,
		Material = Enum.Material.Wood,
		Parent = boardsFolder,
	})
	local gui = make("SurfaceGui", {
		Name = "Gui",
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 25,
		LightInfluence = 0.1,
		Parent = board,
	})
	text({ Name = "Title", Text = def.Title, Size = UDim2.fromScale(0.94, 0.11), Position = UDim2.fromScale(0.03, 0.02), TextColor3 = def.Color, Parent = gui })
	local list = make("Frame", { Name = "List", Size = UDim2.fromScale(0.92, 0.82), Position = UDim2.fromScale(0.04, 0.15), BackgroundTransparency = 1, Parent = gui }, {
		make("UIListLayout", { Padding = UDim.new(0.01, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for rank = 1, LeaderboardsConfig.Rows do
		local row = make("Frame", {
			Name = "Row" .. rank,
			Size = UDim2.fromScale(1, 0.09),
			BackgroundColor3 = rank % 2 == 0 and Color3.fromRGB(90, 60, 38) or Color3.fromRGB(110, 74, 46),
			LayoutOrder = rank,
			Visible = false,
			Parent = list,
		}, { make("UICorner", { CornerRadius = UDim.new(0.3, 0) }) })
		text({ Name = "Player", Text = "#" .. rank, Size = UDim2.fromScale(0.66, 0.8), Position = UDim2.fromScale(0.03, 0.1), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		text({ Name = "Value", Text = "0", Size = UDim2.fromScale(0.28, 0.8), Position = UDim2.fromScale(0.69, 0.1), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = def.Color, Parent = row })
	end
end

local site = make("Folder", { Name = W.Site, Parent = root })
local center = EggConfig.Center
local egg = make("Model", { Name = W.Egg, Parent = site })
outline(egg)
local ringsFolder = make("Folder", { Name = W.Rings, Parent = egg })
local function shellTile()
	local GeometryService = game:GetService("GeometryService")
	local radius = 0.5 / math.sin(math.rad(EggConfig.TileArc / 2))
	local depth = EggConfig.TileThickness + radius * (1 - math.cos(math.rad(EggConfig.TileArc / 2))) + 0.05
	local outer = make("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, radius * 2, radius * 2), CFrame = CFrame.Angles(0, 0, math.rad(90)), Anchored = true })
	local inner = make("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, (radius - EggConfig.TileThickness) * 2, (radius - EggConfig.TileThickness) * 2), CFrame = CFrame.Angles(0, 0, math.rad(90)), Anchored = true })
	local box = make("Part", { Size = Vector3.new(1, 1, depth), CFrame = CFrame.new(0, 0, -radius + depth / 2), Anchored = true })
	local ok, tile = pcall(function()
		local slab = GeometryService:IntersectAsync(box, { outer }, { CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Precise })[1]
		return GeometryService:SubtractAsync(slab, { inner }, { CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false })[1]
	end)
	outer:Destroy()
	inner:Destroy()
	box:Destroy()
	if not ok or not tile then
		warn("shell tile CSG failed: " .. tostring(tile))
		return nil
	end
	tile.UsePartColor = true
	pcall(function()
		tile.SmoothingAngle = EggConfig.TileSmoothing
	end)
	tile.Anchored = true
	return tile
end
local importedTile = ServerStorage:FindFirstChild("Imported") and ServerStorage.Imported:FindFirstChild("ShellTile")
local tileMesh = importedTile and importedTile:FindFirstChildWhichIsA("MeshPart", true)
local tileTemplate
if tileMesh then
	tileTemplate = tileMesh:Clone()
	for _, child in tileTemplate:GetChildren() do
		child:Destroy()
	end
	tileTemplate.CollisionFidelity = Enum.CollisionFidelity.Box
	tileTemplate.RenderFidelity = Enum.RenderFidelity.Precise
else
	tileTemplate = shellTile()
end
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
		local segment = tileTemplate and tileTemplate:Clone() or part({ Name = tostring(index) })
		segment.Name = tostring(index)
		for key, value in {
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth,
			Size = Vector3.new(width, slant * 1.04, EggConfig.ShellThickness),
			CFrame = CFrame.fromMatrix(position, tangent, up),
			Color = P.Shell,
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
			Anchored = true,
			CanQuery = false,
			CanTouch = false,
		} do
			segment[key] = value
		end
		segment.Parent = ringModel
		segment:SetAttribute(A.Segment, ring.First + index - 1)
	end
end
make("BillboardGui", {
	Name = W.EggBoard,
	Size = UDim2.fromOffset(420, 120),
	StudsOffsetWorldSpace = Vector3.new(0, EggShape.ScaffoldHeight() + 30, 0),
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
local stairWidth = EggConfig.ScaffoldWidth
local stairThickness = EggConfig.ScaffoldThickness
local rings = EggShape.Rings()
local overlap = EggConfig.ScaffoldJointOverlap
local function rampHeight(ring, fraction)
	local lowHeight = ring > 1 and EggShape.BandHeight(ring - 1) or center.Y
	return lowHeight + (EggShape.BandHeight(ring) - lowHeight) * fraction
end
for index = 1, #rings do
	local ringLength, turn = 0, 0
	local previous = EggShape.ScaffoldPoint(rampHeight(index, 0))
	local heading
	for sample = 1, 16 do
		local point = EggShape.ScaffoldPoint(rampHeight(index, sample / 16))
		local delta = (point - previous) * Vector3.new(1, 0, 1)
		ringLength += (point - previous).Magnitude
		if heading and delta.Magnitude > 0 then
			turn += math.deg(math.acos(math.clamp(heading:Dot(delta.Unit), -1, 1)))
		end
		heading = delta.Magnitude > 0 and delta.Unit or heading
		previous = point
	end
	local substeps = math.clamp(math.max(math.ceil(ringLength / EggConfig.ScaffoldSegmentLength), math.ceil(turn / EggConfig.ScaffoldSegmentTurn)), EggConfig.ScaffoldSubsteps, EggConfig.ScaffoldMaxSubsteps)
	for sub = 1, substeps do
		local low = EggShape.ScaffoldPoint(rampHeight(index, (sub - 1) / substeps))
		local high = EggShape.ScaffoldPoint(rampHeight(index, sub / substeps))
		local length = (high - low).Magnitude
		local mid = (low + high) / 2
		local frame = CFrame.lookAt(mid, high, Vector3.yAxis)
		local parity = (index + sub) % 2
		local surface = studded({
			Name = "Step",
			Size = Vector3.new(stairWidth + parity * 0.2, stairThickness, length + overlap * 2),
			CFrame = frame * CFrame.new(0, -stairThickness / 2 + parity * EggConfig.ScaffoldParityLift, 0),
			Color = EggConfig.ScaffoldSurfaceColor,
			Parent = scaffold,
		})
		surface:SetAttribute("Height", mid.Y)
		surface:SetAttribute(A.Ring, index)
		for side = -1, 1, 2 do
			part({
				Name = "Rail",
				Size = Vector3.new(EggConfig.ScaffoldWallWidth, EggConfig.ScaffoldWallHeight, length + overlap * 2),
				CFrame = frame * CFrame.new(side * (stairWidth / 2 - EggConfig.ScaffoldWallWidth / 2 - 0.15), EggConfig.ScaffoldWallHeight / 2 + parity * EggConfig.ScaffoldParityLift, 0),
				Color = EggConfig.ScaffoldWallColor,
				Parent = scaffold,
			}):SetAttribute(A.Ring, index)
		end
		if sub == math.ceil(substeps / 2) then
			local arrowSize = EggConfig.RampArrowSize
			local arrow = part({
				Name = "RampArrow",
				Size = Vector3.new(arrowSize, 0.05, arrowSize),
				CFrame = frame * CFrame.new(0, EggConfig.RampArrowLift + parity * EggConfig.ScaffoldParityLift, 0) * CFrame.Angles(0, math.rad(EggConfig.RampArrowRotation), 0),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				CastShadow = false,
				Parent = scaffold,
			})
			arrow:SetAttribute(A.Ring, index)
			arrow:SetAttribute(A.Overlay, true)
			make("Decal", { Name = "Arrow", Face = Enum.NormalId.Top, Texture = EggConfig.RampArrowImage, Transparency = EggConfig.RampArrowTransparency, Parent = arrow })
		end
		local inward = Vector3.new(center.X - mid.X, 0, center.Z - mid.Z)
		local flat = inward.Magnitude
		local shell = EggShape.ShellRadius(mid.Y)
		if sub == substeps and shell > 0 then
			local reach = flat - shell + EggConfig.ScaffoldBraceEmbed
			local size = EggConfig.ScaffoldBraceSize
			local origin = Vector3.new(mid.X, mid.Y - stairThickness - size / 2, mid.Z)
			if reach > 1 then
				studded({
					Name = "Brace",
					Size = Vector3.new(size, size, reach),
					CFrame = CFrame.lookAt(origin + inward.Unit * reach / 2, origin + inward.Unit * reach),
					Color = EggConfig.ScaffoldPillarColor,
					Parent = scaffold,
				}):SetAttribute(A.Ring, index)
			end
		elseif sub == substeps and mid.Y - stairThickness > 1 then
			local pillarTop = mid.Y - stairThickness - center.Y
			for side = -1, 1, 2 do
				local base = mid + frame.RightVector * side * (stairWidth / 2 - EggConfig.ScaffoldPillarSize / 2 - 0.6)
				studded({
					Name = "Post",
					Size = Vector3.new(EggConfig.ScaffoldPillarSize, pillarTop, EggConfig.ScaffoldPillarSize),
					CFrame = CFrame.new(base.X, center.Y + pillarTop / 2, base.Z),
					Color = EggConfig.ScaffoldPillarColor,
					Parent = scaffold,
				}):SetAttribute(A.Ring, index)
			end
		end
	end
end

local fxAnchor = zone({ Name = "FxAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(center + Vector3.new(0, -40, 0)), Parent = site })
for index = 1, 20 do
	make("Attachment", { Name = "Popup" .. index, Parent = fxAnchor })
end

local band = make("Folder", { Name = W.Band, Parent = site })
local placeAnchor = zone({ Name = "Point1", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(center + Vector3.new(0, -50, 0)), Parent = band })
prompt(placeAnchor, W.PlacePrompt, "Place Shells", "Egg", GameConfig.PlaceHoldTime).MaxActivationDistance = EggConfig.PlacePromptDistance
local placeZone = part({
	Name = "PlaceZone",
	Size = Vector3.new(EggConfig.ScaffoldWidth - EggConfig.PlaceZoneInset, EggConfig.PlaceZoneThickness, 8),
	CFrame = CFrame.new(center + Vector3.new(0, -50, 0)),
	Color = P.Band,
	Material = Enum.Material.Neon,
	Transparency = 0.45,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	TopSurface = Enum.SurfaceType.Smooth,
	BottomSurface = Enum.SurfaceType.Smooth,
	Parent = band,
})
make("ParticleEmitter", {
	Name = "Rise",
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Rate = 14,
	Lifetime = NumberRange.new(1.2, 2),
	Speed = NumberRange.new(3, 6),
	EmissionDirection = Enum.NormalId.Top,
	SpreadAngle = Vector2.new(8, 8),
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
	Color = ColorSequence.new(P.Band),
	LightEmission = 1,
	Shape = Enum.ParticleEmitterShape.Box,
	ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	Parent = placeZone,
})
make("BillboardGui", {
	Name = "Label",
	Size = UDim2.fromScale(16, 5),
	StudsOffsetWorldSpace = Vector3.new(0, EggConfig.PlaceLabelHeight, 0),
	AlwaysOnTop = true,
	LightInfluence = 0,
	MaxDistance = 600,
	Parent = placeAnchor,
}, {
	text({ Name = "Title", Text = "PLACE SHELLS HERE", Size = UDim2.fromScale(1, 0.55), TextColor3 = Color3.fromRGB(140, 255, 140) }),
	text({ Name = "Arrow", Text = "⬇", Size = UDim2.fromScale(1, 0.45), Position = UDim2.fromScale(0, 0.55), TextColor3 = Color3.fromRGB(140, 255, 140) }),
})

local trail = make("Folder", { Name = W.Trail, Parent = site })
local startPoint = pitCenter + Vector3.new(0, 0.3, pitSize.Z / 2 + rampLength)
local endPoint = EggShape.ScaffoldPoint(center.Y + 0.6)
local pathVector = Vector3.new(endPoint.X, 0.3, endPoint.Z) - startPoint
local distance = pathVector.Magnitude
studded({ Name = "Path", Size = Vector3.new(14, 1, distance), CFrame = CFrame.lookAt(startPoint + pathVector / 2 - Vector3.new(0, 0.6, 0), startPoint + pathVector - Vector3.new(0, 0.6, 0)), Color = P.Path, Parent = groundFolder })
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
	local slot = gymConfig.Slots[tier.Key]
	local isAdmin = tier.Key == "GymAdmin"
	local height = isAdmin and gymConfig.AdminHeight or 0
	local position = slot.Position + Vector3.new(0, center.Y + height, 0)
	local gym = make("Model", { Name = tier.Key, Parent = gyms })
	gym:SetAttribute(A.Tier, tier.Key)
	local base = CFrame.lookAt(position, Vector3.new(slot.Face.X, position.Y, slot.Face.Z))
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
		local stairLength = gymConfig.AdminRampLength
		local rise = height + size.Y / 2
		make("WedgePart", {
			Name = "Stairs",
			Anchored = true,
			Size = Vector3.new(gymConfig.AdminRampWidth, rise, stairLength),
			CFrame = base * CFrame.new(0, size.Y / 2 - rise / 2, -size.Z / 2 - stairLength / 2),
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
	local board = sign(gym, "Sign", floor * CFrame.new(0, 9, size.Z / 2 - 1), Vector3.new(22, 7, 1), title, subtitle, MapConfig.TierColors[tier.Key])
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
			Size = Vector3.new(2 * math.pi * mid / segments * 1.08, slant * 1.05, 2 + (ringIndex % 2) * 0.6),
			CFrame = CFrame.fromMatrix(inCenter + outward * mid + Vector3.new(0, (y0 + y1) / 2, 0), tangent, up),
			Color = P.InteriorWall,
			Parent = interior,
		})
	end
end
local poolSize = interiorConfig.PoolSize
local poolDepth = interiorConfig.PoolDepth
local poolCenter = inCenter + Vector3.new(0, poolDepth / 2, 8)
local rimHeight = poolDepth + 1
for _, wall in {
	{ Vector3.new(poolSize.X + 6, rimHeight, 3), Vector3.new(0, 0, poolSize.Z / 2 + 1.5) },
	{ Vector3.new(poolSize.X + 6, rimHeight, 3), Vector3.new(0, 0, -poolSize.Z / 2 - 1.5) },
	{ Vector3.new(3, rimHeight, poolSize.Z), Vector3.new(poolSize.X / 2 + 1.5, 0, 0) },
	{ Vector3.new(3, rimHeight, poolSize.Z), Vector3.new(-poolSize.X / 2 - 1.5, 0, 0) },
} do
	part({
		Name = "PoolRim",
		Size = wall[1],
		CFrame = CFrame.new(inCenter + Vector3.new(0, rimHeight / 2 - 0.5, 8) + wall[2]),
		Color = Color3.fromRGB(210, 180, 120),
		Material = Enum.Material.Sandstone,
		Parent = interior,
	})
end
for side = -1, 1, 2 do
	part({
		Name = "PoolStep",
		Size = Vector3.new(8, rimHeight / 2, 3),
		CFrame = CFrame.new(inCenter + Vector3.new(side * 14, rimHeight / 4 - 0.5, 8 - poolSize.Z / 2 - 4.5)),
		Color = Color3.fromRGB(230, 200, 140),
		Material = Enum.Material.Sandstone,
		Parent = interior,
	})
end
Workspace.Terrain:FillBlock(CFrame.new(poolCenter), Vector3.new(poolSize.X, poolDepth, poolSize.Z), Enum.Material.Water)
Workspace.Terrain.WaterColor = interiorConfig.WaterColor
Workspace.Terrain.WaterTransparency = 0.35
Workspace.Terrain.WaterReflectance = 0.25
Workspace.Terrain.WaterWaveSize = 0.1
local pool = part({
	Name = W.Pool,
	Size = Vector3.new(poolSize.X, poolDepth + 4, poolSize.Z),
	CFrame = CFrame.new(poolCenter + Vector3.new(0, 2, 0)),
	Color = P.Yolk,
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
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
Lighting.ExposureCompensation = L.ExposureCompensation
Lighting.ColorShift_Top = L.ColorShiftTop
Lighting.ColorShift_Bottom = L.ColorShiftBottom
Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale
Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale
Lighting.GlobalShadows = true
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or make("Atmosphere", { Parent = Lighting })
atmosphere.Density = L.AtmosphereDensity
atmosphere.Haze = L.AtmosphereHaze
atmosphere.Glare = L.AtmosphereGlare
atmosphere.Color = L.AtmosphereColor
atmosphere.Decay = L.AtmosphereDecay
local grading = Lighting:FindFirstChild("Grading") or make("ColorCorrectionEffect", { Name = "Grading", Parent = Lighting })
grading.Saturation = L.Saturation
grading.Contrast = L.Contrast
grading.Brightness = L.ColorBrightness
grading.TintColor = L.Tint
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or make("BloomEffect", { Parent = Lighting })
bloom.Intensity = L.BloomIntensity
bloom.Size = L.BloomSize
bloom.Threshold = L.BloomThreshold
local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or make("SunRaysEffect", { Parent = Lighting })
rays.Intensity = L.SunRaysIntensity
local spotlightBlur = Lighting:FindFirstChild("SpotlightBlur") or make("BlurEffect", { Name = "SpotlightBlur", Parent = Lighting })
spotlightBlur.Size = require(Shared.Config.Tutorial).SpotlightBlur
spotlightBlur.Enabled = false
local depth = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
if depth then
	depth.Enabled = false
end
Workspace.FallenPartsDestroyHeight = -600

print("Map built")
