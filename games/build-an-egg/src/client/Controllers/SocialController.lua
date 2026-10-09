local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.Game)
local GiftConfig = require(Shared.Config.Gift)

local Ui = require(script.Parent.Parent.Util.Ui)

local SocialController = {}

local PanelController
local GiftController
local player

function SocialController:Init(modules, context)
	PanelController = modules.PanelController
	GiftController = modules.GiftController
	player = context.Player
end

function SocialController:Start()
	local body = PanelController:Get("Social").Body
	Ui.Feel(body.Favorite, function()
		pcall(AvatarEditorService.PromptSetFavorite, AvatarEditorService, game.PlaceId, Enum.AvatarItemType.Asset, true)
		PanelController:Close()
	end)
	Ui.Feel(body.Group, function()
		PanelController:Close()
		GiftController:PromptGroup()
	end)
	task.spawn(function()
		task.wait(GiftConfig.SocialPrompt.First)
		while player.Parent do
			if not PanelController.Current then
				body.Group.Visible = GameConfig.GroupId ~= 0 and not GiftController:InGroup()
				PanelController:Open("Social")
			end
			task.wait(GiftConfig.SocialPrompt.Every)
		end
	end)
end

return SocialController
