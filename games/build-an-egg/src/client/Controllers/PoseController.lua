local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local EffectsConfig = require(Shared.Config.Effects)

local PoseController = {
	Rigs = {},
}

local A = Names.Attributes
local P = EffectsConfig.Poses
local camera = Workspace.CurrentCamera
local templates

local function joints(character)
	local list = { Shoulders = {}, Elbows = {} }
	for _, def in { { "RightUpperArm", "RightShoulder", 1, "Shoulders" }, { "LeftUpperArm", "LeftShoulder", -1, "Shoulders" }, { "Torso", "Right Shoulder", 1, "Shoulders" }, { "Torso", "Left Shoulder", -1, "Shoulders" }, { "RightLowerArm", "RightElbow", 1, "Elbows" }, { "LeftLowerArm", "LeftElbow", -1, "Elbows" } } do
		local holder = character:FindFirstChild(def[1])
		local motor = holder and holder:FindFirstChild(def[2])
		if motor and motor:IsA("Motor6D") then
			table.insert(list[def[4]], { Motor = motor, Base = motor.C0, Side = def[3], R6 = def[1] == "Torso", Angle = 0 })
		end
	end
	return list
end

function PoseController:Start()
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
	local function track(player)
		local function onCharacter(character)
			task.wait(0.5)
			if character.Parent then
				local rig = joints(character)
				rig.Character = character
				self.Rigs[character] = rig
			end
		end
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end
	for _, player in Players:GetPlayers() do
		track(player)
	end
	Players.PlayerAdded:Connect(track)
	RunService.RenderStepped:Connect(function(dt)
		self:Step(dt)
	end)
end

function PoseController:Barbell(rig, show)
	if show and not rig.Barbell then
		local template = templates:FindFirstChild("Barbell")
		if template then
			rig.Barbell = template:Clone()
			rig.Barbell.Parent = Workspace
		end
	elseif not show and rig.Barbell then
		rig.Barbell:Destroy()
		rig.Barbell = nil
	end
	if rig.Barbell then
		local character = rig.Character
		local left = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
		local right = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		if left and right then
			local middle = (left.Position + right.Position) / 2
			local axis = right.Position - left.Position
			if axis.Magnitude > 0.01 then
				rig.Barbell:PivotTo(CFrame.lookAt(middle, middle + axis) * CFrame.Angles(0, math.rad(90), 0))
			end
		end
	end
end

function PoseController:Step(dt)
	local t = os.clock()
	local cameraPosition = camera.CFrame.Position
	for character, rig in self.Rigs do
		if not character.Parent then
			self:Barbell(rig, false)
			self.Rigs[character] = nil
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - cameraPosition).Magnitude > P.CullDistance then
			continue
		end
		local training = character:GetAttribute(A.Training)
		local lifting = training == "Strength"
		local shoulderTarget = 0
		local elbowTarget = 0
		if lifting then
			local wave = 0.5 + 0.5 * math.sin(t * P.LiftSpeed)
			shoulderTarget = math.rad(P.LiftShoulderAngle)
			elbowTarget = math.rad(P.LiftElbowMax) * (1 - wave)
		elseif character:GetAttribute(A.Carrying) then
			shoulderTarget = math.rad(P.CarryArmAngle)
		end
		local alpha = lifting and 1 or math.min(1, dt * P.CarryLerp)
		for _, joint in rig.Shoulders do
			if joint.Motor.Parent then
				joint.Angle += (shoulderTarget - joint.Angle) * alpha
				local rotation = joint.R6 and CFrame.Angles(0, 0, joint.Side * joint.Angle) or CFrame.Angles(joint.Angle, 0, 0)
				joint.Motor.C0 = joint.Base * rotation
			end
		end
		for _, joint in rig.Elbows do
			if joint.Motor.Parent then
				joint.Angle += (elbowTarget - joint.Angle) * alpha
				joint.Motor.C0 = joint.Base * CFrame.Angles(joint.Angle, 0, 0)
			end
		end
		self:Barbell(rig, lifting)
	end
end

return PoseController
