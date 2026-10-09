local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local MapConfig = require(Shared.Config.Map)
local EffectsConfig = require(Shared.Config.Effects)
local PropsConfig = require(Shared.Config.Props)
local Trails = require(Shared.Config.Trails)

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

local function studTexture(part)
	make("Texture", { Name = "Studs", Texture = SC.Hills.Studs, Face = Enum.NormalId.Top, StudsPerTileU = SC.Hills.StudsPerTile, StudsPerTileV = SC.Hills.StudsPerTile, Transparency = SC.Hills.StudsTransparency, Parent = part })
end

local function pick(list)
	return list[random:NextInteger(1, #list)]
end

local function baseName(prefix)
	return (prefix:gsub("%d+$", ""):gsub("%u$", ""))
end

local function roleDef(prefix, role)
	local kit = SC.KitRoles[baseName(prefix)]
	return kit and kit[role] or SC.Roles[baseName(prefix) .. role] or SC.Roles[role] or SC.Roles.Grass
end

local function solidFor(prefix, role)
	local rule = SC.Collide[baseName(prefix)]
	return rule ~= nil and rule[role] == true
end

local function style(part, prefix, role)
	local def = roleDef(prefix, role)
	for _, child in part:GetChildren() do
		if not (def.KeepTexture and (child:IsA("SurfaceAppearance") or child:IsA("Bone"))) then
			child:Destroy()
		end
	end
	local solid = solidFor(prefix, role)
	part.Anchored = true
	if not def.KeepTexture then
		part.TextureID = ""
	end
	if def.Tag then
		CollectionService:AddTag(part, def.Tag)
	end
	part.PivotOffset = CFrame.identity
	part.Color = pick(def.Colors)
	part.Material = def.Material or Enum.Material.SmoothPlastic
	part.Transparency = def.Transparency or 0
	part.Reflectance = def.Reflectance or 0
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
		for prefix in found do
			if prefix:find("^World_") then
				local family = (prefix:gsub("%d+$", ""))
				for existing in groups do
					if (existing:gsub("%d+$", "")) == family and not found[existing] then
						groups[existing] = nil
					end
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
			part.Name = entry.Role
			part.Parent = model
		end
		local origin = SC.KitOrigins[prefix]
		if origin then
			model.WorldPivot = CFrame.new(-group.Offset + origin)
		else
			local box, size = model:GetBoundingBox()
			model.WorldPivot = CFrame.new(box.Position.X, box.Position.Y - size.Y / 2, box.Position.Z)
		end
		templates[prefix] = model
	end
end

local function fitTo(prefix, target, scale, parent)
	local template = templates[prefix]
	if not template then
		return nil
	end
	local model = template:Clone()
	local pivot = model:GetPivot()
	for _, part in model:GetChildren() do
		local rel = pivot:ToObjectSpace(part.CFrame)
		part.Size = part.Size * scale
		part.CFrame = target * CFrame.new(rel.Position * scale) * rel.Rotation
		part.Color = pick(roleDef(prefix, part:GetAttribute("Role")).Colors)
	end
	model.WorldPivot = target
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
	if prefix:find("^World") and not SC.SkipWorld[prefix] then
		for _, entry in group.Entries do
			do
				local part = entry.Part:Clone()
				style(part, prefix, entry.Role)
				part.CFrame = part.CFrame + group.Offset
				if prefix:find("^World_Hills") then
					part.Color = SC.Hills.Color
					part.CastShadow = true
					pcall(function()
						part.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
					end)
					studTexture(part)
					part.Parent = folder("Hills")
					table.insert(hillParts, part)
				elseif prefix:find("^World_Path") then
					part.CastShadow = false
					part.Parent = folder("PathStones")
				elseif prefix:find("^World_Trail") then
					part.CFrame = part.CFrame + Vector3.new(0, SC.TrailLift[prefix] or 0, 0)
					part.CastShadow = false
					part.CanCollide = false
					part.CanQuery = false
					studTexture(part)
					part.Parent = folder("Paths")
				elseif SC.KitFolders[baseName(prefix)] then
					local family = (prefix:gsub("%d+$", ""))
					if SC.KitTags[family] then
						part.CastShadow = false
						part.CanQuery = false
						part:SetAttribute("Phase", tonumber(prefix:match("%d+$")) or 0)
						CollectionService:AddTag(part, SC.KitTags[family])
					end
					part.Parent = folder(SC.KitFolders[baseName(prefix)])
				elseif prefix:find("^World_Falls") then
					part.Parent = folder("Waterfall")
				else
					part.CanQuery = false
					part.CastShadow = entry.Role ~= "Surface"
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

local function trailDistance(p)
	local best = math.huge
	for _, trail in Trails do
		for i = 1, #trail - 1 do
			local a, b = trail[i], trail[i + 1]
			local ax, az, bx, bz = a[1], a[2], b[1], b[2]
			local dx, dz = bx - ax, bz - az
			local length = dx * dx + dz * dz
			local t = length > 0 and math.clamp(((p.X - ax) * dx + (p.Z - az) * dz) / length, 0, 1) or 0
			local distance = math.sqrt((ax + dx * t - p.X) ^ 2 + (az + dz * t - p.Z) ^ 2) - (a[3] + (b[3] - a[3]) * t)
			if distance < best then
				best = distance
			end
		end
	end
	return best
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
	if SC.OrganicTrails then
		if trailDistance(p) < margin + 1 then
			return true
		end
	else
		for _, path in SC.Paths do
			if polylineDistance(p, path.Points) < path.Width / 2 + margin then
				return true
			end
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
	for _, npc in PropsConfig.NPCs do
		if (flatP - flat(npc.Position)).Magnitude < SC.NPCClearance + margin then
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
local slabIndex = 0
local function slab(top, level)
	local thickness = SC.SlabThickness[level]
	return thickness, top - thickness / 2
end
local function inPlazaRect(spot, margin)
	for _, plaza in SC.Plazas do
		if spot.X > plaza.Min.X - margin and spot.X < plaza.Max.X + margin and spot.Z > plaza.Min.Z - margin and spot.Z < plaza.Max.Z + margin then
			return true
		end
	end
	return false
end
local function trailEdges(spacing, callback)
	for _, trail in Trails do
		local carried = 0
		for i = 1, #trail - 1 do
			local a, b = trail[i], trail[i + 1]
			local pa, pb = Vector3.new(a[1], 0, a[2]), Vector3.new(b[1], 0, b[2])
			local length = (pb - pa).Magnitude
			if length > 0 then
				local direction = (pb - pa) / length
				local right = Vector3.new(-direction.Z, 0, direction.X)
				local along = spacing - carried
				while along <= length do
					local t = along / length
					callback(pa + direction * along, direction, right, a[3] + (b[3] - a[3]) * t)
					along += spacing
				end
				carried = length - (along - spacing)
			end
		end
	end
end
if SC.OrganicTrails then
	local lampSide = 1
	trailEdges(SC.LampSpacing, function(center, direction, right, halfWidth)
		lampSide = -lampSide
		local spot = center + right * lampSide * (halfWidth + SC.LampOffset)
		if not inPlazaRect(spot, 4) and trailDistance(spot) > 2 and not nearWater(spot, 2) then
			place("Lamp", CFrame.lookAt(spot, spot - right * lampSide), 1, folder("Lamps"))
		end
	end)
end
for _, path in SC.OrganicTrails and {} or SC.Paths do
	if not path.Hidden then
		for i = 1, #path.Points - 1 do
			local a, b = path.Points[i], path.Points[i + 1]
			local length = (b - a).Magnitude
			local mid = (a + b) / 2
			local level = slabIndex % #SC.PathTops + 1
			slabIndex += 1
			local thickness, center = slab(SC.PathTops[level], level)
			studded({
				Name = "Path",
				Size = Vector3.new(path.Width + 0.8 + level * 0.2, thickness, length + path.Width * 0.5),
				CFrame = CFrame.lookAt(mid, b) + Vector3.new(0, center, 0),
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

for _, plaza in SC.OrganicTrails and {} or SC.Plazas do
	local size = plaza.Max - plaza.Min
	studded({
		Name = plaza.Name,
		Size = Vector3.new(size.X, SC.SlabThickness[#SC.SlabThickness], size.Z),
		CFrame = CFrame.new((plaza.Min + plaza.Max) / 2 + Vector3.new(0, SC.PlazaTop - SC.SlabThickness[#SC.SlabThickness] / 2, 0)),
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
	if not SC.OrganicTrails then
		studded({
			Name = "Lookout",
			Size = Vector3.new(lookout.Radius * 1.6, SC.SlabThickness[#SC.SlabThickness], lookout.Radius * 1.6),
			CFrame = CFrame.lookAt(lookout.Center, Vector3.new(lookout.Face.X, 0, lookout.Face.Z)) + Vector3.new(0, SC.PlazaTop - SC.SlabThickness[#SC.SlabThickness] / 2, 0),
			Color = SC.PathColor,
			Parent = pathFolder,
		})
	end
	local toward = flat(lookout.Face - lookout.Center).Unit
	local right = Vector3.new(-toward.Z, 0, toward.X)
	for k = -1, 1 do
		local spot = lookout.Center + toward * 6 + right * k * 9
		place("ParkBench", CFrame.lookAt(spot, spot + toward) * CFrame.Angles(0, math.pi, 0), 1, folder("Benches"))
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
local function inWater(spot)
	if polylineDistance(spot, river) < water.Width / 2 + water.GrassGap then
		return true
	end
	return (flat(spot) - flat(SC.River.Pond.Center)).Magnitude < water.PondRadius + water.GrassGap or (flat(spot) - flat(SC.River.Pool.Center)).Magnitude < SC.River.Pool.Radius + water.GrassGap
end
local function grassAt(spot, scaleRange)
	if inWater(spot) then
		return nil
	end
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
if SC.OrganicTrails then
	trailEdges(F.EdgeGrass.Spacing, function(center, direction, right, halfWidth)
		for side = -1, 1, 2 do
			local spot = center + direction * random:NextNumber(-1, 1) + right * side * (halfWidth + random:NextNumber(0.9, 2.6))
			if not inPlaza(spot) and not inPlazaRect(spot, 1) and trailDistance(spot) > 0.6 and not nearWater(spot, -4) then
				grassAt(spot, F.EdgeGrass.Scale)
			end
		end
	end)
end
for _, path in SC.OrganicTrails and {} or SC.Paths do
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

local decor = SC.Decor
local decorKit = imported:FindFirstChild(decor.Source)
local function decorPart(name)
	local template = decorKit and decorKit:FindFirstChild(name, true)
	if not template then
		return nil
	end
	local part = template:Clone()
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end
local function swayModel(name, parts, pivot, amount, parent)
	local model = make("Model", { Name = name })
	for _, part in parts do
		part.Parent = model
	end
	model.WorldPivot = pivot
	model:SetAttribute("Sway", amount)
	CollectionService:AddTag(model, "Sway")
	model.Parent = parent
	return model
end

local displays = world:FindFirstChild("EggDisplays")
for _, stand in displays and displays:GetChildren() or {} do
	local pedestal = stand:FindFirstChild("Pedestal")
	if pedestal and pedestal:IsA("BasePart") then
		local position = pedestal.Position
		pedestal:Destroy()
		local podium = place("Pedestal", CFrame.new(position.X, 0, position.Z) * yaw(), 1, stand)
		if podium then
			local box, size = podium:GetBoundingBox()
			local top = box.Position.Y + size.Y / 2 - decor.Vines.Drop
			local radius = math.min(size.X, size.Z) / 2 - decor.Vines.Inset
			local start = random:NextNumber(0, math.pi * 2)
			for index = 1, decor.Vines.Count do
				local vine = decorPart(decor.Vines.Part)
				if vine then
					local angle = start + (index - 1) * math.pi * 2 / decor.Vines.Count + random:NextNumber(-0.3, 0.3)
					local hinge = CFrame.new(position.X + math.cos(angle) * radius, top, position.Z + math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
					vine.CFrame = hinge * CFrame.new(vine.Size.X / 2 + decor.Vines.Offset, -vine.Size.Y / 2, 0)
					swayModel("Vine", { vine }, hinge, decor.Vines.Sway, stand)
				end
			end
		end
	end
end

local quarryRope
for _, part in folder("QuarryKit"):GetChildren() do
	if part:GetAttribute("Role") == "Rope" then
		quarryRope = part
	end
end
local bucket = quarryRope and decorPart(decor.Bucket.Part)
if bucket then
	local ropeTop = quarryRope.Position + Vector3.new(0, quarryRope.Size.Y / 2, 0)
	local ropeBottom = quarryRope.Position - Vector3.new(0, quarryRope.Size.Y / 2, 0)
	bucket.CFrame = CFrame.new(ropeBottom - Vector3.new(0, bucket.Size.Y / 2, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
	quarryRope.CanCollide = false
	swayModel("SwingBucket", { quarryRope, bucket }, CFrame.new(ropeTop), decor.Bucket.Sway, folder("QuarryKit")):SetAttribute("Gust", decor.Bucket.Gust)
	local ropeAxis = Vector3.new(ropeTop.X, 0, ropeTop.Z)
	for _, part in folder("QuarryKit"):GetChildren() do
		if part:IsA("BasePart") and (Vector3.new(part.Position.X, 0, part.Position.Z) - ropeAxis).Magnitude < decor.Bucket.Clear and math.max(part.Size.X, part.Size.Z) < decor.Bucket.Clear * 2 then
			part:Destroy()
		end
	end
end

for _, gym in world:FindFirstChild(W.Gyms) and world[W.Gyms]:GetChildren() or {} do
	local platform = gym:FindFirstChild("Platform")
	local pavilion = platform and platform.Size.Y <= decor.Pavilion.MaxPlatformHeight and decorPart(decor.Pavilion.Part)
	if pavilion then
		local look = platform.CFrame.LookVector * Vector3.new(1, 0, 1)
		look = look.Magnitude > 0 and look.Unit or Vector3.new(0, 0, -1)
		local center = Vector3.new(platform.Position.X, 0, platform.Position.Z) - look * (platform.Size.Z / 2 + decor.Pavilion.Gap + pavilion.Size.Z / 2) + Vector3.new(0, pavilion.Size.Y / 2, 0)
		pavilion.CFrame = CFrame.lookAt(center, center + look)
		pavilion.CanCollide = true
		pavilion.CastShadow = true
		pavilion.Name = gym.Name .. "Pavilion"
		pavilion.Parent = folder(decor.Pavilion.Folder)
	end
end

local arch = place("Arch", CFrame.lookAt(SC.Arch.Position, SC.Arch.Face), 1, folder("Arch"))
local sign = arch and arch:FindFirstChild("Arch_Sign")
if sign then
	local gui = make("SurfaceGui", { Name = "Gui", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 24, LightInfluence = 0.2, Parent = sign })
	local label = make("TextLabel", { Name = "Title", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, Text = SC.Arch.Title, TextColor3 = Color3.fromRGB(120, 72, 40), Parent = gui })
	make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(255, 240, 200), Parent = label })
end

local settleParams = RaycastParams.new()
settleParams.FilterType = Enum.RaycastFilterType.Include
local settleTargets = table.clone(hillParts)
table.insert(settleTargets, world:FindFirstChild("Ground"))
settleParams.FilterDescendantsInstances = settleTargets
local function settle(model, sink, ratio)
	local pivot = model:GetPivot()
	local _, size = model:GetBoundingBox()
	sink += size.Y * (ratio or 0)
	local reach = math.min(size.X, size.Z) * (model:GetAttribute("SwayLeaves") and 0.12 or 0.4)
	local lowest = math.huge
	for _, offset in { Vector3.zero, Vector3.new(reach, 0, 0), Vector3.new(-reach, 0, 0), Vector3.new(0, 0, reach), Vector3.new(0, 0, -reach) } do
		local hit = Workspace:Raycast(pivot.Position + offset + Vector3.new(0, 80, 0), Vector3.new(0, -200, 0), settleParams)
		if hit then
			lowest = math.min(lowest, hit.Position.Y)
		end
	end
	if lowest < math.huge then
		local delta = lowest - sink - pivot.Position.Y
		model:PivotTo(pivot + Vector3.new(0, delta, 0))
	end
end
for folderName, sink in SC.Settle do
	for _, model in folders[folderName] and folders[folderName]:GetChildren() or {} do
		if model:IsA("Model") then
			settle(model, sink, SC.SettleRatio[folderName])
		end
	end
end

local gymsFolder = world:FindFirstChild(W.Gyms)
for _, gym in gymsFolder and gymsFolder:GetChildren() or {} do
	local tierColor = MapConfig.TierColors[gym.Name] or Color3.new(1, 1, 1)
	for _, child in gym:GetChildren() do
		if child.Name == "Border" or child.Name == "KitPlatform" then
			child:Destroy()
		end
	end
	local platform = gym:FindFirstChild("Platform")
	if platform then
		local top = platform.CFrame * CFrame.new(0, platform.Size.Y / 2, 0)
		local kit = fitTo("GymPlatform", top * CFrame.new(0, 0.06 - SC.GymFloorLift + 2.2, 0), Vector3.new(platform.Size.X / 44, 1, platform.Size.Z / 34), gym)
		if kit then
			kit.Name = "KitPlatform"
			for _, part in kit:GetChildren() do
				if part.Name == "Trim" then
					part.Color = tierColor
				elseif part.Name == "Floor" then
					studTexture(part)
				end
			end
			platform.Transparency = platform.Size.Y > 3 and 0 or 1
			platform.Color = Color3.fromRGB(150, 150, 160)
		end
	end
	for _, machine in gym:GetChildren() do
		local pad = machine:IsA("Model") and machine:FindFirstChild(W.Pad)
		local visual = pad and machine:FindFirstChild("Visual")
		if visual then
			for _, part in visual:GetChildren() do
				if part:IsA("BasePart") and not part:IsA("Seat") then
					part:Destroy()
				end
			end
			for _, old in machine:GetChildren() do
				if old.Name == "KitMachine" then
					old:Destroy()
				end
			end
			local floor = pad.CFrame * CFrame.new(0, -pad.Size.Y / 2, 0)
			local kitPlatform = gym:FindFirstChild("KitPlatform")
			local floorPart = kitPlatform and kitPlatform:FindFirstChild("Floor")
			if floorPart then
				floor = floor + Vector3.new(0, floorPart.Position.Y + floorPart.Size.Y / 2 - floor.Position.Y, 0)
			end
			local kit = fitTo(machine.Name == "Treadmill" and "Treadmill" or "Bench", floor, Vector3.one, machine)
			if kit then
				kit.Name = "KitMachine"
				machine.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
				local tint = SC.MachineTints[gym.Name]
				for _, part in kit:GetChildren() do
					if part.Name == "Trim" then
						part.Color = tierColor
					end
					if tint and part:IsA("MeshPart") and part.TextureID ~= "" then
						make("SurfaceAppearance", { Name = "Tint", ColorMap = part.TextureID, Color = tint, Parent = part })
					end
				end
				local belt = kit:FindFirstChild("Belt")
				if belt then
					local ribs = SC.BeltRibs
					local top = belt.CFrame * CFrame.new(0, belt.Size.Y / 2 + ribs.Lift, 0)
					for index = 1, ribs.Count do
						make("Part", {
							Name = "BeltRib",
							Anchored = true,
							CanCollide = false,
							CanQuery = false,
							CanTouch = false,
							CastShadow = false,
							Material = Enum.Material.SmoothPlastic,
							Color = ribs.Color,
							Size = Vector3.new(belt.Size.X * ribs.Width, ribs.Height, ribs.Depth),
							CFrame = top * CFrame.new(0, 0, (index - 0.5) / ribs.Count * belt.Size.Z * ribs.Span - belt.Size.Z * ribs.Span / 2),
							Parent = kit,
						})
					end
				end
			end
		end
	end
end

for _, area in { world:FindFirstChild(W.Gyms), world:FindFirstChild(W.Quarry), world:FindFirstChild(W.Spawn) } do
	for _, gui in area and area:GetDescendants() or {} do
		local board = gui:IsA("SurfaceGui") and gui.Parent
		if board and board:IsA("BasePart") and board.Size.Z <= 1.6 and not board:FindFirstAncestor("Leaderboards") and not board:GetAttribute("KitSign") then
			board:SetAttribute("KitSign", true)
			board.Transparency = 1
			local size = board.Size
			local scale = Vector3.new(size.X / SC.SignSize.X, size.Y / SC.SignSize.Y, size.Z * SC.SignDepth / SC.SignSize.Z)
			fitTo("SignBoard", board.CFrame * CFrame.new(0, 0, size.Z * (1 - SC.SignDepth) / 2), scale, board.Parent)
		end
	end
	for _, post in area and area:GetDescendants() or {} do
		if post:IsA("BasePart") and post.Name == "Post" and not post:FindFirstAncestor("Leaderboards") and not post:GetAttribute("KitSign") then
			post:SetAttribute("KitSign", true)
			post.Transparency = 1
			post.CanCollide = false
			local size = post.Size
			fitTo("SignPost", post.CFrame * CFrame.new(0, -size.Y / 2, 0), Vector3.new(size.X, size.Y, size.Z), post.Parent)
		end
	end
end

local quarry = world:FindFirstChild(W.Quarry)
if folders.QuarryKit and quarry then
	for _, part in quarry:GetChildren() do
		if part:IsA("BasePart") and (part.Name == "PitRock" or part.Name == "PitRamp") then
			part.Transparency = 1
		end
	end
end
local site = world:FindFirstChild(W.Site)
local nest = site and site:FindFirstChild("Nest")
if folders.Nest and nest then
	for _, child in nest:GetChildren() do
		if child:IsA("Model") then
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.Transparency = 1
		end
	end
end
local npcFolder = world:FindFirstChild(W.NPCs)
for _, station in SC.Stations do
	local npc = npcFolder and npcFolder:FindFirstChild(station.NPC)
	local root = npc and npc:FindFirstChild("HumanoidRootPart")
	if root then
		local ring = npc:FindFirstChild("Ring")
		if ring and station.HideRing then
			ring.Transparency = 1
		end
		local tag = root:FindFirstChild("Tag")
		if tag and station.TagHeight then
			tag.StudsOffset = Vector3.new(0, station.TagHeight, 0)
		end
		if station.HideBody then
			for _, descendant in npc:GetDescendants() do
				if descendant:IsA("BasePart") or descendant:IsA("Decal") then
					descendant.Transparency = 1
				end
			end
		end
		local base = npc:GetPivot()
		if station.Tilt then
			local feet = base * CFrame.new(-station.Shift, -3, -(station.Forward or 0))
			npc:PivotTo(feet * CFrame.Angles(0, 0, math.rad(station.Tilt)) * CFrame.new(0, 3, 0))
			npc:SetAttribute("Posed", true)
			for jointName, degrees in PropsConfig.PosedRig.Pose do
				local joint = npc:FindFirstChild(jointName, true)
				local rotation = CFrame.Angles(math.rad(degrees[1]), math.rad(degrees[2]), math.rad(degrees[3]))
				if joint and joint:IsA("AnimationConstraint") then
					joint.Transform = rotation
				elseif joint and joint:IsA("Motor6D") then
					joint.C0 = joint.C0 * rotation
				end
			end
		end
		if station.SignText then
			local def
			for _, entry in PropsConfig.NPCs do
				if entry.Name == station.NPC then
					def = entry
				end
			end
			local forward = flat(def.FaceTarget - def.Position).Unit
			local position = def.Position + forward * station.SignForward + Vector3.new(0, station.SignHeight, 0)
			local board = make("Part", { Name = "StationSign", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = station.SignSize, CFrame = CFrame.lookAt(position, position + forward), Parent = folder("Shop") })
			local gui = make("SurfaceGui", { Name = "Gui", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 40, LightInfluence = 0.3, Parent = board })
			local label = make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, Text = station.SignText, TextColor3 = Color3.new(1, 1, 1), Parent = gui })
			make("UIStroke", { Thickness = 3, Color = station.TextColor, Parent = label })
		end
	end
end

for _, area in { world:FindFirstChild(W.Gyms), world:FindFirstChild(W.Quarry), world:FindFirstChild(W.Spawn) } do
	for _, gui in area and area:GetDescendants() or {} do
		if gui:IsA("SurfaceGui") and gui.Face == Enum.NormalId.Front and not gui:FindFirstAncestor("Leaderboards") and not gui.Parent:FindFirstChild(gui.Name .. "Back") then
			local back = gui:Clone()
			back.Name = gui.Name .. "Back"
			back.Face = Enum.NormalId.Back
			back.Parent = gui.Parent
		end
	end
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
local WS = SC.WaterSprites
local spriteKit = imported:FindFirstChild(WS.Source)
local function sprite(key)
	local part = spriteKit and spriteKit:FindFirstChild(WS.Parts[key], true)
	if not part then
		return nil
	end
	local surface = part:FindFirstChildOfClass("SurfaceAppearance")
	local id = surface and surface.ColorMap or (part:IsA("MeshPart") and part.TextureID) or ""
	return id ~= "" and id or nil
end
local function span(pair)
	return NumberRange.new(pair[1], pair[2])
end
local function grow(pair)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, pair[1]), NumberSequenceKeypoint.new(1, pair[2]) })
end
local function fade(start)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, start), NumberSequenceKeypoint.new(0.7, math.min(start + 0.2, 1)), NumberSequenceKeypoint.new(1, 1) })
end
local splashTexture, dropTexture, mistTexture = sprite("Splash"), sprite("Droplets"), sprite("Mist")
if splashTexture then
	puff(splash, { Texture = splashTexture, FlipbookLayout = Enum.ParticleFlipbookLayout.None, LightEmission = 0.1, Rate = WS.Splash.Rate, Lifetime = span(WS.Splash.Lifetime), Speed = span(WS.Splash.Speed), SpreadAngle = Vector2.new(20, 20), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -32, 0), Size = grow(WS.Splash.Size), Transparency = fade(0.05), Rotation = NumberRange.new(-12, 12), RotSpeed = NumberRange.new(-15, 15) })
else
	puff(splash, { Rate = 30, Lifetime = NumberRange.new(0.7, 1.1), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(50, 50), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -10, 0), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 6) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }) })
end
if dropTexture then
	puff(splash, { Name = "Droplets", Texture = dropTexture, FlipbookLayout = Enum.ParticleFlipbookLayout.None, LightEmission = 0.15, Rate = WS.Droplets.Rate, Lifetime = span(WS.Droplets.Lifetime), Speed = span(WS.Droplets.Speed), SpreadAngle = Vector2.new(40, 40), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -40, 0), Size = grow(WS.Droplets.Size), Transparency = fade(0) })
end
puff(splash, { Name = "Mist", Texture = mistTexture or falls.Splash, FlipbookLayout = mistTexture and Enum.ParticleFlipbookLayout.None or Enum.ParticleFlipbookLayout.Grid4x4, Rate = WS.Mist.Rate, Lifetime = span(WS.Mist.Lifetime), Speed = span(WS.Mist.Speed), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Size = grow(WS.Mist.Size), Transparency = fade(0.55) })

local pondCenter = flat(SC.River.Pond.Center)
local riverEnd = flat(SC.River.Points[#SC.River.Points])
local inlet = pondCenter + (riverEnd - pondCenter).Unit * (water.PondRadius - WS.InletInset)
if dropTexture then
	local pondSplash = emitterPart("PondSplash", inlet + Vector3.new(0, water.Surface, 0), Vector3.new(8, 0.5, 8))
	puff(pondSplash, { Texture = dropTexture, FlipbookLayout = Enum.ParticleFlipbookLayout.None, LightEmission = 0.15, Rate = WS.Pond.Rate, Lifetime = span(WS.Pond.Lifetime), Speed = span(WS.Pond.Speed), SpreadAngle = Vector2.new(35, 35), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -20, 0), Size = grow(WS.Pond.Size), Transparency = fade(0) })
end

local spriteAnchors = { Impact = flat(impact), Pool = flat(pool), Pond = pondCenter, Inlet = inlet }
local function scatter(center, spread)
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = math.sqrt(random:NextNumber()) * spread
	return center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end
local function waterDecal(name, texture, position, size, lift)
	local holder = make("Part", { Name = name, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 1, Size = Vector3.new(size, 0.05, size), CFrame = CFrame.new(position.X, water.Surface + lift, position.Z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0), Parent = folder("WaterSprites") })
	make("Decal", { Name = "Sprite", Texture = texture, Face = Enum.NormalId.Top, Parent = holder })
	return holder
end
local rippleTexture, foamTexture = sprite("Ripple"), sprite("Foam")
for _, spot in rippleTexture and WS.Ripples or {} do
	for n = 1, spot.Count do
		local ripple = waterDecal("Ripple", rippleTexture, scatter(spriteAnchors[spot.At], spot.Spread), random:NextNumber(spot.Size[1], spot.Size[2]), WS.Lift + 0.008 * n)
		ripple:SetAttribute("Phase", random:NextNumber(0, 3))
		CollectionService:AddTag(ripple, "Ripple")
	end
end
for _, spot in foamTexture and WS.Foam or {} do
	for n = 1, spot.Count do
		local foam = waterDecal("Foam", foamTexture, scatter(spriteAnchors[spot.At], spot.Spread), random:NextNumber(spot.Size[1], spot.Size[2]), WS.Lift + 0.1 + 0.005 * n)
		foam:SetAttribute("Phase", random:NextNumber(0, math.pi * 2))
		CollectionService:AddTag(foam, "Foam")
	end
end
local waterFx = imported:FindFirstChild(falls.Fx)
local fallTemplate = waterFx and waterFx:FindFirstChild(falls.Model)
if fallTemplate then
	local flowDirection = -poolDirection
	local facing = CFrame.lookAt(Vector3.zero, flowDirection)
	local templateDrop = fallTemplate.Source.Position.Y - fallTemplate.Plunge.Position.Y
	local templateWidth = 1
	for _, beam in fallTemplate:GetChildren() do
		if beam:IsA("Beam") then
			templateWidth = math.max(templateWidth, beam.Width0, beam.Width1)
		end
	end
	local widthScale = falls.Width / templateWidth
	for _, tier in { { falls.Lip, falls.LedgeTop }, { falls.Ledge, water.Surface } } do
		local top = tier[1] + flowDirection * falls.Out
		local drop = top.Y - tier[2]
		local fall = fallTemplate:Clone()
		fall.Source.CFrame = CFrame.new(top) * facing
		fall.Plunge.CFrame = CFrame.new(Vector3.new(top.X, tier[2], top.Z) + flowDirection * falls.Reach) * facing
		fall.Source.Size = Vector3.new(falls.Width, fall.Source.Size.Y, fall.Source.Size.Z)
		fall.Plunge.Size = Vector3.new(fall.Plunge.Size.X * widthScale, fall.Plunge.Size.Y, fall.Plunge.Size.Z)
		for _, beam in fall:GetChildren() do
			if beam:IsA("Beam") then
				beam.Width0 *= widthScale
				beam.Width1 *= widthScale
				beam.CurveSize0 *= drop / templateDrop
				beam.CurveSize1 *= drop / templateDrop
			end
		end
		fall.Parent = folder("Waterfall")
	end
end

local flowTemplate = waterFx and waterFx:FindFirstChild(water.Flow)
local flowBeam = flowTemplate and flowTemplate:FindFirstChildWhichIsA("Beam", true)
if flowBeam then
	local holder = make("Part", { Name = "FlowingWater", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(), Parent = folder("Water") })
	local height = water.Surface + water.FlowLift
	local previous
	for i = 1, #river, water.FlowStride do
		local before = river[math.max(i - 1, 1)]
		local after = river[math.min(i + 1, #river)]
		local direction = flat(after - before).Unit
		local across = Vector3.new(-direction.Z, 0, direction.X)
		local position = Vector3.new(river[i].X, height, river[i].Z)
		local attachment = make("Attachment", { CFrame = CFrame.fromMatrix(position, Vector3.yAxis, across), Parent = holder })
		if previous then
			local beam = flowBeam:Clone()
			beam.Attachment0 = previous
			beam.Attachment1 = attachment
			beam.Width0 = water.Width + 2
			beam.Width1 = water.Width + 2
			beam.TextureMode = Enum.TextureMode.Wrap
			beam.TextureLength = water.FlowTextureLength
			beam.CurveSize0 = 0
			beam.CurveSize1 = 0
			beam.Segments = 4
			beam.TextureSpeed = water.FlowSpeed
			beam.ZOffset = (#holder:GetChildren() % 2) * 0.2
			beam.Parent = holder
		end
		previous = attachment
	end
end

local windPack = imported:FindFirstChild("WindPack")
local gustTemplates = {}
for _, source in windPack and windPack:GetChildren() or {} do
	if source:IsA("Model") and source.Name ~= "OriginalPack" then
		table.insert(gustTemplates, source)
	end
end
local windDirection = EffectsConfig.Wind.Direction.Unit
if #gustTemplates > 0 then
	local spots = SC.WindSpots
	for _ = 1, spots.Count do
		local spot = ring(spots.Radius[1], spots.Radius[2])
		local y = groundAt(spot)
		local gust = pick(gustTemplates):Clone()
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
		gust:ScaleTo(random:NextNumber(spots.Scale[1], spots.Scale[2]))
		local position = Vector3.new(spot.X, y + random:NextNumber(spots.Height[1], spots.Height[2]), spot.Z)
		gust:PivotTo(CFrame.lookAt(position, position + windDirection) * CFrame.Angles(0, 0, random:NextNumber(-0.5, 0.5)))
		gust.Parent = folder("Wind")
	end
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
local focusDef = EffectsConfig.Cutscene.Focus
local cutsceneFocus = Lighting:FindFirstChild("CutsceneFocus") or make("DepthOfFieldEffect", { Name = "CutsceneFocus", Parent = Lighting })
cutsceneFocus.Enabled = false
cutsceneFocus.FarIntensity = focusDef.Far
cutsceneFocus.NearIntensity = focusDef.Near
cutsceneFocus.InFocusRadius = focusDef.Radius
cutsceneFocus.FocusDistance = 20
local revealBlur = Lighting:FindFirstChild("RevealBlur") or make("BlurEffect", { Name = "RevealBlur", Parent = Lighting })
revealBlur.Enabled = false
revealBlur.Size = EffectsConfig.RevealBlur
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
