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
local source = imported:FindFirstChild(SC.Source)
if not source then
	print("Scenery skipped: kit missing")
	return
end
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
	return (prefix:gsub("%u$", ""))
end

local function style(part, role, solid)
	local def = SC.Roles[role] or SC.Roles.Grass
	for _, child in part:GetChildren() do
		child:Destroy()
	end
	part.Anchored = true
	part.TextureID = ""
	part.PivotOffset = CFrame.identity
	part.Color = pick(def.Colors)
	part.Material = def.Material or Enum.Material.SmoothPlastic
	part.Transparency = def.Transparency or 0
	part.Reflectance = def.Reflectance or 0
	part.CanCollide = solid
	part.CanQuery = solid or def.Transparency ~= nil
	part.CanTouch = false
	part.CastShadow = part.Size.Magnitude > 6
end

local groups = {}
for _, part in source:GetDescendants() do
	if part:IsA("MeshPart") then
		local prefix, role = part.Name:match("^(.-)_(%a+)$")
		if prefix then
			groups[prefix] = groups[prefix] or {}
			table.insert(groups[prefix], { Part = part, Role = role })
		end
	end
end

local templates = {}
for prefix, entries in groups do
	if not prefix:find("^World") then
		local model = Instance.new("Model")
		model.Name = prefix
		local collideRole = SC.Collide[baseName(prefix)]
		for _, entry in entries do
			local part = entry.Part:Clone()
			style(part, entry.Role, collideRole == entry.Role)
			part:SetAttribute("Role", entry.Role)
			part.Parent = model
		end
		local box, size = model:GetBoundingBox()
		model.WorldPivot = CFrame.new(box.Position.X, box.Position.Y - size.Y / 2, box.Position.Z)
		templates[prefix] = model
	end
end

local function place(prefix, cframe, scale, parent)
	local template = templates[prefix]
	if not template then
		return nil
	end
	local model = template:Clone()
	for _, part in model:GetChildren() do
		local def = SC.Roles[part:GetAttribute("Role")]
		if def then
			part.Color = pick(def.Colors)
		end
	end
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cframe)
	model.Parent = parent
	return model
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

local anchor = groups.World_Anchor and groups.World_Anchor[1].Part
local offset = anchor and -anchor.Position or Vector3.zero
for prefix, entries in groups do
	if prefix:find("^World") and not prefix:find("^World_Anchor") then
		for _, entry in entries do
			local part = entry.Part:Clone()
			local solid = entry.Role == "Rock"
			style(part, entry.Role, solid)
			if prefix == "World_Foam" then
				part.Color = Color3.fromRGB(235, 248, 255)
				part.Material = Enum.Material.SmoothPlastic
			elseif prefix == "World_Waterfall" then
				part.Color = Color3.fromRGB(150, 210, 245)
				part.Transparency = 0.2
			end
			part.CanQuery = true
			part.CFrame = part.CFrame + offset
			part.Parent = folder("Water")
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
local occupied = {}
local function occupiedNear(p, radius)
	for _, entry in occupied do
		if (flat(entry.P) - flat(p)).Magnitude < radius + entry.R then
			return true
		end
	end
	return false
end

local function blocked(p, margin)
	local flatP = flat(p)
	if flatP.Magnitude > SC.Radius then
		return true
	end
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
	if polylineDistance(p, river) < SC.River.Clearance + margin then
		return true
	end
	if (flatP - flat(SC.River.Pond.Center)).Magnitude < SC.River.Pond.Radius + margin then
		return true
	end
	for _, lookout in SC.Lookouts do
		if (flatP - flat(lookout.Center)).Magnitude < lookout.Radius + margin then
			return true
		end
	end
	return false
end

local function randomSpot(minRadius, maxRadius)
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

local cliffs = variants("Cliff")
local center = Vector3.zero
for index = 1, SC.Cliffs.Count do
	local angle = index / SC.Cliffs.Count * math.pi * 2 + random:NextNumber(-0.02, 0.02)
	local radius = SC.Cliffs.Radius + random:NextNumber(-SC.Cliffs.Jitter, SC.Cliffs.Jitter)
	local position = Vector3.new(math.cos(angle) * radius, -2, math.sin(angle) * radius)
	local scale = random:NextNumber(SC.Cliffs.Scale[1], SC.Cliffs.Scale[2])
	place(pick(cliffs), CFrame.lookAt(position, Vector3.new(center.X, position.Y, center.Z)) * CFrame.Angles(0, random:NextNumber(-0.15, 0.15), 0), scale, folder("Cliffs"))
end
local fall = SC.River.Waterfall
local fallDirection = flat(SC.River.Points[1] - fall).Unit
place("CliffB", CFrame.lookAt(fall - fallDirection * 16 + Vector3.new(0, -2, 0), fall + fallDirection * 10 + Vector3.new(0, -2, 0)), 1.1, folder("Cliffs"))
for side = -1, 1, 2 do
	local sideways = Vector3.new(-fallDirection.Z, 0, fallDirection.X) * side * 34
	place(pick(cliffs), CFrame.lookAt(fall + sideways - fallDirection * 6 + Vector3.new(0, -2, 0), fall + sideways + fallDirection * 10 + Vector3.new(0, -2, 0)), 1.2, folder("Cliffs"))
end

local hills = variants("Hill")
for index = 1, SC.Hills.Count do
	local angle = index / SC.Hills.Count * math.pi * 2 + random:NextNumber(-0.1, 0.1)
	local radius = random:NextNumber(SC.Hills.Radius[1], SC.Hills.Radius[2])
	local position = Vector3.new(math.cos(angle) * radius, -3, math.sin(angle) * radius)
	if not blocked(position, 20) then
		place(pick(hills), CFrame.new(position) * yaw(), random:NextNumber(SC.Hills.Scale[1], SC.Hills.Scale[2]), folder("Hills"))
	end
end

local pathFolder = folder("Paths")
local flags = variants("Flag")
for _, path in SC.Paths do
	if not path.Hidden then
		for i = 1, #path.Points - 1 do
			local a, b = path.Points[i], path.Points[i + 1]
			local length = (b - a).Magnitude
			local mid = (a + b) / 2
			studded({
				Name = "Path",
				Size = Vector3.new(path.Width, 0.4, length + path.Width * 0.5),
				CFrame = CFrame.lookAt(mid, b) + Vector3.new(0, SC.PathLift - 0.2 + (i % 2) * 0.02, 0),
				Color = SC.PathColor,
				Parent = pathFolder,
			})
			local direction = (b - a).Unit
			local right = Vector3.new(-direction.Z, 0, direction.X)
			for step = 0, math.floor(length / SC.FlagSpacing) do
				local along = a + direction * step * SC.FlagSpacing + right * random:NextNumber(-path.Width / 2 + 2, path.Width / 2 - 2)
				place(pick(flags), CFrame.new(along + Vector3.new(0, SC.PathLift - 0.05, 0)) * yaw(), random:NextNumber(0.8, 1.25), pathFolder)
			end
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
	local frame = CFrame.fromMatrix(bridge.Position, along, Vector3.yAxis)
	place("Bridge", frame, 1, folder("Bridges"))
	for side = -1, 1, 2 do
		local riverDir = Vector3.new(-along.Z, 0, along.X)
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

local trees = {}
local roundTrees = variants("Tree")
local pines = variants("Pine")
local placedTrees = 0
for _ = 1, SC.Trees.Count * 8 do
	if placedTrees >= SC.Trees.Count then
		break
	end
	local spot = randomSpot(150, SC.Radius - 15)
	local cluster = math.noise(spot.X * SC.Trees.Cluster, spot.Z * SC.Trees.Cluster, 3.7)
	if cluster > -0.15 and not blocked(spot, 6) and not occupiedNear(spot, 9) then
		local isPine = random:NextNumber() < SC.Trees.Pines + (spot.Magnitude > 430 and 0.3 or 0)
		local model = place(pick(isPine and pines or roundTrees), CFrame.new(spot + Vector3.new(0, -0.3, 0)) * yaw(), random:NextNumber(SC.Trees.Scale[1], SC.Trees.Scale[2]), folder("Trees"))
		if model then
			table.insert(occupied, { P = spot, R = 7 })
			table.insert(trees, spot)
			placedTrees += 1
		end
	end
end

local rocks = variants("Rock")
local placedRocks = 0
for _ = 1, SC.Rocks.Count * 8 do
	if placedRocks >= SC.Rocks.Count then
		break
	end
	local spot = randomSpot(150, SC.Radius - 10)
	if not blocked(spot, 4) and not occupiedNear(spot, 5) then
		place(pick(rocks), CFrame.new(spot + Vector3.new(0, -0.6, 0)) * yaw(), random:NextNumber(SC.Rocks.Scale[1], SC.Rocks.Scale[2]), folder("Rocks"))
		table.insert(occupied, { P = spot, R = 4 })
		placedRocks += 1
	end
end

local bushes = variants("Bush")
local placedBushes = 0
for _ = 1, SC.Bushes.Count * 8 do
	if placedBushes >= SC.Bushes.Count then
		break
	end
	local spot
	if #trees > 0 and random:NextNumber() < 0.6 then
		local angle = random:NextNumber(0, math.pi * 2)
		spot = pick(trees) + Vector3.new(math.cos(angle), 0, math.sin(angle)) * random:NextNumber(8, 14)
	else
		spot = randomSpot(150, SC.Radius - 10)
	end
	if not blocked(spot, 3) and not occupiedNear(spot, 3) then
		place(pick(bushes), CFrame.new(spot + Vector3.new(0, -0.4, 0)) * yaw(), random:NextNumber(SC.Bushes.Scale[1], SC.Bushes.Scale[2]), folder("Bushes"))
		table.insert(occupied, { P = spot, R = 3 })
		placedBushes += 1
	end
end

local flowers = variants("Flower")
local small = folder("Grass")
local placedTufts, placedFlowers = 0, 0
for _ = 1, (SC.Tufts.Count + SC.Flowers.Count) * 6 do
	if placedTufts >= SC.Tufts.Count and placedFlowers >= SC.Flowers.Count then
		break
	end
	local spot = randomSpot(95, SC.Radius - 10)
	if not blocked(spot, 1) then
		if placedFlowers < SC.Flowers.Count and random:NextNumber() < 0.35 then
			local model = place(pick(flowers), CFrame.new(spot) * yaw(), random:NextNumber(SC.Flowers.Scale[1], SC.Flowers.Scale[2]), small)
			if model then
				local petal = pick(SC.Roles.Petal.Colors)
				for _, part in model:GetChildren() do
					part.CastShadow = false
					if part:GetAttribute("Role") == "Petal" then
						part.Color = petal
					end
				end
				placedFlowers += 1
			end
		elseif placedTufts < SC.Tufts.Count then
			local model = place("Tuft", CFrame.new(spot) * yaw(), random:NextNumber(SC.Tufts.Scale[1], SC.Tufts.Scale[2]), small)
			if model then
				for _, part in model:GetChildren() do
					part.CastShadow = false
				end
				placedTufts += 1
			end
		end
	end
end

local spawn = world:FindFirstChild(W.Spawn)
local boards = spawn and spawn:FindFirstChild("Leaderboards")
for _, board in boards and boards:GetChildren() or {} do
	if board.Name == "Post" then
		board:Destroy()
	end
end
for _, board in boards and boards:GetChildren() or {} do
	if board:IsA("BasePart") then
		place("Board", CFrame.new(board.Position.X, 0, board.Position.Z) * board.CFrame.Rotation, 1, boards)
	end
end

local displays = world:FindFirstChild("EggDisplays")
for _, stand in displays and displays:GetChildren() or {} do
	local pedestal = stand:FindFirstChild("Pedestal")
	if pedestal then
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

print(("Scenery built: trees=%d rocks=%d bushes=%d tufts=%d flowers=%d"):format(placedTrees, placedRocks, placedBushes, placedTufts, placedFlowers))
