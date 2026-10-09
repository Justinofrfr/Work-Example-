local CollectionService = game:GetService("CollectionService")
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
		elseif motor and motor:IsA("AnimationConstraint") and motor.Attachment0 then
			table.insert(list[def[4]], { Motor = motor, Attachment = motor.Attachment0, Base = motor.Attachment0.CFrame, Side = def[3], R6 = false, Angle = 0 })
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

local function nearestRack(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local best, bestDistance
	for _, rack in root and CollectionService:GetTagged(P.RackTag) or {} do
		local distance = (rack.Position - root.Position).Magnitude
		if rack:IsDescendantOf(Workspace) and distance < P.RackRange and (not best or distance < bestDistance) then
			best, bestDistance = rack, distance
		end
	end
	return best
end

local function ease(alpha)
	return 0.5 - math.cos(math.clamp(alpha, 0, 1) * math.pi) / 2
end

function PoseController:DropBarbell(rig)
	if rig.Barbell then
		rig.Barbell:Destroy()
		rig.Barbell = nil
	end
	if rig.Rack then
		rig.Rack.LocalTransparencyModifier = 0
		rig.Rack = nil
	end
	rig.Returning = nil
end

function PoseController:Barbell(rig, show)
	local t = os.clock()
	if show and (not rig.Barbell or rig.Returning) then
		if not rig.Barbell then
			local rack = nearestRack(rig.Character)
			local template = rack or templates:FindFirstChild("Barbell")
			if template then
				rig.Barbell = template:Clone()
				for _, tag in CollectionService:GetTags(rig.Barbell) do
					CollectionService:RemoveTag(rig.Barbell, tag)
				end
				if rig.Barbell:IsA("BasePart") then
					rig.Barbell.Anchored = true
					rig.Barbell.CanCollide = false
					rig.Barbell.CanQuery = false
				end
				rig.Barbell.Parent = Workspace
				rig.Rack = rack
				rig.PickedAt = t
				if rack then
					rack.LocalTransparencyModifier = 1
				end
			end
		end
		rig.Returning = nil
	elseif not show and rig.Barbell and not rig.Returning then
		if rig.Rack and rig.Rack.Parent then
			rig.Returning = { From = rig.Barbell:GetPivot(), At = t }
		else
			self:DropBarbell(rig)
		end
	end
	if not rig.Barbell then
		return
	end
	if rig.Returning then
		local alpha = (t - rig.Returning.At) / P.ReturnTime
		rig.Barbell:PivotTo(rig.Returning.From:Lerp(rig.Rack.CFrame, ease(alpha)))
		if alpha >= 1 then
			self:DropBarbell(rig)
		end
		return
	end
	local character = rig.Character
	local left = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	local right = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if left and right then
		local middle = (left.Position + right.Position) / 2
		local axis = right.Position - left.Position
		if axis.Magnitude > 0.01 then
			local hands = CFrame.lookAt(middle, middle + axis) * CFrame.Angles(0, math.rad(90), 0)
			local alpha = rig.Rack and (t - rig.PickedAt) / P.PickupTime or 1
			rig.Barbell:PivotTo(alpha < 1 and rig.Rack.CFrame:Lerp(hands, ease(alpha)) or hands)
		end
	end
end

function PoseController:Freeze(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
end

function PoseController:Step(dt)
	local t = os.clock()
	local cameraPosition = camera.CFrame.Position
	for character, rig in self.Rigs do
		if not character.Parent then
			self:DropBarbell(rig)
			self.Rigs[character] = nil
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - cameraPosition).Magnitude > P.CullDistance then
			continue
		end
		local stale = #rig.Shoulders == 0 or not rig.Shoulders[1].Motor:IsDescendantOf(character)
		if stale and t - (rig.LastScan or 0) > 1 then
			rig.LastScan = t
			local fresh = joints(character)
			rig.Shoulders = fresh.Shoulders
			rig.Elbows = fresh.Elbows
		end
		local training = character:GetAttribute(A.Training)
		local lifting = training == "Strength"
		local shoulderTarget = 0
		local elbowTarget = 0
		if lifting then
			local wave = 0.5 + 0.5 * math.sin(t * P.LiftSpeed)
			local shoulder = P.LiftShoulderMin + (P.LiftShoulderMax - P.LiftShoulderMin) * wave
			shoulderTarget = math.rad(shoulder)
			elbowTarget = math.rad(P.LiftShoulderMax - shoulder)
			self:Freeze(character)
		elseif character:GetAttribute(A.Carrying) then
			shoulderTarget = math.rad(P.CarryArmAngle)
		end
		local alpha = lifting and 1 or math.min(1, dt * P.CarryLerp)
		for _, joint in rig.Shoulders do
			if joint.Motor.Parent then
				joint.Angle += (shoulderTarget - joint.Angle) * alpha
				local rotation = joint.R6 and CFrame.Angles(0, 0, joint.Side * joint.Angle) or CFrame.Angles(joint.Angle, 0, 0)
				if joint.Attachment then
					joint.Attachment.CFrame = joint.Base * rotation
				else
					joint.Motor.C0 = joint.Base * rotation
				end
			end
		end
		for _, joint in rig.Elbows do
			if joint.Motor.Parent then
				joint.Angle += (elbowTarget - joint.Angle) * alpha
				if joint.Attachment then
					joint.Attachment.CFrame = joint.Base * CFrame.Angles(joint.Angle, 0, 0)
				else
					joint.Motor.C0 = joint.Base * CFrame.Angles(joint.Angle, 0, 0)
				end
			end
		end
		self:Barbell(rig, lifting)
	end
end

return PoseController
