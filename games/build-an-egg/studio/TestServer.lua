local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LogService = game:GetService("LogService")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
local function note(...)
	local parts = {}
	for _, value in { ... } do
		table.insert(parts, tostring(value))
	end
	table.insert(results, table.concat(parts, " "))
end

LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		note("[server " .. messageType.Name .. "]", message)
	end
end)

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
clientLog.OnServerEvent:Connect(function(_, message)
	note("[client]", message)
end)

local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local character = player.Character or player.CharacterAdded:Wait()
	local function watch(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			local root = char:FindFirstChild("HumanoidRootPart")
			note("DIED at", root and root.Position, "seat", humanoid.SeatPart, "state", humanoid:GetState())
		end)
	end
	watch(character)
	player.CharacterAdded:Connect(function(char)
		note("respawned")
		character = char
		watch(char)
	end)
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local StateService = require(Services.StateService)
	local CarryService = require(Services.CarryService)
	local BuildService = require(Services.BuildService)
	local GymService = require(Services.GymService)
	local UpgradeService = require(Services.UpgradeService)
	local CodeService = require(Services.CodeService)
	local GiftService = require(Services.GiftService)
	local EggShape = require(ReplicatedStorage.Shared.Util.EggShape)
	local MapConfig = require(ReplicatedStorage.Shared.Config.Map)

	local waited = 0
	while not DataService:Get(player) and waited < 15 do
		task.wait(0.25)
		waited += 0.25
	end
	task.wait(2)
	local data = DataService:Get(player)
	local runtime = StateService:Get(player)
	note("loaded", data ~= nil, "runtime", runtime ~= nil, "walk", character.Humanoid.WalkSpeed)
	note("stack", character:FindFirstChild("CarryStack") ~= nil, "rank", character.Head:FindFirstChild("RankTag") ~= nil)

	local quarry = MapConfig.Quarry.Center
	StateService:Teleport(player, CFrame.new(quarry + Vector3.new(0, -3, 0)))
	task.wait(0.5)
	note("at quarry", character.HumanoidRootPart.Position, "health", character.Humanoid.Health, "inQuarry", CarryService:InQuarry(character.HumanoidRootPart.Position))
	for _ = 1, 3 do
		runtime.LastPickup = 0
		CarryService:Interact(player)
	end
	note("carry after pickup (cap " .. StateService:Capacity(player) .. ")", runtime.Carry)

	data.Strength = 500
	runtime.LastPickup = 0
	CarryService:Interact(player)
	note("carry after strength 500", runtime.Carry, "cap", StateService:Capacity(player))

	local ring = BuildService:ActiveRing()
	local point = EggShape.ScaffoldPoint(EggShape.BandHeight(ring))
	StateService:Teleport(player, CFrame.new(point + Vector3.new(0, 4, 0)))
	task.wait(0.6)
	note("in band", BuildService:CanPlaceAt(player, character.HumanoidRootPart.Position), "pos", character.HumanoidRootPart.Position)
	runtime.LastPlace = 0
	CarryService:Interact(player)
	note("instant teleport place blocked: progress", BuildService.Progress)
	runtime.LastPickup = os.clock() - 60
	local coinsBefore = data.Coins
	runtime.LastPlace = 0
	CarryService:Interact(player)
	note("placed: progress", BuildService.Progress, "coins +", data.Coins - coinsBefore, "carry", runtime.Carry)

	StateService:Teleport(player, CFrame.new(quarry + Vector3.new(0, -3, 0)))
	task.wait(0.5)
	runtime.LastPlace = 0
	CarryService:Interact(player)
	note("place from quarry blocked: progress", BuildService.Progress)

	data.Coins = 1000
	note("buy BulkPickup", UpgradeService:Buy(player, "BulkPickup"))
	note("buy invalid", UpgradeService:Buy(player, "Nope"))
	note("code WELCOME", CodeService:Redeem(player, " welcome "))
	note("code again", CodeService:Redeem(player, "WELCOME"))
	note("gift", GiftService:Claim(player))
	note("gift again", GiftService:Claim(player))

	local pad
	for _, candidate in GymService.Pads do
		if candidate:GetAttribute("Tier") == "Gym1" and candidate:GetAttribute("Stat") == "Speed" then
			pad = candidate
			break
		end
	end
	local speedBefore = data.Speed
	StateService:Teleport(player, pad.CFrame)
	task.wait(2.6)
	note("training", runtime.Training and runtime.Training.Stat, "walk", character.Humanoid.WalkSpeed, "speed +", data.Speed - speedBefore)
	GymService:Stop(player, true)
	note("after stop training", runtime.Training, "walk", character.Humanoid.WalkSpeed)

	local lockedPad
	for _, candidate in GymService.Pads do
		if candidate:GetAttribute("Tier") == "Gym10" then
			lockedPad = candidate
			break
		end
	end
	StateService:Teleport(player, lockedPad.CFrame)
	task.wait(0.8)
	note("locked gym training", runtime.Training)

	StateService:Teleport(player, CFrame.new(point + Vector3.new(0, 4, 0)))
	local forced = workspace:GetAttribute("TestProjectIndex")
	if forced then
		BuildService.ProjectIndex = forced
	end
	BuildService:AddPieces(player, BuildService:Target(), true)
	note("phase after fill", BuildService.Phase)
	task.wait(6.5)
	note("phase after cutscene", BuildService.Phase)
	local eggsBefore = data.Eggs
	note("claim", BuildService:ClaimHatch(player))
	note("eggs +", data.Eggs - eggsBefore, "rank", character.Head:FindFirstChild("RankTag") and character.Head.RankTag.Title.Text)
	task.wait(1)
	local root = character.HumanoidRootPart.Position
	note("in interior", root.Y < -200, root)
	local poolSpeed = data.Speed
	StateService:Teleport(player, workspace.Game.Interior.Pool.CFrame)
	task.wait(2.4)
	note("pool training", runtime.Training and runtime.Training.Stat, "speed +", data.Speed - poolSpeed)
	BuildService:ResetRound()
	note("after reset phase", BuildService.Phase, "project", BuildService:Project(), "progress", BuildService.Progress)
	task.wait(1.5)
end)
if not ok then
	note("TEST ERROR", err)
end
task.wait(1)
StudioTestService:EndTest(table.concat(results, "\n"))
