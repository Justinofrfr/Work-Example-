local CollectionService = game:GetService("CollectionService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		clientLog:FireServer(messageType.Name .. ": " .. message)
	end
end)

local player = Players.LocalPlayer
player.CharacterAdded:Wait()
task.wait(3)
local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if root then
	root.CFrame = CFrame.new(-20, 8, -205)
	root.Anchored = true
end

local cart = CollectionService:GetTagged("QuarryCart")[1]
local bucket = workspace.Game.Scenery.QuarryKit:FindFirstChild("SwingBucket")
local bottles = CollectionService:GetTagged("Potion")
local cartStart = cart and cart.Position
local bucketStart = bucket and bucket:GetPivot().LookVector
local bottleStarts = {}
for _, part in bottles do
	bottleStarts[part] = part.CFrame
end
local cartMax, bucketMax, bottleMax, bottleMoved = 0, 0, 0, 0
for _ = 1, workspace:GetAttribute("LookProbe") and 2 or 52 do
	task.wait(0.5)
	if cart then
		cartMax = math.max(cartMax, (cart.Position - cartStart).Magnitude)
	end
	if bucket then
		bucketMax = math.max(bucketMax, math.deg(math.acos(math.clamp(bucket:GetPivot().LookVector:Dot(bucketStart), -1, 1))))
	end
	local moved = 0
	for part, start in bottleStarts do
		local d = (part.Position - start.Position).Magnitude
		bottleMax = math.max(bottleMax, d)
		if d > 0.05 then
			moved += 1
		end
	end
	bottleMoved = math.max(bottleMoved, moved)
end
local npcInfo = {}
for _, npc in CollectionService:GetTagged("NPC") do
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	table.insert(npcInfo, npc.Name .. "=" .. (animator and #animator:GetPlayingAnimationTracks() or -1))
end
clientLog:FireServer(("cart moved max %.2f studs | bucket swing max %.1f deg | bottles %d, max moved together %d, max distance %.2f | npc playing tracks %s"):format(cartMax, bucketMax, #bottles, bottleMoved, bottleMax, table.concat(npcInfo, " ")))

local lookInfo = {}
for _, npc in CollectionService:GetTagged("NPC") do
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	local neck = npc:FindFirstChild("Neck", true)
	if root and npcRoot and neck and neck:IsA("AnimationConstraint") then
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		local function stopEmotes()
			for _, track in animator and animator:GetPlayingAnimationTracks() or {} do
				if track.Priority == Enum.AnimationPriority.Action then
					track:Stop(0)
				end
			end
		end
		local function turnedFrom(far)
			local forward = npcRoot.CFrame.LookVector
			local moved = (npc.Head.CFrame.Rotation * far:Inverse()):VectorToWorldSpace(forward)
			local a = npcRoot.CFrame:VectorToObjectSpace(moved)
			return math.deg(math.atan2(-a.X, -a.Z))
		end
		root.CFrame = npcRoot.CFrame * CFrame.new(0, 0, -40)
		stopEmotes()
		task.wait(2)
		local far = npc.Head.CFrame.Rotation
		root.CFrame = npcRoot.CFrame * CFrame.new(-7, 0, -8)
		local transforms, total = {}, 0
		task.wait(1.6)
		for i = 1, 6 do
			stopEmotes()
			task.wait(0.15)
			transforms[i] = neck.Transform
			total += turnedFrom(far)
		end
		local wiggle = math.deg(math.acos(math.clamp(transforms[1].LookVector:Dot(transforms[6].LookVector), -1, 1)))
		table.insert(lookInfo, ("%s head turned %.1f deg toward player (player at 41), neck wiggle %.1f deg"):format(npc.Name, total / 6, wiggle))
	end
end
local probe = workspace.Game.NPCs:FindFirstChild("Upgrades")
if root and probe and workspace:GetAttribute("LookProbe") then
	local ambient = require(player.PlayerScripts.Client.Controllers.AmbientController)
	local probeRoot = probe.HumanoidRootPart
	local animator = probe:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
	local parts = { "HumanoidRootPart", "LowerTorso", "UpperTorso", "Head" }
	local function snapshot()
		for _, track in animator:GetPlayingAnimationTracks() do
			if track.Priority == Enum.AnimationPriority.Action then
				track:Stop(0)
			end
		end
		task.wait(0.2)
		local shot = {}
		for _, name in parts do
			shot[name] = probe[name].CFrame.Rotation
		end
		return shot
	end
	local function yawDelta(a, b)
		local moved = probeRoot.CFrame:VectorToObjectSpace((b * a:Inverse()):VectorToWorldSpace(probeRoot.CFrame.LookVector))
		return math.deg(math.atan2(-moved.X, -moved.Z))
	end
	local function measure(label)
		root.CFrame = probeRoot.CFrame * CFrame.new(0, 0, -40)
		task.wait(1.8)
		local far = snapshot()
		root.CFrame = probeRoot.CFrame * CFrame.new(-7, 0, -8)
		task.wait(1.8)
		local near = snapshot()
		local out = {}
		for _, name in parts do
			table.insert(out, ("%s=%.1f"):format(name, yawDelta(far[name], near[name])))
		end
		return label .. " " .. table.concat(out, " ")
	end
	local on = measure("on")
	local saved = ambient.Lookers[probe]
	ambient.Lookers[probe] = nil
	for _, joint in saved and saved.Joints or {} do
		if joint.Applied then
			joint.Joint.Transform = joint.Raw
			joint.Applied = false
		end
	end
	local off = measure("off")
	ambient.Lookers[probe] = saved
	clientLog:FireServer("probe " .. on .. " | " .. off)
end

local goose = CollectionService:GetTagged("GooseRig")[1]
local gooseHead = goose and goose:FindFirstChild("Head", true)
local gooseBody = goose and goose:FindFirstChild("Body", true)
if root and gooseHead and gooseBody and gooseHead:IsA("Bone") then
	local forward = ((gooseHead.WorldPosition - gooseBody.WorldPosition) * Vector3.new(1, 0, 1)).Unit
	local side = forward:Cross(Vector3.yAxis)
	root.CFrame = CFrame.new(gooseHead.WorldPosition + forward * 70)
	task.wait(2)
	local far = gooseHead.WorldCFrame.Rotation
	root.CFrame = CFrame.new(gooseHead.WorldPosition + side * 12 + forward * 4)
	task.wait(2)
	local moved = ((gooseHead.WorldCFrame.Rotation * far:Inverse()):VectorToWorldSpace(forward) * Vector3.new(1, 0, 1)).Unit
	table.insert(lookInfo, ("goose head turned %.1f deg toward player (player at -72)"):format(math.deg(math.atan2(forward:Cross(moved).Y, forward:Dot(moved)))))
end
clientLog:FireServer("look: " .. table.concat(lookInfo, " | "))
