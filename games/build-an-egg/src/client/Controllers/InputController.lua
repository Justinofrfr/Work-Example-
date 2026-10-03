local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InputConfig = require(Shared.Config.Input)
local Signal = require(Shared.Util.Signal)

local InputController = {
	Gamepad = false,
	ModeChanged = Signal.new(),
}

local PanelController
local EggController
local gui
local hud

local GAMEPAD_INPUTS = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
}

function InputController:Init(modules, context)
	PanelController = modules.PanelController
	EggController = modules.EggController
	gui = context.Gui
	hud = gui:WaitForChild("Hud")
end

function InputController:Start()
	self:SetGamepad(GAMEPAD_INPUTS[UserInputService:GetLastInputType()] == true)
	UserInputService.LastInputTypeChanged:Connect(function(inputType)
		if GAMEPAD_INPUTS[inputType] then
			self:SetGamepad(true)
		elseif inputType == Enum.UserInputType.Keyboard or inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.MouseMovement or inputType == Enum.UserInputType.Touch then
			self:SetGamepad(false)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not GAMEPAD_INPUTS[input.UserInputType] then
			return
		end
		if table.find(InputConfig.CloseKeys, input.KeyCode) and PanelController.Current then
			PanelController:Close()
			GuiService.SelectedObject = nil
			return
		end
		if processed and GuiService.SelectedObject then
			return
		end
		if table.find(InputConfig.HatchKeys, input.KeyCode) and gui.Hatch.Visible then
			EggController:Claim()
			return
		end
		for panel, keys in InputConfig.PanelKeys do
			if table.find(keys, input.KeyCode) then
				PanelController:Toggle(panel)
				return
			end
		end
	end)
	PanelController.Opened:Connect(function(name)
		if self.Gamepad then
			self:SelectFirst(PanelController:Get(name))
		end
	end)
end

function InputController:SetGamepad(enabled)
	if self.Gamepad == enabled then
		return
	end
	self.Gamepad = enabled
	for name, text in InputConfig.GamepadHints do
		local target = name == "Hatch" and gui.Hatch.Button or hud:FindFirstChild(name, true)
		local hint = target and target:FindFirstChild("Hint")
		if hint then
			hint.Visible = enabled
			hint.Text.Text = text
		end
	end
	self.ModeChanged:Fire(enabled)
end

function InputController:SelectFirst(root)
	if not root then
		return
	end
	task.defer(function()
		local best
		for _, descendant in root:GetDescendants() do
			if descendant:IsA("GuiButton") and descendant.Visible and descendant.Selectable and descendant.Name ~= "Close" then
				if not best or descendant.AbsolutePosition.Y < best.AbsolutePosition.Y or (descendant.AbsolutePosition.Y == best.AbsolutePosition.Y and descendant.AbsolutePosition.X < best.AbsolutePosition.X) then
					best = descendant
				end
			end
		end
		GuiService.SelectedObject = best
	end)
end

function InputController:Select(object)
	if self.Gamepad and object then
		GuiService.SelectedObject = object
	end
end

return InputController
