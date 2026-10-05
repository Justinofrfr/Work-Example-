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
