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
for _ = 1, 52 do
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
		local rest = neck.Attachment0.CFrame
		local transforms = {}
		root.CFrame = npcRoot.CFrame * CFrame.new(-7, 0, -8)
		for i = 1, 6 do
			task.wait(0.4)
			transforms[i] = neck.Transform
		end
		local turned = math.deg(math.acos(math.clamp(neck.Attachment0.CFrame.LookVector:Dot(rest.LookVector), -1, 1)))
		local wiggle = math.deg(math.acos(math.clamp(transforms[1].LookVector:Dot(transforms[6].LookVector), -1, 1)))
		local toPlayer = (root.Position - npc.Head.Position) * Vector3.new(1, 0, 1)
		local headFacing = npc.Head.CFrame.LookVector * Vector3.new(1, 0, 1)
		local facing = math.deg(math.acos(math.clamp(toPlayer.Unit:Dot(headFacing.Unit), -1, 1)))
		table.insert(lookInfo, ("%s neck turned %.1f deg, head off player %.1f deg, posed wiggle %.1f deg"):format(npc.Name, turned, facing, wiggle))
	end
end
clientLog:FireServer("look: " .. table.concat(lookInfo, " | "))
