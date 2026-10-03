local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local GameConfig = require(Shared.Config.Game)
local UIConfig = require(Shared.Config.UI)
local GiftConfig = require(Shared.Config.Gift)
local Format = require(Shared.Util.Format)

local Ui = require(script.Parent.Parent.Util.Ui)

local Audio = require(script.Parent.Parent.Util.Audio)

local GiftController = {}

local ClientState
local NotifyController
local PanelController
local PurchaseFxController
local remotes
local player
local busy = false

function GiftController:Init(modules, context)
	ClientState = modules.ClientState
	NotifyController = modules.NotifyController
	PanelController = modules.PanelController
	PurchaseFxController = modules.PurchaseFxController
	remotes = context.Remotes
	player = context.Player
end

function GiftController:InGroup()
	if GameConfig.GroupId == 0 then
		return true
	end
	local ok, inGroup = pcall(player.IsInGroup, player, GameConfig.GroupId)
	return ok and inGroup
end

function GiftController:PromptGroup()
	if self.Joined or self:InGroup() then
		return
	end
	local ok, status = pcall(GroupService.PromptJoinAsync, GroupService, GameConfig.GroupId)
	if ok and status == Enum.GroupMembershipStatus.Joined then
		self.Joined = true
	end
end

function GiftController:Start()
	task.spawn(function()
		task.wait(GiftConfig.GroupPrompt.First)
		while true do
			if not self.Joined and not self:InGroup() and not PanelController.Current then
				self:PromptGroup()
			end
			task.wait(GiftConfig.GroupPrompt.Every)
		end
	end)
	local body = PanelController:Get("GiftReward").Body
	Ui.Feel(body.Collect, function()
		PanelController:Close()
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == Names.World.GiftPrompt then
			self:Claim()
		end
	end)
end

function GiftController:Claim()
	if busy then
		return
	end
	local state = ClientState.State
	if state and state.GiftClaimed then
		NotifyController:Toast(UIConfig.Messages.GiftClaimed)
		return
	end
	busy = true
	local favorited = false
	local connection = AvatarEditorService.PromptSetFavoriteCompleted:Connect(function()
		favorited = true
	end)
	pcall(AvatarEditorService.PromptSetFavorite, AvatarEditorService, game.PlaceId, Enum.AvatarItemType.Asset, true)
	local started = os.clock()
	while not favorited and os.clock() - started < GiftConfig.FavoriteWait do
		task.wait(0.2)
	end
	connection:Disconnect()
	self:PromptGroup()
	local ok, result = remotes[Names.Remotes.ClaimGift]:InvokeServer()
	busy = false
	if ok then
		Audio.Play("Reward")
		self:ShowRewards(result)
	elseif result == "Group" then
		NotifyController:Toast(UIConfig.Messages.GiftGroup, UIConfig.Colors.Bad)
	elseif result == "Claimed" then
		NotifyController:Toast(UIConfig.Messages.GiftClaimed)
	end
end

function GiftController:ShowRewards(rewards)
	local body = PanelController:Get("GiftReward").Body
	local lines = {}
	for _, line in GiftConfig.Lines do
		local amount = type(rewards) == "table" and rewards[line.Key] or 0
		if amount and amount > 0 then
			table.insert(lines, line.Icon .. " " .. line.Format:format(Format.Short(amount)))
		end
	end
	body.Rewards.Text = table.concat(lines, "\n")
	PanelController:Open("GiftReward")
	Ui.Pop(body.Collect, 1.15)
	PurchaseFxController:Confetti(UIConfig.Celebrate.GymUnlocked)
end

return GiftController
