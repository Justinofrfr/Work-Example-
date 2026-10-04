local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local MapConfig = require(Shared.Config.Map)

local SC = MapConfig.Scenery
local W = Names.World
local world = Workspace:WaitForChild(W.Root)
local imported = ServerStorage:WaitForChild("Imported")
local random = Random.new(SC.Seed)

local function make(className, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local existing = world:FindFirstChild("Scenery")
if existing then
	existing:Destroy()
end
local scenery = make("Folder", { Name = "Scenery", Parent = world })
local folders = {}
local function folder(name)
	folders[name] = folders[name] or make("Folder", { Name = name, Parent = scenery })
	return folders[name]
end

local function pick(list)
	return list[random:NextInteger(1, #list)]
end

local function baseName(prefix)
	return (prefix:gsub("%d+$", ""):gsub("%u$", ""))
end

local function roleDef(prefix, role)
	return SC.Roles[baseName(prefix) .. role] or SC.Roles[role] or SC.Roles.Grass
end

local function solidFor(prefix, role)
	local rule = SC.Collide[baseName(prefix)]
	return rule ~= nil and rule[role] == true
end

local function style(part, prefix, role)
	local def = roleDef(prefix, role)
	for _, child in part:GetChildren() do
		child:Destroy()
	end
	local solid = solidFor(prefix, role)
	part.Anchored = true
	part.TextureID = ""
	part.PivotOffset = CFrame.identity
	part.Color = pick(def.Colors)
	part.Material = def.Material or Enum.Material.SmoothPlastic
	part.Transparency = def.Transparency or 0
	part.Reflectance = 0
	part.CanCollide = solid
	part.CanQuery = solid
	part.CanTouch = false
	part.CastShadow = part.Size.Magnitude > 5
	part:SetAttribute("Role", role)
end

local function keepLegacy(prefix)
	for _, pattern in SC.Keep do
		if prefix:find(pattern) then
			return true
		end
	end
	return false
end

local groups = {}
for _, sourceName in SC.Sources do
	local source = imported:FindFirstChild(sourceName)
	if source then
		local anchor = source:FindFirstChild("World_Anchor_Marker", true)
		local offset = anchor and -anchor.Position or Vector3.zero
		local found = {}
		for _, part in source:GetDescendants() do
			if part:IsA("MeshPart") then
				local prefix, role = part.Name:match("^(.-)_(%a+)$")
				local legacy = sourceName == SC.Sources[1]
				if prefix and not prefix:find("^World_Anchor") and (not legacy or keepLegacy(prefix)) then
					found[prefix] = found[prefix] or { Entries = {}, Offset = offset }
					table.insert(found[prefix].Entries, { Part = part, Role = role })
				end
			end
		end
		for prefix, group in found do
			groups[prefix] = group
		end
	end
end

local templates = {}
for prefix, group in groups do
	if not prefix:find("^World") then
		local model = Instance.new("Model")
		model.Name = prefix
		for _, entry in group.Entries do
			local part = entry.Part:Clone()
			style(part, prefix, entry.Role)
			part.Parent = model
		end
		local box, size = model:GetBoundingBox()
		model.WorldPivot = CFrame.new(box.Position.X, box.Position.Y - size.Y / 2, box.Position.Z)
		templates[prefix] = model
	end
end

local function variants(base)
	local list = {}
	for prefix in templates do
		if baseName(prefix) == base then
			table.insert(list, prefix)
		end
	end
	table.sort(list)
	return list
end

local function place(prefix, cframe, scale, parent)
	local template = templates[prefix]
	if not template then
		return nil
	end
	local model = template:Clone()
	for _, part in model:GetChildren() do
		part.Color = pick(roleDef(prefix, part:GetAttribute("Role")).Colors)
	end
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cframe)
	local base = baseName(prefix)
	local sway = SC.Sway[base]
	if sway then
		model:SetAttribute("Sway", sway)
		if base == "Oak" or base == "Pine" then
			model:SetAttribute("SwayLeaves", true)
		end
		CollectionService:AddTag(model, "Sway")
	end
	model.Parent = parent
	return model
end

local hillParts = {}
for prefix, group in groups do
	if prefix:find("^World") then
		for _, entry in group.Entries do
			if not (prefix == "World_River" and entry.Role == "Water") then
				local part = entry.Part:Clone()
				style(part, prefix, entry.Role)
				part.CFrame = part.CFrame + group.Offset
				if prefix:find("^World_Hills") then
					part.Color = SC.Hills.Color
					part.CastShadow = true
					pcall(function()
						part.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
					end)
					make("SurfaceAppearance", { ColorMap = SC.Hills.Studs, AlphaMode = Enum.AlphaMode.Overlay, Parent = part })
					part.Parent = folder("Hills")
					table.insert(hillParts, part)
				elseif prefix:find("^World_Path") then
					part.CastShadow = false
					part.Parent = folder("PathStones")
				elseif prefix:find("^World_Falls") then
					part.Parent = folder("Waterfall")
				else
					part.CanQuery = true
					part.Parent = folder("Water")
				end
			end
		end
	end
end

local function smooth(points, steps)
	local out = {}
	local n = #points
	for i = 1, n - 1 do
		local p0, p1, p2, p3 = points[math.max(i - 1, 1)], points[i], points[i + 1], points[math.min(i + 2, n)]
		for s = 0, steps - 1 do
			local t = s / steps
			local t2, t3 = t * t, t * t * t
			table.insert(out, 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
		end
	end
	table.insert(out, points[n])
	return out
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function segmentDistance(p, a, b)
	local ab = flat(b - a)
	local ap = flat(p - a)
	local t = ab.Magnitude > 0 and math.clamp(ap:Dot(ab) / ab:Dot(ab), 0, 1) or 0
	return (flat(a) + ab * t - flat(p)).Magnitude
end

local function polylineDistance(p, points)
	local best = math.huge
	for i = 1, #points - 1 do
		best = math.min(best, segmentDistance(p, points[i], points[i + 1]))
	end
	return best
end

local river = smooth(SC.River.Points, 12)

local terrain = Workspace.Terrain
terrain:Clear()
local water = SC.Water
for i = 1, #river - 1 do
	local a, b = river[i], river[i + 1]
	local mid = (a + b) / 2
	terrain:FillBlock(CFrame.lookAt(Vector3.new(mid.X, water.Center, mid.Z), Vector3.new(b.X, water.Center, b.Z)), Vector3.new(water.Width, water.Depth, (b - a).Magnitude + water.Width * 0.6), Enum.Material.Water)
end
for _, body in { { SC.River.Pond.Center, water.PondRadius }, { SC.River.Pool.Center, SC.River.Pool.Radius } } do
	terrain:FillCylinder(CFrame.new(body[1].X, water.Center, body[1].Z), water.Depth, body[2], Enum.Material.Water)
end
terrain.WaterColor = water.Color
terrain.WaterWaveSize = water.WaveSize
terrain.WaterWaveSpeed = water.WaveSpeed
terrain.WaterTransparency = water.Transparency
terrain.WaterReflectance = water.Reflectance

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = hillParts
task.wait(2)
local function slopeHeight(x, z)
	local hit = Workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), rayParams)
	if hit then
		return hit.Position.Y, hit.Normal.Y
	end
	return 0, 1
end

local occupied = {}
local cell = 16
local function occupiedNear(p, radius)
	local cx, cz = math.floor(p.X / cell), math.floor(p.Z / cell)
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, entry in occupied[(cx + dx) .. ":" .. (cz + dz)] or {} do
				if (flat(entry.P) - flat(p)).Magnitude < radius + entry.R then
					return true
				end
			end
		end
	end
	return false
end
local function occupy(p, radius)
	local k = math.floor(p.X / cell) .. ":" .. math.floor(p.Z / cell)
	occupied[k] = occupied[k] or {}
	table.insert(occupied[k], { P = p, R = radius })
end

local function nearWater(p, margin)
	if polylineDistance(p, river) < SC.River.Clearance + margin then
		return true
	end
	for _, body in { SC.River.Pond, SC.River.Pool } do
		if (flat(p) - flat(body.Center)).Magnitude < body.Radius + margin then
			return true
		end
	end
	return false
end

local function blocked(p, margin)
	local flatP = flat(p)
	for _, zone in SC.Exclusions do
		if zone.Radius then
			if (flatP - flat(zone.Center)).Magnitude < zone.Radius + margin then
				return true
			end
		elseif p.X > zone.Min.X - margin and p.X < zone.Max.X + margin and p.Z > zone.Min.Z - margin and p.Z < zone.Max.Z + margin then
			return true
		end
	end
	for _, path in SC.Paths do
		if polylineDistance(p, path.Points) < path.Width / 2 + margin then
			return true
		end
	end
	if nearWater(p, margin) then
		return true
	end
	for _, lookout in SC.Lookouts do
		if (flatP - flat(lookout.Center)).Magnitude < lookout.Radius + margin then
			return true
		end
	end
	return false
end

local function ring(minRadius, maxRadius)
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = math.sqrt(random:NextNumber(minRadius * minRadius, maxRadius * maxRadius))
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function yaw()
	return CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
end

local function studded(props)
	props.Anchored = true
	props.TopSurface = Enum.SurfaceType.Studs
	props.BottomSurface = Enum.SurfaceType.Inlet
	props.Material = Enum.Material.Plastic
	props.CanTouch = false
	return make("Part", props)
end

local function groundAt(p)
	if flat(p).Magnitude <= SC.FlatRadius then
		return 0, 1
	end
	return slopeHeight(p.X, p.Z)
end

local function scatter(options)
	local placed = 0
	local spots = {}
	for _ = 1, options.Count * 10 do
		if placed >= options.Count then
			break
		end
		local spot = options.Spot()
		if spot and not blocked(spot, options.Margin or 2) and (not options.Spacing or not occupiedNear(spot, options.Spacing)) then
			local y, up = groundAt(spot)
			if up >= (options.MinUp or 0.7) then
				local scale = random:NextNumber(options.Scale[1], options.Scale[2])
				local sink = (options.Lift or 0) - (1 - up) * (options.SlopeSink or 4) * scale
				local model = place(options.Prefix(), CFrame.new(spot.X, y + sink, spot.Z) * yaw(), scale, folder(options.Folder))
				if model then
					if options.Spacing then
						occupy(spot, options.Spacing * 0.7)
					end
					if options.After then
						options.After(model)
					end
					table.insert(spots, spot)
					placed += 1
				end
			end
		end
	end
	return placed, spots
end

local pathFolder = folder("Paths")
for _, path in SC.Paths do
	if not path.Hidden then
		for i = 1, #path.Points - 1 do
			local a, b = path.Points[i], path.Points[i + 1]
			local length = (b - a).Magnitude
			local mid = (a + b) / 2
			studded({
				Name = "Path",
				Size = Vector3.new(path.Width + 1, 0.4, length + path.Width * 0.5),
				CFrame = CFrame.lookAt(mid, b) + Vector3.new(0, SC.PathLift - 0.2 + (i % 2) * 0.02, 0),
				Color = SC.PathColor,
				Parent = pathFolder,
			})
			local direction = (b - a).Unit
			local right = Vector3.new(-direction.Z, 0, direction.X)
			for step = 0, math.floor(length / SC.LampSpacing) do
				local side = (step % 2 == 0) and 1 or -1
				local spot = a + direction * (step + 0.5) * SC.LampSpacing + right * side * (path.Width / 2 + 2.5)
				if (spot - a):Dot(direction) < length then
					place("Lamp", CFrame.lookAt(spot, spot - right * side), 1, folder("Lamps"))
				end
			end
		end
	end
end

for _, plaza in SC.Plazas do
	local size = plaza.Max - plaza.Min
	studded({
		Name = plaza.Name,
		Size = Vector3.new(size.X, 0.4, size.Z),
		CFrame = CFrame.new((plaza.Min + plaza.Max) / 2 + Vector3.new(0, SC.PathLift - 0.19, 0)),
		Color = plaza.Color,
		Parent = pathFolder,
	})
end

for _, bridge in SC.Bridges do
	local along = flat(bridge.Along).Unit
	place("Bridge", CFrame.fromMatrix(bridge.Position, along, Vector3.yAxis), 1, folder("Bridges"))
	local riverDir = Vector3.new(-along.Z, 0, along.X)
	for side = -1, 1, 2 do
		for bank = -1, 1, 2 do
			local spot = bridge.Position + along * bank * 20 + riverDir * side * 13
			place("Fence", CFrame.fromMatrix(spot, riverDir, Vector3.yAxis), 1, folder("Fences"))
		end
	end
end

for _, lookout in SC.Lookouts do
	studded({
		Name = "Lookout",
		Size = Vector3.new(lookout.Radius * 1.6, 0.4, lookout.Radius * 1.6),
		CFrame = CFrame.lookAt(lookout.Center, Vector3.new(lookout.Face.X, 0, lookout.Face.Z)) + Vector3.new(0, SC.PathLift - 0.2, 0),
		Color = SC.PathColor,
		Parent = pathFolder,
	})
	local toward = flat(lookout.Face - lookout.Center).Unit
	local right = Vector3.new(-toward.Z, 0, toward.X)
	for k = -1, 1 do
		local spot = lookout.Center + toward * 6 + right * k * 9
		place("Bench", CFrame.lookAt(spot, spot + toward) * CFrame.Angles(0, math.pi, 0), 1, folder("Benches"))
	end
	for k = -2, 2 do
		local spot = lookout.Center + toward * (lookout.Radius * 0.8) + right * k * 11.5
		place("Fence", CFrame.fromMatrix(spot, right, Vector3.yAxis), 1, folder("Fences"))
	end
end

local F = SC.Flat
local S = SC.Slopes
local oaks = variants("Oak")
local pines = variants("Pine")
local flatRadius = SC.FlatRadius - 8
local _, flatTrees = scatter({
	Count = F.Trees.Count,
	Folder = "Trees",
	Scale = F.Trees.Scale,
	Spacing = F.Trees.Spacing,
	Margin = 7,
	Lift = -0.4,
	Spot = function()
		local spot = ring(150, flatRadius)
		return math.noise(spot.X * F.Trees.Cluster, spot.Z * F.Trees.Cluster, 3.7) > -0.1 and spot or nil
	end,
	Prefix = function()
		return pick(random:NextNumber() < F.Trees.Pines and pines or oaks)
	end,
})
local _, slopeTrees = scatter({
	Count = S.Trees.Count,
	Folder = "Trees",
	Scale = S.Trees.Scale,
	Spacing = S.Trees.Spacing,
	Margin = 6,
	Lift = -0.8,
	MinUp = 0.6,
	SlopeSink = 9,
	Spot = function()
		local spot = ring(SC.HillRadius[1] + 8, SC.HillRadius[2])
		return math.noise(spot.X * S.Trees.Cluster, spot.Z * S.Trees.Cluster, 8.1) > -0.35 and spot or nil
	end,
	Prefix = function()
		return pick(random:NextNumber() < S.Trees.Pines and pines or oaks)
	end,
})

local outcrops = variants("Outcrop")
for index = 1, S.Outcrops.Count do
	local angle = index / S.Outcrops.Count * math.pi * 2 + random:NextNumber(-0.08, 0.08)
	local radius = random:NextNumber(S.Outcrops.Radius[1], S.Outcrops.Radius[2])
	local spot = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	if not nearWater(spot, 50) and not blocked(spot, 10) then
		local y = slopeHeight(spot.X, spot.Z)
		place(pick(outcrops), CFrame.lookAt(Vector3.new(spot.X, y - S.Outcrops.Sink, spot.Z), Vector3.new(0, y - S.Outcrops.Sink, 0)), random:NextNumber(S.Outcrops.Scale[1], S.Outcrops.Scale[2]), folder("Rocks"))
		occupy(spot, 22)
	end
end

local boulders = variants("Boulder")
scatter({ Count = F.Boulders.Count, Folder = "Rocks", Scale = F.Boulders.Scale, Spacing = 5, Margin = 3, Lift = -0.5, Spot = function()
	return ring(150, flatRadius)
end, Prefix = function()
	return pick(boulders)
end })
scatter({ Count = S.Boulders.Count, Folder = "Rocks", Scale = S.Boulders.Scale, Spacing = 6, Margin = 3, Lift = -1.2, MinUp = 0.5, Spot = function()
	return ring(SC.HillRadius[1], SC.HillRadius[2] - 40)
end, Prefix = function()
	return pick(boulders)
end })

local function nearTree(minDistance, maxDistance)
	return function()
		if #flatTrees == 0 then
			return ring(150, flatRadius)
		end
		local angle = random:NextNumber(0, math.pi * 2)
		return pick(flatTrees) + Vector3.new(math.cos(angle), 0, math.sin(angle)) * random:NextNumber(minDistance, maxDistance)
	end
end
local logs = variants("Log")
scatter({ Count = F.Logs.Count, Folder = "Logs", Scale = { 0.8, 1.3 }, Spacing = 6, Margin = 3, Lift = -0.2, Spot = nearTree(10, 18), Prefix = function()
	return pick(logs)
end })
scatter({ Count = F.Stumps.Count, Folder = "Logs", Scale = { 0.7, 1.2 }, Spacing = 4, Margin = 3, Lift = -0.1, Spot = nearTree(9, 20), Prefix = function()
	return "Stump"
end })
local bushes = variants("Bush")
scatter({ Count = F.Bushes.Count, Folder = "Bushes", Scale = F.Bushes.Scale, Spacing = 3, Margin = 2, Lift = -0.4, Spot = function()
	return random:NextNumber() < 0.65 and nearTree(7, 13)() or ring(150, flatRadius)
end, Prefix = function()
	return pick(bushes)
end })
scatter({ Count = S.Bushes.Count, Folder = "Bushes", Scale = S.Bushes.Scale, Spacing = 3, Margin = 2, Lift = -0.6, MinUp = 0.6, Spot = function()
	return ring(SC.HillRadius[1], SC.HillRadius[2] - 30)
end, Prefix = function()
	return pick(bushes)
end })
scatter({ Count = F.Ferns.Count, Folder = "Ferns", Scale = F.Ferns.Scale, Margin = 1, Spot = function()
	return random:NextNumber() < 0.6 and nearTree(4, 10)() or ring(150, flatRadius)
end, Prefix = function()
	return "Fern"
end })
scatter({ Count = F.Mushrooms.Count, Folder = "Ferns", Scale = F.Mushrooms.Scale, Margin = 1, Spot = nearTree(3, 7), Prefix = function()
	return "Mushroom"
end })
scatter({ Count = F.Pebbles.Count, Folder = "Rocks", Scale = F.Pebbles.Scale, Margin = 0.5, Spot = function()
	return ring(95, flatRadius)
end, Prefix = function()
	return "Pebbles"
end })

local grassVariants = variants("Grass")
local flowerVariants = variants("Flower")
local grassFolder = folder("Grass")
local function grassAt(spot, scaleRange)
	local y = groundAt(spot)
	return place(pick(grassVariants), CFrame.new(spot.X, y, spot.Z) * yaw(), random:NextNumber(scaleRange[1], scaleRange[2]), grassFolder)
end
local function inPlaza(spot)
	for _, plaza in SC.Plazas do
		if spot.X > plaza.Min.X and spot.X < plaza.Max.X and spot.Z > plaza.Min.Z and spot.Z < plaza.Max.Z then
			return true
		end
	end
	return false
end
for _, path in SC.Paths do
	if not path.Hidden then
		for i = 1, #path.Points - 1 do
			local a, b = path.Points[i], path.Points[i + 1]
			local length = (b - a).Magnitude
			local direction = (b - a).Unit
			local right = Vector3.new(-direction.Z, 0, direction.X)
			for along = 0, length, F.EdgeGrass.Spacing do
				for side = -1, 1, 2 do
					local spot = a + direction * (along + random:NextNumber(-1, 1)) + right * side * (path.Width / 2 + random:NextNumber(0.5, 2.5))
					if not inPlaza(spot) and not nearWater(spot, -4) then
						grassAt(spot, F.EdgeGrass.Scale)
					end
				end
			end
		end
	end
end
for i = 1, #river - 1, 2 do
	local a, b = river[i], river[i + 1]
	local direction = flat(b - a).Unit
	local right = Vector3.new(-direction.Z, 0, direction.X)
	for side = -1, 1, 2 do
		grassAt(a + right * side * random:NextNumber(water.Width / 2 + 3, water.Width / 2 + 9), F.EdgeGrass.Scale)
	end
end
for _, spot in flatTrees do
	for _ = 1, 3 do
		local angle = random:NextNumber(0, math.pi * 2)
		grassAt(spot + Vector3.new(math.cos(angle), 0, math.sin(angle)) * random:NextNumber(3, 6), F.Grass.Scale)
	end
end
scatter({ Count = F.Grass.Count, Folder = "Grass", Scale = F.Grass.Scale, Margin = 0.5, Spot = function()
	return ring(95, SC.HillRadius[2] - 20)
end, Prefix = function()
	return pick(grassVariants)
end })
scatter({ Count = math.floor(F.Flowers.Count / 4), Folder = "Grass", Scale = F.Flowers.Scale, Margin = 1, Spot = function()
	return ring(95, flatRadius)
end, Prefix = function()
	return pick(flowerVariants)
end, After = function(model)
	local origin = model:GetPivot().Position
	local kind = model.Name
	for _ = 1, 3 do
		local spot = origin + Vector3.new(random:NextNumber(-4, 4), 0, random:NextNumber(-4, 4))
		if not blocked(spot, 0) then
			place(kind, CFrame.new(spot) * yaw(), random:NextNumber(F.Flowers.Scale[1], F.Flowers.Scale[2]), grassFolder)
		end
	end
end })

local spawn = world:FindFirstChild(W.Spawn)
local boards = spawn and spawn:FindFirstChild("Leaderboards")
for _, board in boards and boards:GetChildren() or {} do
	if board.Name == "Post" or board.Name == "Frame" then
		board:Destroy()
	end
end
for _, board in boards and boards:GetChildren() or {} do
	if board:IsA("BasePart") then
		local frame = place("Board", CFrame.new(board.Position.X, 0, board.Position.Z) * board.CFrame.Rotation, 1, boards)
		if frame then
			frame.Name = "Frame"
		end
	end
end

local displays = world:FindFirstChild("EggDisplays")
for _, stand in displays and displays:GetChildren() or {} do
	local pedestal = stand:FindFirstChild("Pedestal")
	if pedestal and pedestal:IsA("BasePart") then
		local position = pedestal.Position
		pedestal:Destroy()
		place("Pedestal", CFrame.new(position.X, 0, position.Z) * yaw(), 1, stand)
	end
end

local arch = place("Arch", CFrame.lookAt(SC.Arch.Position, SC.Arch.Face), 1, folder("Arch"))
local sign = arch and arch:FindFirstChild("Arch_Sign")
if sign then
	local gui = make("SurfaceGui", { Name = "Gui", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 24, LightInfluence = 0.2, Parent = sign })
	local label = make("TextLabel", { Name = "Title", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, Text = SC.Arch.Title, TextColor3 = Color3.fromRGB(120, 72, 40), Parent = gui })
	make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(255, 240, 200), Parent = label })
end

local falls = SC.Falls
local fallFx = make("Folder", { Name = "FallFx", Parent = folder("Waterfall") })
local function emitterPart(name, position, size)
	return make("Part", { Name = name, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = size, CFrame = CFrame.new(position), Parent = fallFx })
end
local function puff(parent, props)
	local base = {
		Texture = falls.Splash,
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
		FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		Color = ColorSequence.new(Color3.fromRGB(240, 252, 255)),
		LightEmission = 0.25,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-40, 40),
		Shape = Enum.ParticleEmitterShape.Box,
		Parent = parent,
	}
	for key, value in props do
		base[key] = value
	end
	return make("ParticleEmitter", base)
end
local pool = SC.River.Pool.Center
local poolDirection = flat(falls.Lip - pool).Unit
local impact = flat(pool) + poolDirection * 32 + Vector3.new(0, 1.5, 0)
local splash = emitterPart("Splash", impact, Vector3.new(18, 1, 6))
puff(splash, { Rate = 30, Lifetime = NumberRange.new(0.7, 1.1), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(50, 50), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -10, 0), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 6) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }) })
puff(splash, { Name = "Mist", Rate = 10, Lifetime = NumberRange.new(2.5, 3.5), Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 22) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }) })
for _, def in { { falls.Lip, 14 }, { falls.Ledge, 20 } } do
	local lip = emitterPart("Lip", def[1] - poolDirection * 2, Vector3.new(def[2], 1, 2))
	lip.CFrame = CFrame.lookAt(lip.Position, lip.Position - poolDirection)
	puff(lip, { Name = "Fall", Rate = 22, Lifetime = NumberRange.new(1.4, 1.8), Speed = NumberRange.new(2, 4), EmissionDirection = Enum.NormalId.Front, Acceleration = Vector3.new(0, -38, 0), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 4) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.8, 0.4), NumberSequenceKeypoint.new(1, 1) }) })
end

local L = SC.Lighting
Lighting.ClockTime = L.ClockTime
Lighting.GeographicLatitude = L.GeographicLatitude
Lighting.Brightness = L.Brightness
Lighting.ExposureCompensation = L.ExposureCompensation
Lighting.Ambient = L.Ambient
Lighting.OutdoorAmbient = L.OutdoorAmbient
Lighting.ColorShift_Top = L.ColorShiftTop
Lighting.ColorShift_Bottom = L.ColorShiftBottom
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.ShadowSoftness = L.ShadowSoftness
pcall(function()
	Lighting.Technology = Enum.Technology.Future
end)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or make("Atmosphere", { Parent = Lighting })
atmosphere.Density = L.AtmosphereDensity
atmosphere.Offset = L.AtmosphereOffset
atmosphere.Color = L.AtmosphereColor
atmosphere.Decay = L.AtmosphereDecay
atmosphere.Glare = L.AtmosphereGlare
atmosphere.Haze = L.AtmosphereHaze
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
local depth = Lighting:FindFirstChild("SceneryDepth") or make("DepthOfFieldEffect", { Name = "SceneryDepth", Parent = Lighting })
depth.Enabled = true
depth.FarIntensity = L.DepthFar
depth.NearIntensity = 0
depth.FocusDistance = L.DepthFocus
depth.InFocusRadius = L.DepthRadius
local clouds = terrain:FindFirstChildOfClass("Clouds") or make("Clouds", { Parent = terrain })
clouds.Cover = L.CloudCover
clouds.Density = L.CloudDensity
clouds.Color = Color3.new(1, 1, 1)

local count = 0
for _, descendant in scenery:GetDescendants() do
	if descendant:IsA("BasePart") then
		count += 1
	end
end
print(("Scenery built: parts=%d flatTrees=%d slopeTrees=%d"):format(count, #flatTrees, #slopeTrees))
