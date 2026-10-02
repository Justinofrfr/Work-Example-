local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetsConfig = require(Shared.Config.Pets)
local PetRules = require(Shared.Util.PetRules)

local PetView = {}

local folder = ReplicatedStorage:WaitForChild("Pets")

function PetView.Template(collection, rarity)
	return folder:FindFirstChild(PetRules.ModelName(collection, rarity))
end

function PetView.Name(collection, rarity)
	local def = PetsConfig.Collections[collection]
	local tier = PetsConfig.Rarities[rarity]
	return ("%s %s"):format(def and def.Name or collection, tier and tier.Species or "?")
end

function PetView.Show(frame, collection, rarity, yaw)
	local camera = frame:FindFirstChildOfClass("Camera")
	frame.CurrentCamera = camera
	local old = frame:FindFirstChild("Pet")
	if old then
		old:Destroy()
	end
	local template = PetView.Template(collection, rarity)
	if not template or not camera then
		return nil
	end
	local model = template:Clone()
	model.Name = "Pet"
	model:PivotTo(CFrame.Angles(0, math.rad(yaw or 0), 0) * template:GetPivot().Rotation)
	model.Parent = frame
	local boxCFrame, size = model:GetBoundingBox()
	local radius = size.Magnitude / 2
	camera.CFrame = CFrame.lookAt(boxCFrame.Position + Vector3.new(0, radius * 0.35, -radius * 2.7), boxCFrame.Position)
	return model
end

return PetView
