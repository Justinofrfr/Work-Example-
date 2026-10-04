local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local PetsConfig = require(Shared.Config.Pets)
local UIConfig = require(Shared.Config.UI)
local PetRules = require(Shared.Util.PetRules)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)
local PetView = require(script.Parent.Parent.Util.PetView)

local PetController = {
	Followers = {},
	Cards = {},
	Signature = "",
}

local F = PetsConfig.Follow
local A = Names.Attributes
local ClientState
local PanelController
local NotifyController
local remotes
local hud
local panel
local list
local cardTemplate
local camera = Workspace.CurrentCamera

function PetController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	NotifyController = modules.NotifyController
	remotes = context.Remotes
	hud = context.Gui:WaitForChild("Hud")
	panel = PanelController:Get("Pets")
	list = panel.Body.List
	cardTemplate = context.Gui:WaitForChild("Templates"):WaitForChild("PetCard")
end

function PetController:Start()
	Ui.BindCanvas(PanelController:Get("Pets").Body.List)
	hud.TopLeft.Pets.Activated:Connect(function()
		PanelController:Toggle("Pets")
	end)
	panel.Body.Incubator.Activated:Connect(function()
		PanelController:Open("Incubator")
	end)
	panel.Body.EquipBest.Activated:Connect(function()
		self:Action("EquipBest")
	end)
	ClientState.StateChanged:Connect(function()
		self:Refresh()
	end)
	PanelController.Opened:Connect(function(name)
		if name == "Pets" then
			self:Refresh(true)
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		self:Step(dt)
	end)
end

function PetController:Action(action, id)
	local ok, err = remotes[Names.Remotes.PetAction]:InvokeServer(action, id)
	if not ok and err == "SlotsFull" then
		NotifyController:Toast(("Only %d pets can be equipped"):format(PetsConfig.EquipSlots), UIConfig.Colors.Bad)
	end
	return ok
end

function PetController:Refresh(force)
	local state = ClientState.State
	if not state or not state.Pets then
		return
	end
	local parts = {}
	for _, pet in state.Pets do
		table.insert(parts, pet.Id .. (table.find(state.Equipped, pet.Id) and "e" or ""))
	end
	local signature = table.concat(parts, ",")
	local body = panel.Body
	body.Info.Text = ("Equipped %d/%d"):format(#state.Equipped, PetsConfig.EquipSlots)
	body.Boosts.Text = ("Pet boosts: x%.2f Speed · x%.2f Strength"):format(state.PetSpeed or 1, state.PetStrength or 1)
	body.Empty.Visible = #state.Pets == 0
	if signature == self.Signature and not force then
		return
	end
	self.Signature = signature
	for _, card in self.Cards do
		card:Destroy()
	end
	self.Cards = {}
	local sorted = table.clone(state.Pets)
	table.sort(sorted, function(a, b)
		local ea, eb = table.find(state.Equipped, a.Id) ~= nil, table.find(state.Equipped, b.Id) ~= nil
		if ea ~= eb then
			return ea
		end
		local sa, sb = PetRules.Score(a.Collection, a.Rarity), PetRules.Score(b.Collection, b.Rarity)
		if sa ~= sb then
			return sa > sb
		end
		return a.Id > b.Id
	end)
	for order, pet in sorted do
		local equipped = table.find(state.Equipped, pet.Id) ~= nil
		local tier = PetsConfig.Rarities[pet.Rarity]
		local card = cardTemplate:Clone()
		card.Name = tostring(pet.Id)
		card.LayoutOrder = order
		card.Visible = true
		card.PetName.Text = PetView.Name(pet.Collection, pet.Rarity)
		card.Rarity.Text = tier.Key
		card.Rarity.TextColor3 = tier.Color
		card.Boost.Text = PetRules.BoostText(pet.Collection, pet.Rarity)
		card.EquippedMark.Visible = equipped
		Ui.SetText(card.Equip, equipped and "UNEQUIP" or "EQUIP")
		Ui.SetColor(card.Equip, equipped and UIConfig.Colors.Locked or UIConfig.Colors.Good)
		card.Parent = list
		PetView.Show(card.View, pet.Collection, pet.Rarity)
		Ui.Feel(card.Equip, function()
			Audio.Play("Click")
			self:Action(equipped and "Unequip" or "Equip", pet.Id)
		end)
		Ui.Feel(card.Delete, function()
			Audio.Play("Click")
			self:Action("Delete", pet.Id)
		end)
		table.insert(self.Cards, card)
	end
end

function PetController:Sync(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local wanted = player:GetAttribute(A.Pets) or ""
	local entry = self.Followers[player]
	if entry and (entry.Key ~= wanted or not root) then
		for _, follower in entry.Models do
			follower.Model:Destroy()
		end
		self.Followers[player] = nil
		entry = nil
	end
	if entry or not root or wanted == "" then
		return entry
	end
	entry = { Key = wanted, Models = {} }
	for name in wanted:gmatch("[^,]+") do
		local template = ReplicatedStorage.Pets:FindFirstChild(name)
		if template then
			local model = template:Clone()
			model:PivotTo(root.CFrame)
			model.Parent = Workspace
			table.insert(entry.Models, {
				Model = model,
				Rotation = template:GetPivot().Rotation,
				Flying = model:GetAttribute("Flying") == true,
				Current = root.CFrame,
				Phase = math.random() * math.pi * 2,
			})
		end
	end
	self.Followers[player] = entry
	return entry
end

function PetController:Step(dt)
	local now = os.clock()
	local cameraPosition = camera.CFrame.Position
	local alpha = 1 - math.exp(-F.Lerp * dt)
	for _, player in Players:GetPlayers() do
		local entry = self:Sync(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if entry and root then
			local far = (root.Position - cameraPosition).Magnitude > F.CullDistance
			local count = #entry.Models
			local yaw = CFrame.lookAt(Vector3.zero, Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z))
			for index, follower in entry.Models do
				local lateral = (index - (count + 1) / 2) * F.Spacing
				local offset = root.CFrame * CFrame.new(lateral, 0, F.Distance)
				local bob = math.abs(math.sin(now * F.BobSpeed + follower.Phase)) * F.Bob
				local height = root.Position.Y + F.GroundOffset + bob + (follower.Flying and F.FlyHeight or 0)
				local target = CFrame.new(offset.Position.X, height, offset.Position.Z) * yaw.Rotation * follower.Rotation
				follower.Current = far and target or follower.Current:Lerp(target, alpha)
				follower.Model:PivotTo(follower.Current)
			end
		end
	end
	for player, entry in self.Followers do
		if not player.Parent then
			for _, follower in entry.Models do
				follower.Model:Destroy()
			end
			self.Followers[player] = nil
		end
	end
end

return PetController
