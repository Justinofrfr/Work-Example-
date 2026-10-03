local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetRules = require(Shared.Util.PetRules)

local PetView = {}

local folder = ReplicatedStorage:WaitForChild("Pets")

function PetView.Template(collection, rarity)
	return folder:FindFirstChild(PetRules.ModelName(collection, rarity))
end

function PetView.Name(collection, rarity)
	return PetRules.DisplayName(collection, rarity)
end

function PetView.Show(frame, collection, rarity, yaw)
	local camera = frame:FindFirstChildOfClass("Camera")
	if not camera then
		camera = Instance.new("Camera")
		camera.FieldOfView = 40
		camera.Parent = frame
	end
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
