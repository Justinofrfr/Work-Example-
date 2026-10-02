local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function describe(character)
	local parts = {}
	for _, name in { "Head", "UpperTorso", "Torso", "RightUpperArm", "RightLowerArm", "RightHand", "LeftHand", "Right Arm", "Left Arm" } do
		local part = character:FindFirstChild(name)
		if part then
			local rel = character.HumanoidRootPart.CFrame:PointToObjectSpace(part.Position)
			table.insert(parts, ("%s(%.1f,%.1f,%.1f)"):format(name, rel.X, rel.Y, rel.Z))
		end
	end
	local barbell = workspace:FindFirstChild("Barbell")
	if barbell then
		local rel = character.HumanoidRootPart.CFrame:PointToObjectSpace(barbell:GetPivot().Position)
		table.insert(parts, ("Barbell(%.1f,%.1f,%.1f)"):format(rel.X, rel.Y, rel.Z))
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	table.insert(parts, "state " .. tostring(humanoid and humanoid:GetState()))
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			table.insert(parts, "anim " .. track.Name .. " " .. track.Animation.AnimationId .. " w" .. string.format("%.2f", track.WeightCurrent))
		end
	end
	return table.concat(parts, " ")
end

task.spawn(function()
	repeat
		task.wait(0.2)
	until player.Character and player.Character:GetAttribute("Training") == "Strength"
	local character = player.Character
	task.wait(1)
	RunService:BindToRenderStep("PoseCam", Enum.RenderPriority.Camera.Value + 1, function()
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			camera.CameraType = Enum.CameraType.Scriptable
			local side = workspace:GetAttribute("PoseView") or 1
			local offset = side == 1 and Vector3.new(9, 4, 0) or Vector3.new(0, 10, 0.01)
			camera.CFrame = CFrame.lookAt(root.Position + offset, root.Position)
		end
	end)
	for _ = 1, 3 do
		clientLog:FireServer(describe(character))
		task.wait(0.6)
	end
end)
