local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BASE = "http://127.0.0.1:34877/studio/models/"
local MODELS = { "Chick", "Owl", "Goose", "Dragon", "Phoenix", "EggCommon", "EggSilver", "EggGolden", "EggVoid", "EggGem" }
local THICKNESS = 0.04

local folder = ReplicatedStorage:FindFirstChild("Models")
if folder then
	folder:Destroy()
end
folder = Instance.new("Folder")
folder.Name = "Models"
folder.Parent = ReplicatedStorage

local function wedge(parent, color, neon)
	local part = Instance.new("WedgePart")
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = parent
	return part
end

local function triangle(a, b, c, parent, color, neon, weldTo)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cross = ac:Cross(ab)
	if cross.Magnitude < 1e-6 or bc.Magnitude < 1e-6 then
		return 0
	end
	local right = cross.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local shift = -right * THICKNESS / 2
	local w0 = wedge(parent, color, neon)
	w0.Size = Vector3.new(THICKNESS, math.max(height, 0.001), math.max(math.abs(ab:Dot(back)), 0.001))
	w0.CFrame = CFrame.fromMatrix((a + b) / 2 + shift, right, up, back)
	local w1 = wedge(parent, color, neon)
	w1.Size = Vector3.new(THICKNESS, math.max(height, 0.001), math.max(math.abs(ac:Dot(back)), 0.001))
	w1.CFrame = CFrame.fromMatrix((a + c) / 2 + shift, -right, up, -back)
	for _, w in { w0, w1 } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = weldTo
		weld.Part1 = w
		weld.Parent = w
	end
	return 2
end

local total = 0
for _, name in MODELS do
	local data = HttpService:JSONDecode(HttpService:GetAsync(BASE .. name .. ".json?t=" .. tostring(os.clock()), true))
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.4, 0.4, 0.4)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	local count = 0
	for groupName, tris in data.groups do
		local pivot = data.pivots[groupName]
		local groupRoot = Instance.new("Part")
		groupRoot.Name = groupName
		groupRoot.Size = Vector3.new(0.2, 0.2, 0.2)
		groupRoot.Transparency = 1
		groupRoot.Anchored = false
		groupRoot.CanCollide = false
		groupRoot.CanQuery = false
		groupRoot.CanTouch = false
		groupRoot.Massless = true
		groupRoot.CFrame = CFrame.new(pivot and Vector3.new(pivot[1], pivot[2], pivot[3]) or Vector3.zero)
		groupRoot.Parent = model
		local motor = Instance.new("Motor6D")
		motor.Name = groupName
		motor.Part0 = root
		motor.Part1 = groupRoot
		motor.C0 = root.CFrame:ToObjectSpace(groupRoot.CFrame)
		motor.C1 = CFrame.new()
		motor.Parent = root
		local parts = Instance.new("Folder")
		parts.Name = groupName .. "Parts"
		parts.Parent = model
		for _, row in tris do
			local a = Vector3.new(row[1], row[2], row[3])
			local b = Vector3.new(row[4], row[5], row[6])
			local c = Vector3.new(row[7], row[8], row[9])
			count += triangle(a, b, c, parts, Color3.fromRGB(row[10], row[11], row[12]), row[13] == 1, groupRoot)
		end
	end
	model:SetAttribute("Wedges", count)
	model.Parent = folder
	total += count
end

print(("Models built: %d wedges"):format(total))
