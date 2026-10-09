local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UIConfig = require(Shared.Config.UI)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local CodesController = {}

local PanelController
local remotes
local body
local busy = false

local messages = {
	Invalid = UIConfig.Messages.CodeInvalid,
	Claimed = UIConfig.Messages.CodeClaimed,
	Expired = UIConfig.Messages.CodeExpired,
	Busy = UIConfig.Messages.CodeBusy,
}

function CodesController:Init(modules, context)
	PanelController = modules.PanelController
	remotes = context.Remotes
	body = PanelController:Get("Codes").Body
end

function CodesController:Start()
	body.Redeem.Activated:Connect(function()
		self:Redeem()
	end)
	body.Input.FocusLost:Connect(function(enter)
		if enter then
			self:Redeem()
		end
	end)
end

function CodesController:Redeem()
	local text = body.Input.Text
	if busy or text == "" then
		return
	end
	busy = true
	body.Status.Text = "..."
	body.Status.TextColor3 = Color3.new(1, 1, 1)
	local ok, result = remotes[Names.Remotes.RedeemCode]:InvokeServer(text)
	busy = false
	if ok then
		body.Status.Text = UIConfig.Messages.CodeOk
		body.Status.TextColor3 = UIConfig.Colors.Good
		body.Input.Text = ""
		Audio.Play("Reward")
		Ui.Pop(body.Input, 1.05)
	else
		body.Status.Text = messages[result] or UIConfig.Messages.CodeInvalid
		body.Status.TextColor3 = UIConfig.Colors.Bad
		Audio.Play("Error")
		task.spawn(Ui.Shake, body.Input)
	end
end

return CodesController
