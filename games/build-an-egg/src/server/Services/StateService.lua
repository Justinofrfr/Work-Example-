local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local ProductsConfig = require(Shared.Config.Products)
local Names = require(Shared.Config.Names)
local Formulas = require(Shared.Util.Formulas)

local StateService = {
	Runtime = {},
}

local DataService
local MonetizationService
local remotes

function StateService:Init(modules, context)
	DataService = modules.DataService
	MonetizationService = modules.MonetizationService
	remotes = context.Remotes
end

function StateService:Start()
	DataService.Loaded:Connect(function(player, data)
		self.Runtime[player] = {
			Carry = 0,
			Training = nil,
			LastPickup = 0,
			LastPlace = 0,
			Dirty = true,
		}
		self:BuildLeaderstats(player, data)
		player.CharacterAdded:Connect(function(character)
			self:OnCharacter(player, character)
		end)
		if player.Character then
			self:OnCharacter(player, player.Character)
		end
	end)
	DataService.Releasing:Connect(function(player)
		self.Runtime[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.StateSyncInterval)
			for player, runtime in self.Runtime do
				if runtime.Dirty then
					runtime.Dirty = false
					self:Sync(player)
				end
			end
		end
	end)
end

function StateService:Get(player)
	return self.Runtime[player]
end

function StateService:Dirty(player)
	local runtime = self.Runtime[player]
	if runtime then
		runtime.Dirty = true
	end
	self:RefreshLeaderstats(player)
end

function StateService:BoostMultiplier(player, stat)
	local data = DataService:Get(player)
	if not data then
		return 1
	end
	local key = stat .. "Boost"
	local product = ProductsConfig.DevProducts[key]
	local level = data.BoostLevels[key] or 0
	if not product then
		return 1
	end
	return 1 + (product.Multiplier - 1) * level
end

function StateService:AwardStat(player, stat, amount)
	local data = DataService:Get(player)
	if not data or (stat ~= "Speed" and stat ~= "Strength") then
		return
	end
	local gain = amount * self:BoostMultiplier(player, stat)
	data[stat] += gain
	DataService:MarkDirty(player)
	if stat == "Speed" then
		self:ApplyWalkSpeed(player)
	end
	self:Dirty(player)
end

function StateService:Grant(player, rewards)
	local data = DataService:Get(player)
	if not data then
		return false
	end
	for field, amount in rewards do
		if type(data[field]) == "number" then
			data[field] += amount
		end
	end
	DataService:MarkDirty(player)
	self:ApplyWalkSpeed(player)
	self:Dirty(player)
	return true
end

function StateService:Capacity(player)
	local data = DataService:Get(player)
	return data and Formulas.Capacity(data.Strength) or 1
end

function StateService:ApplyWalkSpeed(player)
	local data = DataService:Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if data and humanoid then
		humanoid.WalkSpeed = Formulas.WalkSpeed(data.Speed)
	end
end

function StateService:OnCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	local runtime = self.Runtime[player]
	if runtime then
		runtime.Carry = 0
		runtime.Training = nil
	end
	self:ApplyWalkSpeed(player)
	self:ApplyRankTag(player, character)
	self:Dirty(player)
end

function StateService:ApplyRankTag(player, character)
	local data = DataService:Get(player)
	local templates = ReplicatedStorage:FindFirstChild(Names.Templates.Folder)
	local template = templates and templates:FindFirstChild(Names.Templates.RankTag)
	local head = character and character:FindFirstChild("Head")
	if not data or not template or not head then
		return
	end
	local existing = head:FindFirstChild(Names.Templates.RankTag)
	local tag = existing or template:Clone()
	local rank = Formulas.Rank(data.Eggs)
	local label = tag:FindFirstChild("Title", true)
	if label and label:IsA("TextLabel") then
		label.Text = rank.Name
		label.TextColor3 = rank.Color
	end
	tag.Parent = head
end

function StateService:BuildLeaderstats(player, data)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	for _, field in { "Eggs", "PiecesPlaced", "Speed", "Strength" } do
		local value = Instance.new("NumberValue")
		value.Name = field == "PiecesPlaced" and "Pieces" or field
		value.Value = math.floor(data[field])
		value:SetAttribute("Field", field)
		value.Parent = folder
	end
	folder.Parent = player
end

function StateService:RefreshLeaderstats(player)
	local data = DataService:Get(player)
	local folder = player:FindFirstChild("leaderstats")
	if not data or not folder then
		return
	end
	for _, value in folder:GetChildren() do
		local field = value:GetAttribute("Field")
		if field and type(data[field]) == "number" then
			value.Value = math.floor(data[field])
		end
	end
end

function StateService:Sync(player)
	local data = DataService:Get(player)
	local runtime = self.Runtime[player]
	if not data or not runtime then
		return
	end
	local rank = Formulas.Rank(data.Eggs)
	remotes[Names.Remotes.StateSync]:FireClient(player, {
		Coins = data.Coins,
		Speed = data.Speed,
		Strength = data.Strength,
		Eggs = data.Eggs,
		PiecesPlaced = data.PiecesPlaced,
		Carry = runtime.Carry,
		Capacity = Formulas.Capacity(data.Strength),
		Upgrades = data.Upgrades,
		BoostLevels = data.BoostLevels,
		GiftClaimed = data.GiftClaimed,
		Training = runtime.Training,
		Rank = rank.Name,
		Passes = MonetizationService:OwnedPasses(player),
	})
end

Players.PlayerRemoving:Connect(function(player)
	StateService.Runtime[player] = nil
end)

return StateService
