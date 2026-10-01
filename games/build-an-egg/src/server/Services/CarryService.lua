local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
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
		remotes[Names.Remotes.Notify]:FireClient(player, "Toast", UIConfig.Messages.DropQuarry)
		return
	end
	local count = 0
	for pile in self.Piles do
		if pile.Parent then
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
	pile.CFrame = CFrame.new(rootPart.Position - Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	self:SetPileCount(pile, amount)
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
	local template = templates:FindFirstChild(Names.Templates.CarryBlock)
	if template then
		local block = template:Clone()
		local weld = block:FindFirstChildOfClass("Weld")
		if weld then
			weld.Part0 = head
			weld.Part1 = block
		end
		block.Parent = character
		self.Blocks[player] = block
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
	local block = self.Blocks[player]
	local runtime = StateService:Get(player)
	if not block or not block.Parent or not runtime then
		return
	end
	local carrying = runtime.Carry > 0
	block.Parent:SetAttribute(Names.Attributes.Carrying, carrying)
	block.Transparency = carrying and 0 or 1
	local size = math.min(GameConfig.CarryBlockBaseSize + GameConfig.CarryBlockGrowth * math.sqrt(runtime.Carry), GameConfig.CarryBlockMaxSize)
	local base = block:GetAttribute("BaseSize") or block.Size
	block:SetAttribute("BaseSize", base)
	block.Size = base.Unit * size * math.sqrt(3)
	local weld = block:FindFirstChildOfClass("Weld")
	local head = weld and weld.Part0
	if weld and head then
		weld.C0 = CFrame.new(0, head.Size.Y / 2 + block.Size.Y / 2 + 0.8, 0)
	end
	local count = block:FindFirstChild("Count")
	if count then
		count.Enabled = carrying
		local label = count:FindFirstChild("Text")
		if label then
			label.Text = tostring(runtime.Carry)
		end
	end
end

return CarryService
