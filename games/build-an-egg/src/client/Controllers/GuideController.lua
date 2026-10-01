local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local TutorialConfig = require(Shared.Config.Tutorial)

local GuideController = {}

local W = Names.World
local ClientState
local TutorialController
local InteractController
local player
local templates
local target
local beam
local attachment

function GuideController:Init(modules, context)
	ClientState = modules.ClientState
	TutorialController = modules.TutorialController
	InteractController = modules.InteractController
	player = context.Player
end

function GuideController:Start()
	templates = ReplicatedStorage:WaitForChild(Names.Templates.Folder)
	RunService.Heartbeat:Connect(function()
		self:Update()
	end)
end

function GuideController:Destination()
	local state = ClientState.State
	local server = ClientState.Server
	local world = Workspace:FindFirstChild(W.Root)
	if not state or not server or not world or state.Training then
		return nil
	end
	if state.Carry > 0 and server.Phase == "Building" then
		if InteractController.Mode == "Place" then
			return nil
		end
		local zone = world:FindFirstChild(W.Site) and world.Site:FindFirstChild(W.Band) and world.Site.Band:FindFirstChild("PlaceZone")
		return zone and zone.Position
	end
	if state.Carry == 0 and state.PiecesPlaced < TutorialConfig.GuideNewPlayerPieces and InteractController.Mode ~= "Pickup" then
		local zone = world:FindFirstChild(W.Quarry) and world.Quarry:FindFirstChild(W.QuarryZone)
		return zone and zone.Position
	end
	return nil
end

function GuideController:Update()
	local destination = not TutorialController.Active and self:Destination() or nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not destination or not root then
		if beam then
			beam.Enabled = false
		end
		if target then
			target.Marker.Enabled = false
		end
		return
	end
	if not target then
		target = templates.GuideTarget:Clone()
		target.Marker.Enabled = false
		target.Parent = Workspace
	end
	target.CFrame = CFrame.new(destination)
	if not attachment or attachment.Parent ~= root then
		if attachment then
			attachment:Destroy()
		end
		attachment = templates.GuideAttachment:Clone()
		attachment.Parent = root
	end
	if not beam then
		beam = templates.GuideBeam:Clone()
		beam.Parent = target
	end
	beam.Attachment0 = attachment
	beam.Attachment1 = target.Target
	beam.Enabled = true
end

return GuideController
