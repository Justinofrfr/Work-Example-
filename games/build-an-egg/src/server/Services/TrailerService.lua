local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local TrailerConfig = require(Shared.Config.Trailer)
local TutorialConfig = require(Shared.Config.Tutorial)
local EggShape = require(Shared.Util.EggShape)

local TrailerService = {
	Generation = 0,
}

local DataService
local StateService
local BuildService
local GymService
local CarryService
local PetService
local TutorialService
local remotes

function TrailerService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	BuildService = modules.BuildService
	GymService = modules.GymService
	CarryService = modules.CarryService
	PetService = modules.PetService
	TutorialService = modules.TutorialService
	remotes = context.Remotes
	if self:IsServer() then
		Workspace:SetAttribute(TrailerConfig.Attribute, true)
	end
end

function TrailerService:Start()
	remotes[Names.Remotes.Trailer].OnServerInvoke = function(player, action, index)
		if action ~= "Stage" or type(index) ~= "number" or not self:Active() or not self:IsDirector(player) then
			return false
		end
		return self:Stage(player, index)
	end
	Players.PlayerAdded:Connect(function(player)
		self:CheckLaunch(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(self.CheckLaunch, self, player)
	end
end

function TrailerService:IsServer()
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

function TrailerService:Active()
	return Workspace:GetAttribute(TrailerConfig.Attribute) == true
end

function TrailerService:IsDirector(player)
	return table.find(TrailerConfig.Directors, player.UserId) ~= nil
end

function TrailerService:CheckLaunch(player)
	if self:IsServer() or not self:IsDirector(player) then
		return
	end
	local ok, joinData = pcall(player.GetJoinData, player)
	if not ok or type(joinData) ~= "table" or joinData.LaunchData ~= TrailerConfig.LaunchData then
		return
	end
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	local teleported, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, { player }, options)
	if not teleported then
		warn("[TrailerService] teleport failed: " .. tostring(err))
	end
end

function TrailerService:Setup(player)
	local data = DataService:Get(player)
	if not data then
		return false
	end
	local setup = TrailerConfig.Setup
	for stat, value in setup.Stats do
		data[stat] = value
	end
	for upgrade, level in setup.Upgrades do
		data.Upgrades[upgrade] = level
	end
	if setup.TutorialDone then
		TutorialService:SetStep(player, #TutorialConfig.Steps)
	end
	data.Equipped = {}
	for _, pet in setup.Pets do
		PetService:AddPet(player, data, pet.Collection, pet.Rarity)
	end
	PetService:Apply(player)
	local goal = math.floor(BuildService:Target() * setup.Progress)
	if BuildService.Phase == "Building" and goal > BuildService.Progress then
		BuildService:AddPieces(player, goal - BuildService.Progress, false)
	end
	StateService:ApplyWalkSpeed(player)
	StateService:Dirty(player)
	return true
end

function TrailerService:Target(spec)
	local position, face
	if spec.Scaffold then
		local height = spec.Scaffold == "Band" and EggShape.BandHeight(BuildService:ActiveRing()) or spec.Scaffold
		local ground = EggShape.ScaffoldPoint(height)
		face = EggShape.ScaffoldPoint(height + 2) - ground
		position = ground + Vector3.new(0, 4, 0)
	else
		position = spec.Position
		face = spec.Face
	end
	face = face and Vector3.new(face.X, 0, face.Z)
	if face and face.Magnitude > 0.01 then
		return CFrame.lookAt(position, position + face.Unit)
	end
	return CFrame.new(position)
end

function TrailerService:FindPad(spec)
	for _, pad in GymService.Pads do
		if pad:GetAttribute(Names.Attributes.Tier) == spec.Tier and pad:GetAttribute(Names.Attributes.Stat) == spec.Stat then
			return pad
		end
	end
	return nil
end

function TrailerService:Loop(player, loop, generation)
	while self.Generation == generation and player.Parent do
		local runtime = StateService:Get(player)
		local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
		local still = Vector3.new(velocity.X, 0, velocity.Z).Magnitude < TrailerConfig.StillSpeed
		if loop.WhenStill and not still then
			task.wait(TrailerConfig.StillPoll)
			continue
		end
		if runtime and loop.Action == "Pickup" then
			self:Pickup(player, runtime, loop)
		elseif runtime and loop.Action == "Place" then
			self:Place(player, runtime, loop)
		end
		task.wait(loop.Every)
	end
end

function TrailerService:Pickup(player, runtime, loop)
	local amount = math.random(loop.Amount[1], loop.Amount[2])
	runtime.Carry += amount
	CarryService:UpdateVisual(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "Pickup", amount, false)
end

function TrailerService:Place(player, runtime, loop)
	if BuildService.Phase ~= "Building" then
		return
	end
	local amount = math.min(math.random(loop.Amount[1], loop.Amount[2]), BuildService:Target() - BuildService.Progress)
	if amount <= 0 then
		return
	end
	local data = DataService:Get(player)
	if data then
		data.Coins += amount
	end
	runtime.Carry = math.max(runtime.Carry - amount, 0)
	CarryService:UpdateVisual(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "Place", amount, BuildService:ActiveRing())
	BuildService:AddPieces(player, amount, false)
end

function TrailerService:Grow(player, grow, generation)
	local steps = math.max(1, math.floor(grow.Time / TrailerConfig.GrowStep))
	local start = BuildService.Progress
	local goal = math.floor(BuildService:Target() * grow.To)
	for step = 1, steps do
		if self.Generation ~= generation or BuildService.Phase ~= "Building" then
			return
		end
		local want = start + math.floor((goal - start) * step / steps)
		if want > BuildService.Progress then
			BuildService:AddPieces(player, want - BuildService.Progress, false)
		end
		task.wait(TrailerConfig.GrowStep)
	end
end

function TrailerService:Stage(player, index)
	self.Generation += 1
	local generation = self.Generation
	if index == 0 then
		return self:Setup(player)
	end
	local shot = TrailerConfig.Shots[index]
	local runtime = StateService:Get(player)
	if not shot or not runtime then
		return false
	end
	local stage = shot.Stage
	if runtime.Training and (stage.Stop or stage.Teleport or stage.Pad) then
		GymService:Stop(player, true)
	end
	if stage.Teleport then
		StateService:Teleport(player, self:Target(stage.Teleport))
	end
	if stage.Pad then
		local pad = self:FindPad(stage.Pad)
		if pad then
			GymService.Stopped[player] = nil
			StateService:Teleport(player, pad.CFrame + Vector3.new(0, 3, 0))
		end
	end
	if stage.Carry then
		runtime.Carry = math.min(stage.Carry, StateService:Capacity(player))
		runtime.PickupPosition = nil
		CarryService:UpdateVisual(player)
		StateService:Dirty(player)
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and not stage.Pad then
		StateService:ApplyWalkSpeed(player)
		if stage.WalkSpeed then
			humanoid.WalkSpeed = stage.WalkSpeed
		end
	end
	if stage.Loop then
		task.spawn(self.Loop, self, player, stage.Loop, generation)
	end
	if stage.Grow then
		task.spawn(self.Grow, self, player, stage.Grow, generation)
	end
	if stage.Complete then
		task.delay(TrailerConfig.CompleteDelay, function()
			if self.Generation == generation and BuildService.Phase == "Building" then
				BuildService:AddPieces(player, BuildService:Target() - BuildService.Progress, false)
			end
		end)
	end
	return true
end

return TrailerService
