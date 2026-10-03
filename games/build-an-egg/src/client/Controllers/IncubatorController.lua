local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local PetsConfig = require(Shared.Config.Pets)
local UIConfig = require(Shared.Config.UI)
local PetRules = require(Shared.Util.PetRules)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)
local PetView = require(script.Parent.Parent.Util.PetView)

local IncubatorController = {
	Mode = "Fragments",
	Selection = {},
	Rows = {},
	Busy = false,
}

local R = PetsConfig.Reveal
local M = PetsConfig.Messages
local ClientState
local PanelController
local NotifyController
local PurchaseFxController
local remotes
local body
local reveal
local choiceTemplate

local function hex(color)
	return ("#%02X%02X%02X"):format(math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

function IncubatorController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	NotifyController = modules.NotifyController
	PurchaseFxController = modules.PurchaseFxController
	remotes = context.Remotes
	body = PanelController:Get("Incubator").Body
	reveal = context.Gui:WaitForChild("Reveal")
	choiceTemplate = context.Gui:WaitForChild("Templates"):WaitForChild("Choice")
end

function IncubatorController:Start()
	Ui.Feel(body.FragmentsTab, function()
		self:SetMode("Fragments")
	end)
	Ui.Feel(body.PetsTab, function()
		self:SetMode("Pets")
	end)
	Ui.Feel(body.Clear, function()
		self.Selection = {}
		self:Render()
	end)
	Ui.Feel(body.Hatch, function()
		self:Hatch()
	end)
	for index = 1, PetsConfig.Inputs do
		Ui.Feel(body.Slots["Slot" .. index], function()
			if self.Selection[index] then
				table.remove(self.Selection, index)
				Audio.Play("Tick")
				self:Render()
			end
		end)
	end
	Ui.Feel(reveal.Collect, function()
		reveal.Visible = false
	end)
	PanelController.Opened:Connect(function(name)
		if name == "Incubator" then
			self.Selection = {}
			self:Render()
		end
	end)
	ClientState.StateChanged:Connect(function()
		if PanelController.Current and PanelController.Current.Name == "Incubator" and not self.Busy then
			self:Render()
		end
	end)
	self:SetMode("Fragments")
end

function IncubatorController:SetMode(mode)
	self.Mode = mode
	self.Selection = {}
	Ui.SetColor(body.FragmentsTab, mode == "Fragments" and Color3.fromRGB(255, 190, 60) or Color3.fromRGB(150, 150, 160))
	Ui.SetColor(body.PetsTab, mode == "Pets" and Color3.fromRGB(255, 190, 60) or Color3.fromRGB(150, 150, 160))
	self:Render()
end

function IncubatorController:SelectedCount(value)
	local count = 0
	for _, item in self.Selection do
		if item == value then
			count += 1
		end
	end
	return count
end

function IncubatorController:SelectionTier()
	local first = self.Selection[1]
	if not first then
		return nil
	end
	if self.Mode == "Fragments" then
		local _, tier = PetRules.ParseFragment(first)
		return tier
	end
	local pet = self:FindPet(first)
	return pet and pet.Rarity
end

function IncubatorController:FindPet(id)
	local state = ClientState.State
	for _, pet in state and state.Pets or {} do
		if pet.Id == id then
			return pet
		end
	end
	return nil
end

function IncubatorController:Entries()
	local state = ClientState.State
	local entries = {}
	if not state then
		return entries
	end
	if self.Mode == "Fragments" then
		for key, count in state.Fragments or {} do
			local collection, tier = PetRules.ParseFragment(key)
			if collection and count > 0 then
				table.insert(entries, { Value = key, Collection = collection, Tier = tier, Count = count - self:SelectedCount(key) })
			end
		end
	else
		for _, pet in state.Pets or {} do
			if not table.find(self.Selection, pet.Id) and pet.Rarity < #PetsConfig.Rarities then
				table.insert(entries, { Value = pet.Id, Collection = pet.Collection, Tier = pet.Rarity, Count = 1, Pet = pet })
			end
		end
	end
	table.sort(entries, function(a, b)
		if a.Tier ~= b.Tier then
			return a.Tier < b.Tier
		end
		return a.Collection < b.Collection
	end)
	return entries
end

function IncubatorController:Render()
	for _, row in self.Rows do
		row:Destroy()
	end
	self.Rows = {}
	local selectedTier = self:SelectionTier()
	for order, entry in self:Entries() do
		local def = PetsConfig.Collections[entry.Collection]
		local tier = PetsConfig.Rarities[entry.Tier]
		local row = choiceTemplate:Clone()
		row.Name = tostring(entry.Value)
		row.LayoutOrder = order
		row.Visible = true
		row.Swatch.BackgroundColor3 = def.Color
		if entry.Pet then
			row.Title.Text = ("%s (%s)"):format(PetView.Name(entry.Collection, entry.Tier), tier.Key)
		else
			row.Title.Text = ("%s · %s"):format(def.Name, tier.Fragment)
		end
		row.Title.TextColor3 = tier.Color
		row.Sub.Text = def.Stat == "Both" and "Speed & Strength pets" or (def.Stat .. " pets")
		row.Count.Text = entry.Pet and "" or ("x" .. entry.Count)
		local sameTierOnly = self.Mode == "Pets"
		local allowed = entry.Count > 0 and #self.Selection < PetsConfig.Inputs and (not sameTierOnly or not selectedTier or selectedTier == entry.Tier)
		Ui.SetColor(row.Add, allowed and UIConfig.Colors.Good or UIConfig.Colors.Locked)
		Ui.Feel(row.Add, function()
			if allowed then
				table.insert(self.Selection, entry.Value)
				Audio.Play("Tick")
				self:Render()
			end
		end)
		row.Parent = body.Choices
		table.insert(self.Rows, row)
	end
	for index = 1, PetsConfig.Inputs do
		local slot = body.Slots["Slot" .. index]
		local value = self.Selection[index]
		local collection
		if value then
			if self.Mode == "Fragments" then
				collection = PetRules.ParseFragment(value)
			else
				local pet = self:FindPet(value)
				collection = pet and pet.Collection
			end
		end
		local def = collection and PetsConfig.Collections[collection]
		Ui.SetText(slot, def and def.Name or "+")
		Ui.SetColor(slot, def and def.Color or Color3.fromRGB(120, 110, 100))
	end
	self:RenderOdds(selectedTier)
end

function IncubatorController:RenderOdds(selectedTier)
	if #self.Selection == 0 then
		body.Odds.Text = self.Mode == "Fragments" and "Add any 5 fragments.\nEach one adds its pet to the odds!" or "Add 5 pets of the same rarity to trade up\nfor one pet of the next rarity!"
		Ui.SetColor(body.Hatch, UIConfig.Colors.Locked)
		return
	end
	if self.Mode == "Fragments" then
		self:RenderFragmentOdds()
		return
	end
	local resultTier = selectedTier + 1
	local tier = PetsConfig.Rarities[resultTier]
	local collections = {}
	for _, value in self.Selection do
		if self.Mode == "Fragments" then
			table.insert(collections, (PetRules.ParseFragment(value)))
		else
			local pet = self:FindPet(value)
			if pet then
				table.insert(collections, pet.Collection)
			end
		end
	end
	local lines = { ('Result: <font color="%s">%s pet</font>'):format(hex(tier.Color), tier.Key) }
	local odds = PetRules.CollectionOdds(collections)
	local keys = {}
	for collection in odds do
		table.insert(keys, collection)
	end
	table.sort(keys, function(a, b)
		return odds[a] > odds[b]
	end)
	for _, collection in keys do
		local def = PetsConfig.Collections[collection]
		table.insert(lines, ('<font color="%s">%s</font> %d%% · %s'):format(hex(def.Color), PetRules.DisplayName(collection, resultTier), math.floor(odds[collection] * 100 + 0.5), PetRules.BoostText(collection, resultTier)))
	end
	table.insert(lines, ("%d/%d picked"):format(#self.Selection, PetsConfig.Inputs))
	body.Odds.Text = table.concat(lines, "\n")
	Ui.SetColor(body.Hatch, #self.Selection == PetsConfig.Inputs and Color3.fromRGB(190, 110, 255) or UIConfig.Colors.Locked)
end

function IncubatorController:RenderFragmentOdds()
	local share = {}
	local order = {}
	for _, value in self.Selection do
		if not share[value] then
			table.insert(order, value)
		end
		share[value] = (share[value] or 0) + 1 / PetsConfig.Inputs
	end
	table.sort(order, function(a, b)
		return share[a] > share[b]
	end)
	local lines = { "Possible pets:" }
	for _, value in order do
		local collection, tierIndex = PetRules.ParseFragment(value)
		local tier = PetsConfig.Rarities[tierIndex]
		table.insert(lines, ('<font color="%s">%s %s</font> %d%% · %s'):format(hex(tier.Color), tier.Key, PetRules.DisplayName(collection, tierIndex), math.floor(share[value] * 100 + 0.5), PetRules.BoostText(collection, tierIndex)))
	end
	table.insert(lines, ("%d/%d picked"):format(#self.Selection, PetsConfig.Inputs))
	body.Odds.Text = table.concat(lines, "\n")
	Ui.SetColor(body.Hatch, #self.Selection == PetsConfig.Inputs and Color3.fromRGB(190, 110, 255) or UIConfig.Colors.Locked)
end

function IncubatorController:Hatch()
	if self.Busy then
		return
	end
	if #self.Selection ~= PetsConfig.Inputs then
		NotifyController:Toast(M.NeedFive, UIConfig.Colors.Bad)
		return
	end
	self.Busy = true
	local ok, result = remotes[Names.Remotes.Incubate]:InvokeServer(self.Mode, self.Selection)
	self.Selection = {}
	if ok and type(result) == "table" then
		PanelController:Close()
		self:Reveal(result)
	else
		Audio.Play("PurchaseFail")
		NotifyController:Toast(result == "PetsFull" and M.PetsFull or M.NeedFive, UIConfig.Colors.Bad)
	end
	self.Busy = false
	self:Render()
end

function IncubatorController:Reveal(pet)
	local tier = PetsConfig.Rarities[pet.Rarity]
	reveal.Visible = true
	reveal.View.Visible = false
	reveal.Rarity.Visible = false
	reveal.PetName.Visible = false
	reveal.Boost.Visible = false
	reveal.Collect.Visible = false
	reveal.Egg.Visible = true
	reveal.Egg.TextColor3 = tier.Color
	local started = os.clock()
	while os.clock() - started < R.ShakeTime do
		local progress = (os.clock() - started) / R.ShakeTime
		reveal.Egg.Rotation = math.sin(os.clock() * 30) * R.ShakeAngle * progress
		reveal.Egg.Size = UDim2.fromScale(0.3 + progress * 0.08, 0.3 + progress * 0.08)
		if math.random() < 0.15 then
			Audio.Play("Tick")
		end
		RunService.RenderStepped:Wait()
	end
	reveal.Egg.Visible = false
	reveal.Egg.Rotation = 0
	reveal.Egg.Size = UDim2.fromScale(0.3, 0.3)
	local model = PetView.Show(reveal.View, pet.Collection, pet.Rarity)
	reveal.View.Visible = true
	reveal.Rarity.Text = string.upper(tier.Key)
	reveal.Rarity.TextColor3 = tier.Color
	reveal.PetName.Text = PetView.Name(pet.Collection, pet.Rarity)
	reveal.Boost.Text = PetRules.BoostText(pet.Collection, pet.Rarity)
	for _, element in { reveal.Rarity, reveal.PetName, reveal.Boost, reveal.Collect } do
		element.Visible = true
	end
	Ui.Pop(reveal.Collect, 1.15)
	PurchaseFxController:Confetti(R.Confetti + pet.Rarity * 10)
	Audio.Play(pet.Rarity >= 4 and "Victory" or "Prize")
	if model then
		local base = model:GetPivot()
		task.spawn(function()
			local spinStart = os.clock()
			while reveal.Visible and model.Parent do
				model:PivotTo(base * CFrame.Angles(0, math.rad((os.clock() - spinStart) * R.Spin), 0))
				RunService.RenderStepped:Wait()
			end
		end)
	end
end

return IncubatorController
