local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local GameConfig = require(Shared.Config.Game)
local InputConfig = require(Shared.Config.Input)
local Formulas = require(Shared.Util.Formulas)
local EggShape = require(Shared.Util.EggShape)

local Ui = require(script.Parent.Parent.Util.Ui)

local InteractController = {
	Mode = nil,
	HoldingKey = false,
	HoldingButton = false,
	LastFire = 0,
	LastPrompt = 0,
}

local W = Names.World
local ClientState
local remotes
local player
local button
local dropButton
local pileFolder
local quarryZone
local prompts = {}

function InteractController:Init(modules, context)
	ClientState = modules.ClientState
	remotes = context.Remotes
	player = context.Player
	button = context.Gui:WaitForChild("Hud"):WaitForChild("Interact")
	dropButton = context.Gui.Hud:WaitForChild("DropButton")
end

function InteractController:Start()
	local world = Workspace:WaitForChild(W.Root)
	quarryZone = world:WaitForChild(W.Quarry):WaitForChild(W.QuarryZone)
	pileFolder = world:WaitForChild(W.Piles)
	world:WaitForChild(W.Site):WaitForChild(W.Band)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			self.HoldingButton = false
		end
	end)
	for _, descendant in world:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and (descendant.Name == W.PickupPrompt or descendant.Name == W.PlacePrompt) then
			table.insert(prompts, descendant)
		end
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == W.PickupPrompt or prompt.Name == W.PlacePrompt or prompt.Name == "PilePrompt" then
			self.LastPrompt = os.clock()
			self:Fire(true)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if table.find(InputConfig.InteractKeys, input.KeyCode) and not processed then
			self.HoldingKey = true
			if input.KeyCode == Enum.KeyCode.ButtonR2 and self.Mode then
				self.LastPrompt = os.clock()
				self:Fire(true)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if table.find(InputConfig.InteractKeys, input.KeyCode) then
			self.HoldingKey = false
		end
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.HoldingButton = true
			self:Fire(true)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.HoldingButton = false
		end
	end)
	ClientState.StateChanged:Connect(function(state)
		self:TunePrompts(state)
		dropButton.Visible = UserInputService.TouchEnabled and state.Carry > 0
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and table.find(InputConfig.DropKeys, input.KeyCode) then
			remotes[Names.Remotes.Drop]:FireServer()
		end
	end)
	dropButton.Activated:Connect(function()
		remotes[Names.Remotes.Drop]:FireServer()
	end)
	if ClientState.State then
		self:TunePrompts(ClientState.State)
	end
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= 0.15 then
			accumulator = 0
			self:UpdateMode()
		end
		local repeating = self.HoldingButton or (self.HoldingKey and os.clock() - self.LastPrompt < 30)
		if repeating and self.Mode then
			self:Fire(false)
		end
	end)
end

function InteractController:Interval()
	if ClientState:OwnsPass("GoldenGoose") then
		return GameConfig.ActionCooldownFloor + 0.05
	end
	return self.Mode == "Place" and GameConfig.PlaceRepeat or GameConfig.PickupRepeat
end

function InteractController:Fire(immediate)
	local now = os.clock()
	if not immediate and now - self.LastFire < self:Interval() then
		return
	end
	if immediate and now - self.LastFire < GameConfig.ActionCooldownFloor then
		return
	end
	self.LastFire = now
	remotes[Names.Remotes.Interact]:FireServer()
end

function InteractController:NearPile(position)
	if not pileFolder then
		return false
	end
	for _, pile in pileFolder:GetChildren() do
		if pile:IsA("BasePart") and (pile.Position - position).Magnitude <= GameConfig.BasePromptDistance then
			return true
		end
	end
	return false
end

function InteractController:InQuarry(position)
	local localPosition = quarryZone.CFrame:PointToObjectSpace(position)
	local half = quarryZone.Size / 2
	local reach = GameConfig.BasePromptDistance
	return math.abs(localPosition.X) <= half.X + reach and math.abs(localPosition.Y) <= half.Y + reach and math.abs(localPosition.Z) <= half.Z + reach
end

function InteractController:UpdateMode()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local state = ClientState.State
	local server = ClientState.Server
	local mode
	if rootPart and state and not state.Training then
		if self:NearPile(rootPart.Position) and state.Carry < state.Capacity then
			mode = "Pickup"
		elseif self:InQuarry(rootPart.Position) then
			mode = "Pickup"
		elseif server and server.Phase == "Building" and state.Carry > 0 then
			local reach = 1 + Formulas.UpgradeValue("Range", state.Upgrades.Range or 0)
			if EggShape.InBand(rootPart.Position, server.Ring, reach, 0) then
				mode = "Place"
			end
		end
	end
	if mode ~= self.Mode then
		self.Mode = mode
		Ui.SetText(button, mode == "Place" and "PLACE" or "PICK UP")
		if button:FindFirstChild("Icon") then
			button.Icon.Text = mode == "Place" and "🧱" or "✋"
		end
	end
	button.Visible = UserInputService.TouchEnabled and mode ~= nil
	if not button.Visible then
		self.HoldingButton = false
	end
end

function InteractController:TunePrompts(state)
	local goose = ClientState:OwnsPass("GoldenGoose")
	local range = Formulas.PromptDistance(state.Upgrades and state.Upgrades.Range or 0)
	for _, prompt in prompts do
		prompt.GamepadKeyCode = InputConfig.PromptGamepadKey
		if prompt.Name == W.PickupPrompt then
			prompt.HoldDuration = goose and 0 or GameConfig.PickupHoldTime
		else
			prompt.HoldDuration = goose and 0 or GameConfig.PlaceHoldTime
			prompt.MaxActivationDistance = range
			prompt.Enabled = state.Carry > 0
		end
	end
end

return InteractController
