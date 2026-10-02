local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local EggConfig = require(Shared.Config.Egg)
local ProjectsConfig = require(Shared.Config.Projects)
local ProductsConfig = require(Shared.Config.Products)
local UIConfig = require(Shared.Config.UI)
local Names = require(Shared.Config.Names)
local Formulas = require(Shared.Util.Formulas)
local EggShape = require(Shared.Util.EggShape)
local Signal = require(Shared.Util.Signal)
local RateLimiter = require(Shared.Util.RateLimiter)
local AntiCheatConfig = require(Shared.Config.AntiCheat)

local claimLimiter = RateLimiter.new(GameConfig.RequestRateLimit, GameConfig.RequestRateWindow)

local BuildService = {
	Phase = "Building",
	PhaseEndsAt = 0,
	ProjectIndex = 1,
	Cycle = 0,
	Progress = 0,
	Round = 1,
	Contributions = {},
	Claimed = {},
	PendingPieces = 0,
	PendingContributions = {},
	MilestonesHit = {},
	Placements = {},
	Completed = Signal.new(),
	Reset = Signal.new(),
	EggsCredited = Signal.new(),
	HatchStarted = Signal.new(),
}

local DataService
local StateService
local MonetizationService
local CarryService
local GymService
local remotes

local world

local function now()
	return Workspace:GetServerTimeNow()
end

function BuildService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	MonetizationService = modules.MonetizationService
	CarryService = modules.CarryService
	GymService = modules.GymService
	remotes = context.Remotes
end

function BuildService:Start()
	world = Workspace:WaitForChild(Names.World.Root)
	self:UpdateRamp()
	remotes[Names.Remotes.LeaveEgg].OnServerInvoke = function(player)
		if not claimLimiter:Check(player) then
			return false
		end
		return self:LeaveInterior(player)
	end
	remotes[Names.Remotes.ClaimHatch].OnServerInvoke = function(player)
		if not claimLimiter:Check(player) then
			return false, "Busy"
		end
		return self:ClaimHatch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		self.Placements[tostring(player.UserId)] = nil
		claimLimiter:Remove(player)
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.ServerProgressSyncInterval)
			self:BroadcastServer()
		end
	end)
	self:BroadcastServer()
end

function BuildService:Project()
	local key = ProjectsConfig.Order[self.ProjectIndex]
	return key, ProjectsConfig.List[key]
end

function BuildService:Target()
	local _, project = self:Project()
	local rounding = ProjectsConfig.TargetRounding
	return math.floor(project.Target * ProjectsConfig.CycleGrowth ^ self.Cycle / rounding + 0.5) * rounding
end

function BuildService:ActiveRing()
	return EggShape.ActiveRing(self.Progress, self:Target())
end

function BuildService:Contribution(player)
	return self.Contributions[player.UserId] or 0
end

function BuildService:IsContributor(player)
	return self:Contribution(player) >= GameConfig.InteriorMinContribution
end

function BuildService:Snapshot()
	local key, project = self:Project()
	return {
		Project = key,
		ProjectName = project.DisplayName,
		ProjectIndex = self.ProjectIndex,
		Progress = self.Progress,
		Target = self:Target(),
		Phase = self.Phase,
		PhaseEndsAt = self.PhaseEndsAt,
		Ring = self:ActiveRing(),
		Round = self.Round,
	}
end

function BuildService:UpdateRamp()
	local ring = self.Phase == "Building" and self:ActiveRing() or GameConfig.RingCount
	if ring == self.RampRing then
		return
	end
	local site = world and world:FindFirstChild(Names.World.Site)
	local scaffold = site and site:FindFirstChild(Names.World.Scaffold)
	if not scaffold then
		return
	end
	self.RampRing = ring
	for _, piece in scaffold:GetChildren() do
		local index = piece:GetAttribute(Names.Attributes.Ring)
		if index and piece:IsA("BasePart") then
			local shown = index <= ring
			if piece:GetAttribute(Names.Attributes.Overlay) then
				for _, decal in piece:GetChildren() do
					if decal:IsA("Decal") then
						decal.Transparency = shown and EggConfig.RampArrowTransparency or 1
					end
				end
			else
				piece.Transparency = shown and 0 or 1
				piece.CanCollide = shown
				piece.CanQuery = shown
			end
		end
	end
end

function BuildService:BroadcastServer()
	self:UpdateRamp()
	local payload = self:Snapshot()
	if next(self.Placements) then
		payload.Placements = self.Placements
		self.Placements = {}
	end
	remotes[Names.Remotes.ServerSync]:FireAllClients(payload)
end

function BuildService:SendServer(player)
	remotes[Names.Remotes.ServerSync]:FireClient(player, self:Snapshot())
end

function BuildService:CanPlaceAt(player, position)
	local data = DataService:Get(player)
	if not data then
		return false
	end
	local reach = 1 + Formulas.UpgradeValue("Range", data.Upgrades.Range or 0)
	return EggShape.InBand(position, self:ActiveRing(), reach, GameConfig.DistanceTolerance)
end

function BuildService:TryPlace(player, rootPart)
	local data = DataService:Get(player)
	local runtime = StateService:Get(player)
	if not data or not runtime then
		return false
	end
	if self.Phase ~= "Building" then
		remotes[Names.Remotes.Notify]:FireClient(player, "Toast", UIConfig.Messages.NotBuilding, "Bad")
		return false
	end
	if runtime.Carry <= 0 then
		remotes[Names.Remotes.Notify]:FireClient(player, "Toast", UIConfig.Messages.NoPieces, "Bad")
		return false
	end
	if not self:CanPlaceAt(player, rootPart.Position) then
		return false
	end
	if runtime.PickupPosition then
		local humanoid = rootPart.Parent:FindFirstChildOfClass("Humanoid")
		local delta = rootPart.Position - runtime.PickupPosition
		local travel = Vector2.new(delta.X, delta.Z).Magnitude
		local minimum = travel / math.max(humanoid and humanoid.WalkSpeed or 0, AntiCheatConfig.MinWalkSpeed) * AntiCheatConfig.TravelSlack
		if os.clock() - runtime.LastPickup < minimum then
			return false
		end
	end
	local instant = MonetizationService:OwnsPass(player, "GoldenGoose") and ProductsConfig.GamePasses.GoldenGoose.InstantActions
	local cooldown = instant and GameConfig.ActionCooldownFloor or math.max(GameConfig.PlaceRepeat - GameConfig.ActionCooldownSlack, GameConfig.ActionCooldownFloor)
	local clock = os.clock()
	if clock - runtime.LastPlace < cooldown then
		return false
	end
	runtime.LastPlace = clock
	local quick = MonetizationService:OwnsPass(player, "GoldenGoose") and ProductsConfig.GamePasses.GoldenGoose.QuickPlace
	local amount = quick and runtime.Carry or math.min(runtime.Carry, Formulas.PlaceAmount(data.Upgrades.BulkPlace or 0))
	amount = math.min(amount, self:Target() - self.Progress)
	if amount <= 0 then
		return false
	end
	runtime.Carry -= amount
	data.Coins += amount * GameConfig.CoinsPerPiece
	data.PiecesPlaced += amount
	DataService:MarkDirty(player)
	CarryService:UpdateVisual(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "Place", amount, self:ActiveRing())
	self:AddPieces(player, amount, false)
	return true
end

function BuildService:AddPieces(player, amount, isPurchase)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then
		return
	end
	local userId = player and player.UserId
	if self.Phase ~= "Building" then
		if isPurchase then
			self.PendingPieces += amount
			if userId then
				self.PendingContributions[userId] = (self.PendingContributions[userId] or 0) + amount
			end
		end
		return
	end
	local target = self:Target()
	local added = math.min(amount, target - self.Progress)
	local overflow = amount - added
	self.Progress += added
	if userId then
		self.Contributions[userId] = (self.Contributions[userId] or 0) + amount
		self.Placements[tostring(userId)] = (self.Placements[tostring(userId)] or 0) + added
		if player.Parent then
			StateService:Dirty(player)
		end
	end
	self:CheckMilestones()
	if self.Progress >= target then
		if isPurchase and overflow > 0 then
			self.PendingPieces += overflow
		end
		self:Complete()
	end
end

function BuildService:CheckMilestones()
	local fraction = self.Progress / self:Target()
	for _, milestone in GameConfig.Milestones do
		if fraction >= milestone and not self.MilestonesHit[milestone] then
			self.MilestonesHit[milestone] = true
			remotes[Names.Remotes.Notify]:FireAllClients("Milestone", milestone)
		end
	end
end

function BuildService:SetPhase(phase, duration)
	self.Phase = phase
	self.PhaseEndsAt = now() + (duration or 0)
	self:BroadcastServer()
end

function BuildService:Complete()
	if self.Phase ~= "Building" then
		return
	end
	local round = self.Round
	self:SetPhase("Cutscene", GameConfig.CompletionCutsceneTime)
	self.Completed:Fire(self:Project())
	remotes[Names.Remotes.Notify]:FireAllClients("EggComplete", self:Project())
	task.delay(GameConfig.CompletionCutsceneTime, function()
		if self.Round ~= round then
			return
		end
		self:SetPhase("Interior", GameConfig.InteriorDuration)
		self.HatchStarted:Fire(self:Project())
		task.delay(GameConfig.HatchAutoClaimDelay, function()
			if self.Round == round then
				self:AutoClaim()
			end
		end)
		task.delay(GameConfig.InteriorDuration, function()
			if self.Round == round then
				self:ResetRound()
			end
		end)
	end)
end

function BuildService:CreditEgg(player)
	local data = DataService:Get(player)
	if not data or self.Claimed[player.UserId] then
		return 0
	end
	self.Claimed[player.UserId] = true
	local amount = MonetizationService:OwnsPass(player, "GoldenGoose") and ProductsConfig.GamePasses.GoldenGoose.CreditMultiplier or 1
	local before = data.Eggs
	data.Eggs += amount
	DataService:MarkDirty(player)
	StateService:ApplyRankTag(player, player.Character)
	StateService:Dirty(player)
	self.EggsCredited:Fire(player, before, data.Eggs)
	local oldRank = Formulas.Rank(before)
	local newRank = Formulas.Rank(data.Eggs)
	if oldRank ~= newRank then
		remotes[Names.Remotes.Notify]:FireClient(player, "RankUp", newRank.Name)
	end
	GymService:CheckUnlocks(player, before, data.Eggs)
	remotes[Names.Remotes.Notify]:FireClient(player, "Hatched", amount)
	return amount
end

function BuildService:ClaimHatch(player)
	if self.Phase ~= "Interior" then
		return false, "NotReady"
	end
	if not self:IsContributor(player) then
		return false, "NotContributor"
	end
	if self.Claimed[player.UserId] then
		self:SendToInterior(player)
		return false, "Claimed"
	end
	local amount = self:CreditEgg(player)
	self:SendToInterior(player)
	return true, amount
end

function BuildService:AutoClaim()
	for _, player in Players:GetPlayers() do
		if self:IsContributor(player) and not self.Claimed[player.UserId] then
			self:CreditEgg(player)
		end
	end
end

function BuildService:LeaveInterior(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local interior = world:FindFirstChild(Names.World.Interior)
	local spawnFolder = world:FindFirstChild(Names.World.Spawn)
	local spawn = spawnFolder and spawnFolder:FindFirstChildWhichIsA("SpawnLocation")
	if not rootPart or not interior or not spawn then
		return false
	end
	local pivot, size = interior:GetBoundingBox()
	local localPosition = pivot:PointToObjectSpace(rootPart.Position)
	if math.abs(localPosition.X) > size.X / 2 + 10 or math.abs(localPosition.Y) > size.Y / 2 + 10 or math.abs(localPosition.Z) > size.Z / 2 + 10 then
		return false
	end
	StateService:Teleport(player, spawn.CFrame + Vector3.new(0, 4, 0))
	return true
end

function BuildService:SendToInterior(player)
	local interior = world:FindFirstChild(Names.World.Interior)
	local arrive = interior and interior:FindFirstChild(Names.World.InteriorArrive)
	if arrive then
		StateService:Teleport(player, arrive.CFrame + Vector3.new(0, 3, 0))
	end
end

function BuildService:ResetRound()
	self:AutoClaim()
	local spawnFolder = world:FindFirstChild(Names.World.Spawn)
	local spawn = spawnFolder and spawnFolder:FindFirstChildWhichIsA("SpawnLocation")
	local interior = world:FindFirstChild(Names.World.Interior)
	if spawn and interior then
		local pivot, size = interior:GetBoundingBox()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local localPosition = pivot:PointToObjectSpace(rootPart.Position)
				if math.abs(localPosition.X) <= size.X / 2 + 10 and math.abs(localPosition.Y) <= size.Y / 2 + 10 and math.abs(localPosition.Z) <= size.Z / 2 + 10 then
					StateService:Teleport(player, spawn.CFrame + Vector3.new(0, 4, 0))
				end
			end
		end
	end
	self.Round += 1
	self.ProjectIndex = self.ProjectIndex % #ProjectsConfig.Order + 1
	if self.ProjectIndex == 1 then
		self.Cycle += 1
	end
	self.Contributions = self.PendingContributions
	self.PendingContributions = {}
	self.Claimed = {}
	self.MilestonesHit = {}
	self.Progress = 0
	self:SetPhase("Building", 0)
	self.Reset:Fire(self:Project())
	remotes[Names.Remotes.Notify]:FireAllClients("NextEgg", self:Project())
	for _, player in Players:GetPlayers() do
		StateService:Dirty(player)
	end
	local pending = self.PendingPieces
	self.PendingPieces = 0
	if pending > 0 then
		self:AddPieces(nil, pending, true)
	end
end

return BuildService
