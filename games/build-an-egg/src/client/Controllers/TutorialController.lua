local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local TutorialConfig = require(Shared.Config.Tutorial)

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
local remotes
local player
local gui
local frame
local templates
local guideTarget
local guideBeam
local playerAttachment
local stepStarted = 0

function TutorialController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	CutsceneController = modules.CutsceneController
	InteractController = modules.InteractController
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
	elseif name == "PlaceZone" then
		local band = world:FindFirstChild(W.Site) and world.Site:FindFirstChild(W.Band)
		local zone = band and band:FindFirstChild("PlaceZone")
		return zone and zone.Position
	elseif name == "Band" then
		local band = world:FindFirstChild(W.Site) and world.Site:FindFirstChild(W.Band)
		local point = band and band:FindFirstChild("Point3")
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
	elseif name == "Shop" then
		return hud and hud.Right:FindFirstChild("Shop")
	end
	return nil
end

function TutorialController:ShowStep()
	local def = self:CurrentDef()
	if not def then
		self:Finish(false)
		return
	end
	self.Active = true
	stepStarted = os.clock()
	self.StartPlaced = ClientState.State and ClientState.State.PiecesPlaced or 0
	self.LastPanel = nil
	frame.Visible = true
	local card = frame.Card
	card.Step.Text = ("STEP %d/%d"):format(self.Step, #TutorialConfig.Steps)
	card.Text.Text = (UserInputService.TouchEnabled and def.MobileText) or def.Text
	Ui.Pop(card, 1.08)
	Audio.Play("Open")
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
		self:ShowStep()
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
	if def.Key == "Quarry" then
		return InteractController.Mode == "Pickup"
	elseif def.Key == "Pickup" then
		return state.Carry > 0
	elseif def.Key == "Carry" then
		return InteractController.Mode == "Place" or state.PiecesPlaced > self.StartPlaced
	elseif def.Key == "Place" then
		return state.PiecesPlaced > self.StartPlaced
	elseif def.Key == "Upgrades" then
		if self.LastPanel == "Upgrades" then
			return true
		end
		for _, level in state.Upgrades or {} do
			if level > 0 then
				return true
			end
		end
		return false
	elseif def.Key == "Gym" then
		return state.Training ~= nil
	elseif def.Key == "Shop" then
		return self.LastPanel == "Shop" or (def.AutoAdvance and os.clock() - stepStarted >= def.AutoAdvance)
	end
	return false
end

function TutorialController:SetSpot(target)
	local spots = { frame.Top, frame.Bottom, frame.Left, frame.Right }
	if not target then
		for _, spot in spots do
			spot.Size = UDim2.fromScale(0, 0)
		end
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
	frame.Top.Position = UDim2.fromScale(0, 0)
	frame.Top.Size = UDim2.fromScale(1, y0)
	frame.Bottom.Position = UDim2.fromScale(0, y1)
	frame.Bottom.Size = UDim2.fromScale(1, 1 - y1)
	frame.Left.Position = UDim2.fromScale(0, y0)
	frame.Left.Size = UDim2.fromScale(x0, y1 - y0)
	frame.Right.Position = UDim2.fromScale(x1, y0)
	frame.Right.Size = UDim2.fromScale(1 - x1, y1 - y0)
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

function TutorialController:SetGuide(position)
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
	guideTarget.Marker.StudsOffsetWorldSpace = Vector3.new(0, TutorialConfig.MarkerHeight + math.sin(os.clock() * 4) * 1.5, 0)
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
	if CutsceneController.Playing then
		frame.Visible = false
		return
	end
	frame.Visible = true
	if def.Target == "Gui" then
		self:SetSpot(self:GuiTarget(def.Gui))
	else
		self:SetSpot(nil)
	end
	self:SetGuide(def.World and self:WorldTarget(def.World) or nil)
	if self:IsDone(def) then
		self:Complete()
	end
end

return TutorialController
