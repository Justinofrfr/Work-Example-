local ServerStorage = game:GetService("ServerStorage")

local ASSETS = {
	Chick = 8780281108,
	Owl = 135771743712685,
	Goose = 13605683583,
	Dragon = 12859249654,
	Phoenix = 338568374,
	Hen = 930957937,
	Egg = 5168800671,
	Nest = 2657877247,
	Nature = 9682467046,
	Tree = 4893246329,
	Trees = 79689531752352,
	Treadmills = 135041830463035,
	Bench = 2151381239,
	Rack = 15275879602,
	Chest = 1880922775,
	Coins = 4725406385,
	Gift = 190430153,
	Throne = 2293753659,
	Sign = 12712225222,
	Scaffold = 12947205672,
}

local BLOCKED = { "Script", "LocalScript", "ModuleScript", "Tool", "Sound", "ClickDetector", "BodyMover", "Fire", "Smoke", "Explosion", "ForceField" }

local folder = ServerStorage:FindFirstChild("Imported")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Imported"
	folder.Parent = ServerStorage
end

local report = {}
for name, id in ASSETS do
	if not folder:FindFirstChild(name) then
		local ok, objects = pcall(function()
			return game:GetObjects("rbxassetid://" .. id)
		end)
		if ok and objects[1] then
			local model = Instance.new("Model")
			model.Name = name
			for _, object in objects do
				object.Parent = model
			end
			local stripped = 0
			for _, descendant in model:GetDescendants() do
				for _, className in BLOCKED do
					if descendant:IsA(className) then
						descendant:Destroy()
						stripped += 1
						break
					end
				end
			end
			model:SetAttribute("AssetId", id)
			model:SetAttribute("Stripped", stripped)
			model.Parent = folder
		else
			table.insert(report, name .. " FAILED " .. tostring(objects))
		end
	end
end

for _, model in folder:GetChildren() do
	local parts, meshes = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			if d:IsA("MeshPart") or d:FindFirstChildOfClass("SpecialMesh") then
				meshes += 1
			end
		end
	end
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	table.insert(report, ("%s parts=%d meshes=%d stripped=%s size=%s"):format(model.Name, parts, meshes, tostring(model:GetAttribute("Stripped")), ok and tostring(size) or "?"))
end
table.sort(report)
print(table.concat(report, "\n"))
