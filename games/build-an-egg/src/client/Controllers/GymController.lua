local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local GymsConfig = require(Shared.Config.Gyms)
local ProductsConfig = require(Shared.Config.Products)
local EffectsConfig = require(Shared.Config.Effects)
local UIConfig = require(Shared.Config.UI)
local Formulas = require(Shared.Util.Formulas)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local GymController = {
	Training = nil,
	LockedKey = nil,
}

local ClientState
local PanelController
local ShopController
local remotes
local player
local loop
local track
local signs = {}

function GymController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	ShopController = modules.ShopController
	remotes = context.Remotes
	player = context.Player
end

function GymController:Start()
	local world = Workspace:WaitForChild(Names.World.Root)
	for _, gym in world:WaitForChild(Names.World.Gyms):GetChildren() do
		local sign = gym:FindFirstChild("Sign")
		local tier = Formulas.GymTier(gym.Name)
		if sign and tier then
			signs[tier.Key] = { Sign = sign, Tier = tier }
		end
	end
	UserInputService.JumpRequest:Connect(function()
		if self.Training then
			remotes[Names.Remotes.GymStop]:FireServer()
		end
	end)
	ClientState.StateChanged:Connect(function(state)
		self:OnState(state)
	end)
	remotes[Names.Remotes.Notify].OnClientEvent:Connect(function(kind, key)
		if kind == "GymLocked" then
			self:ShowLocked(key)
		end
	end)
	local lockedPanel = PanelController:Get("Locked")
	Ui.Feel(lockedPanel.Body.Buy, function()
		if self.LockedKey then
			ShopController:PromptPass(self.LockedKey)
		end
	end)
end

function GymController:OnState(state)
	local training = state.Training
	if training ~= self.Training then
		self.Training = training
		if training then
			if not loop then
				loop = Audio.Loop("TrainLoop")
			end
			if loop then
				loop:Play()
			end
			self:PlayAnimation(training)
		else
			if loop then
				loop:Stop()
			end
			if track then
				track:Stop(0.2)
				track = nil
			end
		end
	end
	for key, entry in signs do
		local unlocked = state.Eggs >= entry.Tier.RequiredEggs or (state.Passes and state.Passes[entry.Tier.PassKey or ""])
		local subtitle = entry.Sign:FindFirstChild("Subtitle", true)
		if subtitle then
			if unlocked then
				subtitle.Text = "UNLOCKED"
				subtitle.TextColor3 = UIConfig.Colors.Good
			elseif entry.Tier.RequiredEggs == math.huge then
				subtitle.Text = "🔒 Gamepass only"
				subtitle.TextColor3 = UIConfig.Colors.Bad
			else
				subtitle.Text = ("🔒 Hatch %d eggs"):format(entry.Tier.RequiredEggs)
				subtitle.TextColor3 = UIConfig.Colors.Bad
			end
		end
	end
end

function GymController:PlayAnimation(stat)
	local animationId = EffectsConfig.GymAnimations and EffectsConfig.GymAnimations[stat]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animationId or animationId == "" or not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, loaded = pcall(animator.LoadAnimation, animator, animation)
	if ok and loaded then
		loaded.Looped = true
		loaded.Priority = Enum.AnimationPriority.Action
		loaded:Play(0.2)
		track = loaded
	end
end

function GymController:ShowLocked(key)
	local tier = Formulas.GymTier(key)
	if not tier then
		return
	end
	self.LockedKey = tier.PassKey
	local panel = PanelController:Get("Locked")
	local body = panel.Body
	if tier.RequiredEggs == math.huge then
		body.Desc.Text = "Unlock with the gamepass!"
	else
		body.Desc.Text = UIConfig.Messages.GymLocked:format(tier.RequiredEggs)
	end
	local pass = tier.PassKey and ProductsConfig.GamePasses[tier.PassKey]
	Ui.SetText(body.Buy, pass and ("UNLOCK R$" .. pass.Price) or "LOCKED")
	panel.Header.Title.Text = tier.Key == "GymAdmin" and "ADMIN GYM" or (tier.Multiplier .. "x GYM")
	PanelController:Open("Locked")
	Audio.Play("Locked")
	task.spawn(Ui.Shake, body.Lock)
end

return GymController
