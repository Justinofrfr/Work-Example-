local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UIConfig = require(Shared.Config.UI)
local Signal = require(Shared.Util.Signal)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local PanelController = {
	Current = nil,
	Opened = Signal.new(),
}

local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(Names.Gui.Main)
local panels = gui:WaitForChild("Panels")
local homes = {}

function PanelController:Start()
	for _, panel in panels:GetChildren() do
		homes[panel] = panel.Position
		local close = panel:FindFirstChild("Close", true)
		if close then
			Ui.Feel(close, function()
				self:Close()
			end)
		end
	end
	self:BindFeel(gui)
	gui.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("GuiButton") and descendant:GetAttribute("Feel") then
			task.defer(Ui.Feel, descendant)
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == Names.World.StandPrompt then
			local target = prompt:GetAttribute("Panel")
			if target then
				self:Open(target)
			end
		end
	end)
end

function PanelController:BindFeel(root)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("GuiButton") and descendant:GetAttribute("Feel") and not descendant:IsDescendantOf(gui.Templates) then
			Ui.Feel(descendant)
			descendant.Activated:Connect(function()
				Audio.Play("Click")
			end)
		end
	end
end

function PanelController:Get(name)
	return panels:FindFirstChild(name)
end

function PanelController:Open(name)
	local panel = panels:FindFirstChild(name)
	if not panel then
		return
	end
	if self.Current and self.Current ~= panel then
		self.Current.Visible = false
	end
	self.Current = panel
	panel.Position = homes[panel] or panel.Position
	panel.Visible = true
	local scale = Ui.Scale(panel)
	scale.Scale = UIConfig.Fx.OpenScaleFrom
	Ui.Tween(scale, UIConfig.Fx.OpenTime, { Scale = 1 }, Enum.EasingStyle.Back)
	Audio.Play("Open")
	task.delay(UIConfig.Fx.HeaderShineDelay, function()
		if self.Current == panel then
			Ui.Shine(panel:FindFirstChild("Header"))
		end
	end)
	self.Opened:Fire(name)
end

function PanelController:Close()
	local panel = self.Current
	if not panel then
		return
	end
	self.Current = nil
	Audio.Play("Close")
	local scale = Ui.Scale(panel)
	Ui.Tween(scale, UIConfig.Fx.CloseTime, { Scale = UIConfig.Fx.CloseScale }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
		if self.Current ~= panel then
			panel.Visible = false
		end
	end)
end

function PanelController:Toggle(name)
	if self.Current and self.Current.Name == name then
		self:Close()
	else
		self:Open(name)
	end
end

return PanelController
