local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local GameConfig = require(Shared.Config.Game)
local UIConfig = require(Shared.Config.UI)

local Audio = require(script.Parent.Parent.Util.Audio)

local GiftController = {}

local ClientState
local NotifyController
local remotes
local player
local busy = false

function GiftController:Init(modules, context)
	ClientState = modules.ClientState
	NotifyController = modules.NotifyController
	remotes = context.Remotes
	player = context.Player
end

function GiftController:Start()
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
	pcall(AvatarEditorService.PromptSetFavorite, AvatarEditorService, game.PlaceId, Enum.AvatarItemType.Asset, true)
	if GameConfig.GroupId ~= 0 then
		local ok, inGroup = pcall(player.IsInGroup, player, GameConfig.GroupId)
		if ok and not inGroup then
			pcall(GroupService.PromptJoinAsync, GroupService, GameConfig.GroupId)
		end
	end
	local ok, result = remotes[Names.Remotes.ClaimGift]:InvokeServer()
	busy = false
	if ok then
		NotifyController:Toast(UIConfig.Messages.GiftOk, UIConfig.Colors.Good)
		Audio.Play("Reward")
	elseif result == "Group" then
		NotifyController:Toast(UIConfig.Messages.GiftGroup, UIConfig.Colors.Bad)
		Audio.Play("Error")
	elseif result == "Claimed" then
		NotifyController:Toast(UIConfig.Messages.GiftClaimed)
	end
end

return GiftController
