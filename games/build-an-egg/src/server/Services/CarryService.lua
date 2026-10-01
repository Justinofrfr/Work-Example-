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
	Stacks = {},
}

local DataService
local StateService
local MonetizationService
local BuildService
local remotes

local quarryZone
local templates
local limiter = RateLimiter.new(GameConfig.InteractRateLimit, GameConfig.InteractRateWindow)

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
	remotes[Names.Remotes.Interact].OnServerEvent:Connect(function(player)
		if not limiter:Check(player) then
			return
		end
		self:Interact(player)
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
		self.Stacks[player] = nil
	end)
	MonetizationService.PassChanged:Connect(function(player)
		self:ApplyCosmetics(player)
	end)
end

function CarryService:InQuarry(position)
	local localPosition = quarryZone.CFrame:PointToObjectSpace(position)
	local reach = GameConfig.BasePromptDistance + GameConfig.DistanceTolerance
	local half = quarryZone.Size / 2
	return math.abs(localPosition.X) <= half.X + reach and math.abs(localPosition.Y) <= half.Y + reach and math.abs(localPosition.Z) <= half.Z + reach
end

function CarryService:Interact(player)
	local rootPart = rootOf(player)
	local runtime = StateService:Get(player)
	if not rootPart or not runtime or runtime.Training then
		return
	end
	if self:InQuarry(rootPart.Position) then
		self:Pickup(player)
	elseif BuildService:CanPlaceAt(player, rootPart.Position) then
		BuildService:TryPlace(player, rootPart)
	end
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
	local instant = MonetizationService:OwnsPass(player, "GoldenGoose") and ProductsConfig.GamePasses.GoldenGoose.InstantActions
	local cooldown = instant and GameConfig.ActionCooldownFloor or math.max(GameConfig.PickupHoldTime - GameConfig.ActionCooldownSlack, GameConfig.ActionCooldownFloor)
	local clock = os.clock()
	if clock - runtime.LastPickup < cooldown then
		return false
	end
	runtime.LastPickup = clock
	local rootPart = rootOf(player)
	runtime.PickupPosition = rootPart and rootPart.Position or runtime.PickupPosition
	local amount =math.min(Formulas.PickupAmount(data.Upgrades.BulkPickup or 0), capacity - runtime.Carry)
	runtime.Carry += amount
	self:UpdateVisual(player)
	StateService:Dirty(player)
	remotes[Names.Remotes.Effect]:FireClient(player, "Pickup", amount, runtime.Carry >= capacity)
	return true
end

function CarryService:OnCharacter(player, character)
	local torso = character:WaitForChild("UpperTorso", 10) or character:FindFirstChild("Torso")
	if not torso or not templates then
		return
	end
	local stack = templates:FindFirstChild(Names.Templates.CarryStack)
	if stack then
		stack = stack:Clone()
		local root = stack.PrimaryPart
		stack:PivotTo(torso.CFrame * CFrame.new(0, 0.2, torso.Size.Z / 2 + 1.1))
		root:FindFirstChild("Weld").Part1 = torso
		stack.Parent = character
		self.Stacks[player] = stack
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
	local stack = self.Stacks[player]
	local runtime = StateService:Get(player)
	if not stack or not stack.Parent or not runtime then
		return
	end
	local shown = math.min(runtime.Carry, GameConfig.CarryVisualMax)
	if stack.Parent then
		stack.Parent:SetAttribute(Names.Attributes.Carrying, runtime.Carry > 0)
	end
	for _, piece in stack.Pieces:GetChildren() do
		local index = tonumber(piece.Name) or 0
		piece.Transparency = index <= shown and 0 or 1
	end
	local count = stack.PrimaryPart:FindFirstChild("Count")
	if count then
		count.Enabled = runtime.Carry > 0
		local label = count:FindFirstChild("Text")
		if label then
			label.Text = tostring(runtime.Carry)
		end
		count.StudsOffsetWorldSpace = Vector3.new(0, shown * 1.15 + 2, 0)
	end
end

return CarryService
