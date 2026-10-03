local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		clientLog:FireServer("Error: " .. message)
	end
end)

local player = Players.LocalPlayer
task.spawn(function()
	local layer = player:WaitForChild("PlayerGui"):WaitForChild("Bubbles"):WaitForChild("Layer")
	local controller = require(player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("BubbleController"))
	repeat
		task.wait(0.1)
	until player.Character and player.Character:GetAttribute("Training") == "Speed"
	local bubble
	repeat
		task.wait(0.1)
		for _, child in layer:GetChildren() do
			if child.Name:match("^Bubble%d+$") then
				bubble = child
			end
		end
	until bubble
	task.wait(0.4)
	local id = tonumber(bubble.Name:match("%d+"))
	clientLog:FireServer(("bubble ui %s visible %s abs %s pos %s approach %.2f icon %s"):format(bubble.Name, tostring(bubble.Visible), tostring(bubble.AbsoluteSize), tostring(bubble.AbsolutePosition), bubble.Approach.Size.X.Scale, bubble.Icon.Text))
	controller:Pop(id)
	local float
	for _ = 1, 20 do
		task.wait(0.05)
		for _, child in layer:GetChildren() do
			if child.Name == "Float" and child.Visible then
				float = child
			end
		end
		if float then
			break
		end
	end
	clientLog:FireServer("float " .. (float and float.Text or "none") .. " bubble gone " .. tostring(bubble.Parent == nil or bubble.BackgroundTransparency > 0.5))
end)
task.spawn(function()
	local reported = false
	while not reported do
		task.wait(0.3)
		local character = player.Character
		if character and character:GetAttribute("Training") == "Strength" then
			task.wait(1)
			local barbell = workspace:FindFirstChild("Barbell")
			local right = character:FindFirstChild("RightHand")
			local left = character:FindFirstChild("LeftHand")
			local elbow = character:FindFirstChild("RightLowerArm") and character.RightLowerArm:FindFirstChild("RightElbow")
			local samples = {}
			for _ = 1, 4 do
				table.insert(samples, right and string.format("%.2f", right.Position.Y) or "?")
				task.wait(0.25)
			end
			clientLog:FireServer(("camDist %.0f barbell %s at %s hands mid %s rightHand Y samples %s elbowC0 %s"):format(
				(workspace.CurrentCamera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude,
				tostring(barbell ~= nil),
				barbell and tostring(barbell:GetPivot().Position) or "-",
				(right and left) and tostring((right.Position + left.Position) / 2) or "-",
				table.concat(samples, ","),
				elbow and tostring(elbow.C0.Rotation) or "-"
			))
			local pose = require(player.PlayerScripts.Client.Controllers.PoseController)
			local rig = pose.Rigs[character]
			local info = rig and ("shoulders=" .. #rig.Shoulders .. " elbows=" .. #rig.Elbows) or "no rig"
			if rig and rig.Shoulders[1] then
				info ..= " angle=" .. tostring(rig.Shoulders[1].Angle) .. " motorParent=" .. tostring(rig.Shoulders[1].Motor.Parent) .. " C0=" .. tostring(rig.Shoulders[1].Motor.C0.Rotation)
			end
			local found = {}
			for _, d in character:GetDescendants() do
				if d.Name:find("Shoulder") or d.Name:find("Elbow") then
					table.insert(found, d.ClassName .. ":" .. d.Name .. "@" .. d.Parent.Name)
				end
			end
			clientLog:FireServer(info .. " | " .. table.concat(found, ", "))
			reported = true
		end
	end
end)
