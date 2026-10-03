local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local TutorialConfig = require(Shared.Config.Tutorial)
local UpgradesConfig = require(Shared.Config.Upgrades)
local PetsConfig = require(Shared.Config.Pets)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local TutorialController = {
	Step = nil,
	Active = false,
}

local W = Names.World
local ClientState
local PanelController
local CutsceneController
local InteractController
local EggController
local IncubatorController
local remotes
local player
local gui
local frame
local templates
local guideTarget
local guideBeam
local playerAttachment

function TutorialController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	CutsceneController = modules.CutsceneController
	InteractController = modules.InteractController
	EggController = modules.EggController
	IncubatorController = modules.IncubatorController
	remotes = context.Remotes
	player = context.Player
	gui = context.Gui
end

function TutorialController:Start()
	frame = gui:WaitForChild("Tutorial")
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
	Ui.Feel(frame.Card.Skip, function()
		self:Finish(true)
	end)
	PanelController.Opened:Connect(function(name)
		self.LastPanel = name
	end)
	local function begin(state)
		if self.Step or not state then
			return
		end
		local saved = state.TutorialStep or 0
		if saved >= #TutorialConfig.Steps then
			self.Step = #TutorialConfig.Steps + 1
			return
		end
		self.Step = saved + 1
		self.BasePlaced = state.PiecesPlaced or 0
		local skipped = false
		while self:CurrentDef() and self:IsDone(self:CurrentDef()) do
			self.Step += 1
			skipped = true
		end
		if skipped then
			remotes[Names.Remotes.Tutorial]:FireServer(self.Step - 1)
		end
		if self.Step > #TutorialConfig.Steps then
			return
		end
		task.spawn(function()
			while CutsceneController.Playing do
				task.wait(0.2)
			end
			self:ShowStep()
		end)
	end
	ClientState.StateChanged:Connect(begin)
	begin(ClientState.State)
	RunService.RenderStepped:Connect(function()
		if self.Active then
			self:Update()
		end
	end)
end

function TutorialController:CurrentDef()
	return self.Step and TutorialConfig.Steps[self.Step]
end

function TutorialController:WorldTarget(name)
	local world = Workspace:FindFirstChild(W.Root)
	if not world then
		return nil
	end
	if name == "Quarry" then
		local zone = world:FindFirstChild(W.Quarry) and world.Quarry:FindFirstChild(W.QuarryZone)
		return zone and zone.Position
	elseif name == "Shell" then
		local quarry = world:FindFirstChild(W.Quarry)
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local best, bestDistance
		for _, prompt in quarry and quarry:GetDescendants() or {} do
			if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent:IsA("BasePart") then
				local distance = root and (prompt.Parent.Position - root.Position).Magnitude or 0
				if not best or distance < bestDistance then
					best, bestDistance = prompt.Parent, distance
				end
			end
		end
		return best and best.Position
	elseif name == "PlaceZone" then
		local band = world:FindFirstChild(W.Site) and world.Site:FindFirstChild(W.Band)
		local zone = band and band:FindFirstChild("PlaceZone")
		return zone and zone.Position
	elseif name == "Band" then
		local band = world:FindFirstChild(W.Site) and world.Site:FindFirstChild(W.Band)
		local point = band and band:FindFirstChild("Point1")
		return point and point.Position
	elseif name == "UpgradesNPC" then
		local npc = world:FindFirstChild(W.NPCs) and world.NPCs:FindFirstChild("Upgrades")
		local root = npc and npc:FindFirstChild("HumanoidRootPart")
		return root and root.Position
	elseif name == "Gym" then
		local gym = world:FindFirstChild(W.Gyms) and world.Gyms:FindFirstChild("Gym1")
		if gym then
			for _, descendant in gym:GetDescendants() do
				if descendant.Name == W.Pad and descendant:GetAttribute(Names.Attributes.Stat) == "Speed" then
					return descendant.Position
				end
			end
		end
	end
	return nil
end

function TutorialController:GuiTarget(name)
	local hud = gui:FindFirstChild("Hud")
	if name == "Action" then
		if UserInputService.TouchEnabled then
			local interact = hud and hud:FindFirstChild("Interact")
			return interact and interact.Visible and interact or nil
		end
		local hints = hud and hud:FindFirstChild("KeyHints")
		return hints and hints.Visible and hints:FindFirstChild("Pickup") or nil
	elseif name == "UpgradeBuy" then
		local panel = PanelController:Get("Upgrades")
		local list = panel and panel.Visible and panel.Body:FindFirstChild("List")
		local card = list and list:FindFirstChild(UpgradesConfig.Order[1])
		return card and card:FindFirstChild("Buy")
	elseif name == "PetsButton" then
		local topLeft = hud and hud.Visible and hud:FindFirstChild("TopLeft")
		return topLeft and topLeft:FindFirstChild("Pets")
	elseif name == "IncubatorButton" then
		local panel = PanelController:Get("Pets")
		return panel and panel.Visible and panel.Body:FindFirstChild("Incubator") or nil
	elseif name == "IncubatorAdd" or name == "IncubatorHatch" then
		local panel = PanelController:Get("Incubator")
		if not panel or not panel.Visible then
			return nil
		end
		if IncubatorController.Mode ~= "Fragments" then
			return panel.Body:FindFirstChild("FragmentsTab")
		end
		if name == "IncubatorHatch" then
			return panel.Body:FindFirstChild("Hatch")
		end
		return self:FirstCard(panel.Body:FindFirstChild("Choices"), function(row)
			return row.Count.Text ~= "x0"
		end, "Add")
	elseif name == "EquipButton" then
		local panel = PanelController:Get("Pets")
		return panel and panel.Visible and self:FirstCard(panel.Body:FindFirstChild("List"), nil, "Equip") or nil
	end
	return nil
end

function TutorialController:FirstCard(container, filter, buttonName)
	local best
	for _, child in container and container:GetChildren() or {} do
		if child:IsA("GuiObject") and child.Visible and child:FindFirstChild(buttonName) and (not filter or filter(child)) then
			if not best or child.LayoutOrder < best.LayoutOrder then
				best = child
			end
		end
	end
	return best and best[buttonName]
end

function TutorialController:FragmentCount(state)
	local total = 0
	for _, count in state.Fragments or {} do
		total += count
	end
	return total
end

function TutorialController:Waiting(def)
	local state = ClientState.State
	if not def.WaitFor or not state then
		return false
	end
	if def.WaitFor == "Fragments" then
		return #(state.Pets or {}) == 0 and self:FragmentCount(state) < PetsConfig.Inputs
	end
	return false
end

function TutorialController:StageCounts(def)
	local index, total = 0, 0
	for position, other in TutorialConfig.Steps do
		if other.Stage == def.Stage then
			total += 1
			if position <= self.Step then
				index += 1
			end
		end
	end
	return index, total
end

function TutorialController:ShowStep(quiet)
	local def = self:CurrentDef()
	if not def then
		self:Finish(false)
		return
	end
	self.Active = true
	self.BasePlaced = self.BasePlaced or (ClientState.State and ClientState.State.PiecesPlaced or 0)
	self.LastPanel = PanelController.Current and PanelController.Current.Name or nil
	if self:Waiting(def) then
		frame.Visible = false
		quiet = true
	else
		frame.Visible = true
	end
	local card = frame.Card
	card.Step.Text = ("STEP %d/%d"):format(self:StageCounts(def))
	card.Text.Text = (UserInputService.TouchEnabled and def.MobileText) or def.Text
	Ui.Pop(card, 1.08)
	if not quiet then
		Audio.Play("Open")
	end
	if not guideTarget then
		guideTarget = templates.GuideTarget:Clone()
		guideTarget.Parent = Workspace
	end
end

function TutorialController:Complete()
	Audio.Play("Reward")
	remotes[Names.Remotes.Tutorial]:FireServer(self.Step)
	self.Step += 1
	if self.Step > #TutorialConfig.Steps then
		self:Finish(false)
	else
		self:ShowStep(true)
	end
end

function TutorialController:Finish(skipped)
	self.Active = false
	self.Step = #TutorialConfig.Steps + 1
	frame.Visible = false
	if Lighting:FindFirstChild("SpotlightBlur") then
		Lighting.SpotlightBlur.Enabled = false
	end
	if skipped then
		remotes[Names.Remotes.Tutorial]:FireServer(#TutorialConfig.Steps)
	end
	if guideTarget then
		guideTarget:Destroy()
		guideTarget = nil
	end
	if guideBeam then
		guideBeam:Destroy()
		guideBeam = nil
	end
	if playerAttachment then
		playerAttachment:Destroy()
		playerAttachment = nil
	end
end

function TutorialController:IsDone(def)
	local state = ClientState.State
	if not state then
		return false
	end
	local placedSince = state.PiecesPlaced > (self.BasePlaced or state.PiecesPlaced)
	local hasPets = #(state.Pets or {}) > 0
	local current = PanelController.Current and PanelController.Current.Visible and PanelController.Current.Name
	if def.Key == "Quarry" then
		return InteractController.Mode == "Pickup" or state.Carry > 0 or placedSince
	elseif def.Key == "Pickup" then
		return state.Carry > 0 or placedSince
	elseif def.Key == "Carry" then
		return InteractController.Mode == "Place" or placedSince
	elseif def.Key == "Place" then
		return placedSince
	elseif def.Key == "OpenPets" then
		return hasPets or current == "Pets" or current == "Incubator"
	elseif def.Key == "OpenIncubator" then
		return hasPets or current == "Incubator"
	elseif def.Key == "AddFragments" then
		return hasPets or (IncubatorController.Mode == "Fragments" and #IncubatorController.Selection >= PetsConfig.Inputs)
	elseif def.Key == "HatchPet" then
		return hasPets
	elseif def.Key == "EquipPet" then
		return #(state.Equipped or {}) > 0
	elseif def.Key == "OpenUpgrades" or def.Key == "BuyUpgrade" then
		for _, level in state.Upgrades or {} do
			if level > 0 then
				return true
			end
		end
		return def.Key == "OpenUpgrades" and self.LastPanel == "Upgrades"
	elseif def.Key == "Gym" then
		return state.Training ~= nil
	end
	return false
end

function TutorialController:SetSpot(target)
	if not target then
		frame.Hole.Visible = false
		frame.Ring.Visible = false
		frame.Finger.Visible = false
		if Lighting:FindFirstChild("SpotlightBlur") then
			Lighting.SpotlightBlur.Enabled = false
		end
		return
	end
	local origin = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	local pad = TutorialConfig.SpotlightPadding
	local x0 = math.clamp((target.AbsolutePosition.X - origin.X) / size.X - pad, 0, 1)
	local y0 = math.clamp((target.AbsolutePosition.Y - origin.Y) / size.Y - pad, 0, 1)
	local x1 = math.clamp((target.AbsolutePosition.X + target.AbsoluteSize.X - origin.X) / size.X + pad, 0, 1)
	local y1 = math.clamp((target.AbsolutePosition.Y + target.AbsoluteSize.Y - origin.Y) / size.Y + pad, 0, 1)
	frame.Hole.Visible = true
	frame.Hole.Position = UDim2.fromScale(x0, y0)
	frame.Hole.Size = UDim2.fromScale(x1 - x0, y1 - y0)
	if Lighting:FindFirstChild("SpotlightBlur") then
		Lighting.SpotlightBlur.Size = UserInputService.TouchEnabled and TutorialConfig.SpotlightBlurMobile or TutorialConfig.SpotlightBlur
		Lighting.SpotlightBlur.Enabled = true
	end
	frame.Ring.Visible = TutorialConfig.SpotlightRing
	frame.Ring.Position = UDim2.fromScale(x0, y0)
	frame.Ring.Size = UDim2.fromScale(x1 - x0, y1 - y0)
	local bob = math.sin(os.clock() * TutorialConfig.FingerSpeed) * TutorialConfig.FingerBob
	frame.Finger.Visible = true
	local below = y1 < 0.8
	frame.Finger.Rotation = below and 0 or 180
	frame.Finger.AnchorPoint = Vector2.new(0.3, below and 0 or 1)
	frame.Finger.Position = UDim2.fromScale((x0 + x1) / 2, (below and y1 or y0) + (below and bob or -bob))
end

function TutorialController:SetGuide(position, markerHeight)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not position or not root or not guideTarget then
		if guideBeam then
			guideBeam.Enabled = false
		end
		if guideTarget then
			guideTarget.Marker.Enabled = false
		end
		return
	end
	guideTarget.CFrame = CFrame.new(position)
	guideTarget.Marker.Enabled = true
	local height = markerHeight or TutorialConfig.MarkerHeight
	guideTarget.Marker.StudsOffsetWorldSpace = Vector3.new(0, height + math.sin(os.clock() * 4) * math.min(1.5, height * 0.2), 0)
	if not playerAttachment or playerAttachment.Parent ~= root then
		if playerAttachment then
			playerAttachment:Destroy()
		end
		playerAttachment = templates.GuideAttachment:Clone()
		playerAttachment.Parent = root
	end
	if not guideBeam then
		guideBeam = templates.GuideBeam:Clone()
		guideBeam.Parent = guideTarget
	end
	guideBeam.Attachment0 = playerAttachment
	guideBeam.Attachment1 = guideTarget.Target
	guideBeam.Enabled = true
end

function TutorialController:Update()
	local def = self:CurrentDef()
	if not def then
		return
	end
	local reveal = gui:FindFirstChild("Reveal")
	if CutsceneController.Playing or EggController.InCutscene or (reveal and reveal.Visible) or self:Waiting(def) then
		frame.Visible = false
		self:SetSpot(nil)
		self:SetGuide(nil)
		return
	end
	if not frame.Visible then
		frame.Visible = true
		frame.Card.Step.Text = ("STEP %d/%d"):format(self:StageCounts(def))
		frame.Card.Text.Text = (UserInputService.TouchEnabled and def.MobileText) or def.Text
	end
	local panelOpen = not def.NeedsPanel or (PanelController.Current ~= nil and PanelController.Current.Name == def.NeedsPanel and PanelController.Current.Visible)
	local opener
	if def.Target == "Gui" and not panelOpen then
		for _, name in def.OpenGui or {} do
			opener = opener or self:GuiTarget(name)
		end
	end
	if def.Target == "Gui" and panelOpen then
		self:SetSpot(self:GuiTarget(def.Gui))
		self:SetGuide(nil)
	elseif opener then
		self:SetSpot(opener)
		self:SetGuide(nil)
	else
		self:SetSpot(nil)
		self:SetGuide(def.World and self:WorldTarget(def.World) or nil, def.MarkerHeight)
	end
	if self:IsDone(def) then
		self:Complete()
	end
end

return TutorialController
