local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local MapConfig = require(Shared.Config.Map)
local GymsConfig = require(Shared.Config.Gyms)
local EggConfig = require(Shared.Config.Egg)
local ProductsConfig = require(Shared.Config.Products)
local UIConfig = require(Shared.Config.UI)
local Names = require(Shared.Config.Names)
local Formulas = require(Shared.Util.Formulas)
local RateLimiter = require(Shared.Util.RateLimiter)

local CarryService = {
	Blocks = {},
	Piles = {},
}

local DataService
local StateService
local MonetizationService
local BuildService
local remotes

local quarryZone
local templates
local pileFolder
local limiter = RateLimiter.new(GameConfig.InteractRateLimit, GameConfig.InteractRateWindow)
local dropLimiter = RateLimiter.new(GameConfig.DropRateLimit, 1)

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return nil
	end
	return rootPart
end

function CarryService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	MonetizationService = modules.MonetizationService
	BuildService = modules.BuildService
	remotes = context.Remotes
end

function CarryService:Start()
	local world = Workspace:WaitForChild(Names.World.Root)
	quarryZone = world:WaitForChild(Names.World.Quarry):WaitForChild(Names.World.QuarryZone)
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
	pileFolder = world:FindFirstChild(Names.World.Piles)
	remotes[Names.Remotes.Interact].OnServerEvent:Connect(function(player)
		if limiter:Check(player) then
			self:Interact(player)
		end
	end)
	remotes[Names.Remotes.Drop].OnServerEvent:Connect(function(player)
		if dropLimiter:Check(player) then
			self:Drop(player)
		end
	end)
	DataService.Loaded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:OnCharacter(player, character)
		end)
		if player.Character then
			self:OnCharacter(player, player.Character)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		limiter:Remove(player)
		dropLimiter:Remove(player)
		self.Blocks[player] = nil
	end)
	MonetizationService.PassChanged:Connect(function(player)
		self:ApplyCosmetics(player)
	end)
	task.spawn(function()
		for _ = 1, GameConfig.Scatter.Count do
			self:SpawnScatter()
		end
	end)
end

function CarryService:ScatterSpot()
	local S = GameConfig.Scatter
	local center = EggConfig.Center
	local gym = MapConfig.Gyms
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pileFolder }
	for _ = 1, S.Tries do
		local angle = math.random() * math.pi * 2
		local radius = S.MinRadius + math.random() * (S.MaxRadius - S.MinRadius)
		local spot = center + Vector3.new(math.sin(angle) * radius, 0, -math.cos(angle) * radius)
		local clear = (spot - quarryZone.Position).Magnitude > S.SpawnClearance + quarryZone.Size.Magnitude / 2
		for _, stand in MapConfig.Stands do
			clear = clear and (spot - stand).Magnitude > S.SpawnClearance
		end
		for index = 1, #GymsConfig.Tiers do
			local gymAngle = math.rad(gym.StartAngle + (index - 1) * gym.AngleStep)
			local gymSpot = center + Vector3.new(math.sin(gymAngle) * gym.Radius, 0, -math.cos(gymAngle) * gym.Radius)
			clear = clear and (spot - gymSpot).Magnitude > S.GymClearance + gym.PlatformSize.Magnitude / 2
		end
		if clear then
			local hit = Workspace:Raycast(spot + Vector3.new(0, S.DropHeight, 0), Vector3.new(0, -S.DropHeight * 2, 0), params)
			if hit and hit.Instance.Name == "Ground" then
				return hit.Position
			end
		end
	end
	return nil
end

function CarryService:SpawnScatter()
	local template = templates:FindFirstChild(Names.Templates.DroppedPile)
	local spot = template and pileFolder and self:ScatterSpot()
	if not spot then
		return
	end
	local S = GameConfig.Scatter
	local total = 0
	for _, weight in S.Weights do
		total += weight
	end
	local roll = math.random() * total
	local amount = S.Amounts[1]
	for index, weight in S.Weights do
		roll -= weight
		if roll <= 0 then
			amount = S.Amounts[index]
			break
		end
	end
	local pile = template:Clone()
	pile:SetAttribute("Scatter", true)
	self:SetPileCount(pile, amount)
	pile.CFrame = CFrame.new(spot + Vector3.new(0, pile.Size.Y / 2, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	pile.Parent = pileFolder
	self.Piles[pile] = true
	pile.Destroying:Connect(function()
		task.delay(S.Respawn[1] + math.random() * (S.Respawn[2] - S.Respawn[1]), function()
			self:SpawnScatter()
		end)
	end)
end

function CarryService:HasPerk(player, perk)
	return MonetizationService:OwnsPass(player, "GoldenGoose") and ProductsConfig.GamePasses.GoldenGoose[perk] == true
end

function CarryService:InQuarry(position)
	local localPosition = quarryZone.CFrame:PointToObjectSpace(position)
	local reach = GameConfig.BasePromptDistance + GameConfig.DistanceTolerance
	local half = quarryZone.Size / 2
	return math.abs(localPosition.X) <= half.X + reach and math.abs(localPosition.Y) <= half.Y + reach and math.abs(localPosition.Z) <= half.Z + reach
end

function CarryService:NearestPile(position)
	local best, bestDistance
	local reach = GameConfig.BasePromptDistance + GameConfig.DistanceTolerance
	for pile in self.Piles do
		if pile.Parent then
			local distance = (pile.Position - position).Magnitude
			if distance <= reach and (not bestDistance or distance < bestDistance) then
				best, bestDistance = pile, distance
			end
		else
			self.Piles[pile] = nil
		end
	end
	return best
end

function CarryService:Interact(player)
	local rootPart = rootOf(player)
	local runtime = StateService:Get(player)
	if not rootPart or not runtime or runtime.Training then
		return
	end
	local pile = self:NearestPile(rootPart.Position)
	if pile and runtime.Carry < StateService:Capacity(player) then
		self:TakePile(player, pile)
	elseif self:InQuarry(rootPart.Position) then
		self:Pickup(player)
	elseif BuildService:CanPlaceAt(player, rootPart.Position) then
		BuildService:TryPlace(player, rootPart)
	end
end

function CarryService:ReadyForPickup(player, runtime)
	local cooldown = self:HasPerk(player, "InstantActions") and GameConfig.ActionCooldownFloor or math.max(GameConfig.PickupRepeat - GameConfig.ActionCooldownSlack, GameConfig.ActionCooldownFloor)
	local clock = os.clock()
	if clock - runtime.LastPickup < cooldown then
		return false
	end
	runtime.LastPickup = clock
	return true
end

function CarryService:Pickup(player)
	local data = DataService:Get(player)
	local runtime = StateService:Get(player)
	if not data or not runtime then
		return false
	end
	local capacity = StateService:Capacity(player)
	if runtime.Carry >= capacity then
		remotes[Names.Remotes.Notify]:FireClient(player, "Full", UIConfig.Messages.Full)
		return false
	end
	if not self:ReadyForPickup(player, runtime) then
		return false
	end
	local rootPart = rootOf(player)
	runtime.PickupPosition = rootPart and rootPart.Position or runtime.PickupPosition
	local amount = self:HasPerk(player, "QuickPickup") and capacity - runtime.Carry or math.min(Formulas.PickupAmount(data.Upgrades.BulkPickup or 0), capacity - runtime.Carry)
	runtime.Carry += amount
	self:UpdateVisual(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "Pickup", amount, runtime.Carry >= capacity)
	return true
end

function CarryService:TakePile(player, pile)
	local runtime = StateService:Get(player)
	if not runtime or not self:ReadyForPickup(player, runtime) then
		return false
	end
	local stored = pile:GetAttribute("Pieces") or 0
	local amount = math.min(stored, StateService:Capacity(player) - runtime.Carry)
	if amount <= 0 then
		return false
	end
	runtime.PickupPosition = pile.Position
	runtime.Carry += amount
	stored -= amount
	if stored <= 0 then
		self.Piles[pile] = nil
		pile:Destroy()
	else
		self:SetPileCount(pile, stored)
	end
	self:UpdateVisual(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "Pickup", amount, false)
	return true
end

function CarryService:SetPileCount(pile, count)
	pile:SetAttribute("Pieces", count)
	local scale = math.min(GameConfig.CarryBlockBaseSize + GameConfig.CarryBlockGrowth * math.sqrt(count), GameConfig.CarryBlockMaxSize)
	local base = pile:GetAttribute("BaseSize") or pile.Size
	pile:SetAttribute("BaseSize", base)
	pile.Size = base.Unit * scale * math.sqrt(3)
	local gui = pile:FindFirstChild("Count")
	local label = gui and gui:FindFirstChild("Text")
	if label then
		label.Text = tostring(count)
	end
end

function CarryService:Drop(player)
	local runtime = StateService:Get(player)
	local rootPart = rootOf(player)
	if not runtime or not rootPart or runtime.Training or runtime.Carry <= 0 then
		return
	end
	local amount = runtime.Carry
	runtime.Carry = 0
	self:UpdateVisual(player)
	StateService:Dirty(player)
	if self:InQuarry(rootPart.Position) or not pileFolder then
		remotes[Names.Remotes.Notify]:FireClient(player, "Toast", UIConfig.Messages.DropQuarry, "Bad")
		return
	end
	local count = 0
	for pile in self.Piles do
		if pile.Parent and not pile:GetAttribute("Scatter") then
			count += 1
		end
	end
	if count >= GameConfig.MaxDroppedPiles then
		return
	end
	local template = templates:FindFirstChild(Names.Templates.DroppedPile)
	if not template then
		return
	end
	local pile = template:Clone()
	self:SetPileCount(pile, amount)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, pileFolder }
	local hit = Workspace:Raycast(rootPart.Position, Vector3.new(0, -GameConfig.DropGroundReach, 0), params)
	local groundY = hit and hit.Position.Y or rootPart.Position.Y - 3
	pile.CFrame = CFrame.new(rootPart.Position.X, groundY + pile.Size.Y / 2, rootPart.Position.Z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	pile.Parent = pileFolder
	self.Piles[pile] = true
	Debris:AddItem(pile, GameConfig.DropLifetime)
	remotes[Names.Remotes.Effect]:FireClient(player, "Drop", amount)
end

function CarryService:OnCharacter(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head or not templates then
		return
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:WaitForChild("UpperTorso", 5)
	local template = templates:FindFirstChild(Names.Templates.Backpack)
	if template and torso then
		local backpack = template:Clone()
		local body = backpack.PrimaryPart
		local mount = body:FindFirstChild("Mount")
		local offset = GameConfig.Backpack.Offset
		backpack:PivotTo(torso.CFrame * CFrame.new(offset.X, offset.Y, torso.Size.Z / 2 + offset.Z))
		mount.Part0 = torso
		mount.C0 = CFrame.new(offset.X, offset.Y, torso.Size.Z / 2 + offset.Z)
		backpack.Parent = character
		self.Blocks[player] = backpack
	end
	self:ApplyCosmetics(player)
	self:UpdateVisual(player)
end

function CarryService:ApplyCosmetics(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end
	local owns = MonetizationService:OwnsPass(player, "GoldenGoose")
	character:SetAttribute(Names.Attributes.GoldenGoose, owns)
	local existing = rootPart:FindFirstChild(Names.Templates.GooseAura)
	if owns and not existing then
		local aura = templates:FindFirstChild(Names.Templates.GooseAura)
		if aura then
			aura:Clone().Parent = rootPart
		end
	elseif not owns and existing then
		existing:Destroy()
	end
end

function CarryService:UpdateVisual(player)
	local runtime = StateService:Get(player)
	local character = player.Character
	if not character or not runtime then
		return
	end
	character:SetAttribute(Names.Attributes.Carrying, runtime.Carry > 0)
	character:SetAttribute(Names.Attributes.CarryCount, runtime.Carry)
end

return CarryService
