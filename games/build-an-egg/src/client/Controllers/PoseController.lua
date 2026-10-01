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

local function shoulders(character)
	local list = {}
	for _, pair in { { "RightUpperArm", "RightShoulder", 1 }, { "LeftUpperArm", "LeftShoulder", -1 }, { "Torso", "Right Shoulder", 1 }, { "Torso", "Left Shoulder", -1 } } do
		local holder = character:FindFirstChild(pair[1])
		local motor = holder and holder:FindFirstChild(pair[2])
		if motor and motor:IsA("Motor6D") then
			table.insert(list, { Motor = motor, Base = motor.C0, Side = pair[3], R6 = pair[1] == "Torso", Angle = 0 })
		end
	end
	return list
end

function PoseController:Start()
	local function track(player)
		local function onCharacter(character)
			task.wait(0.5)
			if character.Parent then
				self.Rigs[character] = { Character = character, Shoulders = shoulders(character) }
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

function PoseController:Step(dt)
	local t = os.clock()
	local cameraPosition = camera.CFrame.Position
	for character, rig in self.Rigs do
		if not character.Parent then
			self.Rigs[character] = nil
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - cameraPosition).Magnitude > P.CullDistance then
			continue
		end
		local target = 0
		local training = character:GetAttribute(A.Training)
		if training == "Strength" then
			target = math.rad(P.LiftBaseAngle + P.LiftSwing * math.sin(t * P.LiftSpeed))
		elseif character:GetAttribute(A.Carrying) then
			target = math.rad(P.CarryArmAngle)
		end
		local alpha = math.min(1, dt * P.CarryLerp)
		for _, shoulder in rig.Shoulders do
			if shoulder.Motor.Parent then
				shoulder.Angle += (target - shoulder.Angle) * (training == "Strength" and 1 or alpha)
				local rotation = shoulder.R6 and CFrame.Angles(0, 0, shoulder.Side * shoulder.Angle) or CFrame.Angles(shoulder.Angle, 0, 0)
				shoulder.Motor.C0 = shoulder.Base * rotation
			end
		end
	end
end

return PoseController
