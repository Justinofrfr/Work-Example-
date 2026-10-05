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
local stage = Instance.new("StringValue")
stage.Name = "__TestStage"
stage.Parent = ReplicatedStorage
clientLog.OnServerEvent:Connect(function(_, message)
	note("[client]", message)
end)

local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local character = player.Character or player.CharacterAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local StateService = require(Services.StateService)
	local BuildService = require(Services.BuildService)
	local GymService = require(Services.GymService)
	local TutorialService = require(Services.TutorialService)
	local OfferService = require(Services.OfferService)
	local GameConfig = require(ReplicatedStorage.Shared.Config.Game)
	local PetsConfig = require(ReplicatedStorage.Shared.Config.Pets)
	local TutorialConfig = require(ReplicatedStorage.Shared.Config.Tutorial)
	local EggShape = require(ReplicatedStorage.Shared.Util.EggShape)

	local waited = 0
	while not DataService:Get(player) and waited < 15 do
		task.wait(0.25)
		waited += 0.25
	end
	task.wait(3)
	local data = DataService:Get(player)
	note("loaded", data ~= nil, "tutorialStep", data.TutorialStep, "offer", data.StarterOffer.Ready, data.StarterOffer.Ends, data.StarterOffer.Bought)

	stage.Value = "Idle"
	task.wait(4)

	stage.Value = "Interlude"
	local point = EggShape.ScaffoldPoint(EggShape.BandHeight(BuildService:ActiveRing()))
	StateService:Teleport(player, CFrame.new(point + Vector3.new(0, 4, 0)))
	BuildService:AddPieces(player, BuildService:Target(), true)
	note("interlude phase", BuildService.Phase)
	task.wait(GameConfig.CompletionCutsceneTime + 3)
	note("after cutscene phase", BuildService.Phase)
	BuildService:ResetRound()
	task.wait(2)

	stage.Value = "Training"
	local pad
	for _, candidate in GymService.Pads do
		if candidate:GetAttribute("Tier") == "Gym1" and candidate:GetAttribute("Stat") == "Speed" then
			pad = candidate
			break
		end
	end
	StateService:Teleport(player, pad.CFrame)
	task.wait(26)
	local runtime = StateService:Get(player)
	note("training stat", runtime.Training and runtime.Training.Stat)
	GymService:Stop(player, true)
	task.wait(1)

	stage.Value = "Pets"
	local PetService = require(Services.PetService)
	for collection in PetsConfig.Collections do
		for _ = 1, 6 do
			PetService:GrantFragments(player, collection, 200000)
		end
	end
	local kinds = 0
	for _ in data.Fragments do
		kinds += 1
	end
	note("fragment kinds", kinds)
	StateService:Dirty(player)
	task.wait(3)

	stage.Value = "Offer"
	TutorialService:SetStep(player, #TutorialConfig.Steps)
	note("offer scheduled ready-now", data.StarterOffer.Ready - os.time(), "window", data.StarterOffer.Ends - data.StarterOffer.Ready)
	data.StarterOffer.Ready = os.time() - 1
	StateService:Dirty(player)
	task.wait(5)
	note("mark bought previous", OfferService:MarkBought(player, "StarterPack"), "other product", OfferService:MarkBought(player, "ServerPack1K"))
	StateService:Dirty(player)
	task.wait(3)
	stage.Value = "Done"
	task.wait(2)
end)
if not ok then
	note("TEST ERROR", err)
end
stage:Destroy()
StudioTestService:EndTest(table.concat(results, "\n"))
