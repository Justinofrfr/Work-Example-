local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIConfig = require(Shared.Config.UI)

local Ui = require(script.Parent.Parent.Util.Ui)
local Settings = require(script.Parent.Parent.Util.Settings)

local SettingsController = {}

local list
local templates

local function display(value)
	if value == true then
		return "ON", UIConfig.Colors.Good
	elseif value == false then
		return "OFF", UIConfig.Colors.Bad
	end
	return string.upper(tostring(value)), value == "Off" and UIConfig.Colors.Bad or UIConfig.Colors.Speed
end

function SettingsController:Init(modules, context)
	list = modules.PanelController:Get("Settings").Body.List
	templates = context.Gui:WaitForChild("Templates")
end

function SettingsController:Start()
	for index, key in Settings.Order do
		local row = templates.Toggle:Clone()
		row.Visible = true
		row.Name = key
		row.LayoutOrder = index
		row.Title.Text = Settings.Labels[key]
		row.Parent = list
		local function render()
			local text, color = display(Settings:Get(key))
			Ui.SetText(row.Button, text)
			Ui.SetColor(row.Button, color)
		end
		render()
		Ui.Feel(row.Button, function()
			Settings:Toggle(key)
			render()
		end)
	end
end

return SettingsController
