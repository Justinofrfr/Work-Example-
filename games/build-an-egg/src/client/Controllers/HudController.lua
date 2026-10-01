local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIConfig = require(Shared.Config.UI)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local HudController = {}

local ClientState
local PanelController
local gui
local hud
local progress
local shown = {}

function HudController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	gui = context.Gui
	hud = gui:WaitForChild("Hud")
	progress = hud:WaitForChild("Progress")
end

function HudController:Start()
	for _, name in { "Codes", "Settings" } do
		hud.TopLeft[name].Activated:Connect(function()
			PanelController:Toggle(name)
		end)
	end
	for _, name in { "Shop", "Upgrades" } do
		hud.Right[name].Activated:Connect(function()
			PanelController:Toggle(name)
		end)
	end
	ClientState.StateChanged:Connect(function(state, previous)
		self:RenderState(state, previous)
	end)
	ClientState.ServerChanged:Connect(function(server, previous)
		self:RenderServer(server, previous)
	end)
	RunService.Heartbeat:Connect(function()
		self:RenderTimer()
	end)
	task.spawn(function()
		local shine = progress.Bar.Shine
		while true do
			task.wait(UIConfig.BarShineInterval)
			shine.Position = UDim2.fromScale(-0.2, 0)
			Ui.Tween(shine, 0.8, { Position = UDim2.fromScale(1.1, 0) }, Enum.EasingStyle.Sine)
		end
	end)
end

function HudController:SetStat(name, value)
	local row = hud.Stats:FindFirstChild(name)
	if not row then
		return
	end
	local old = shown[name]
	shown[name] = value
	row.Value.Text = Format.Short(value)
	if old and value > old then
		Ui.Pop(row.Value)
		if name ~= "Coins" and math.floor(math.log10(math.max(value, 1))) > math.floor(math.log10(math.max(old, 1))) then
			Audio.Play("StatMilestone")
		end
	end
end

function HudController:RenderState(state, previous)
	self:SetStat("Coins", state.Coins)
	self:SetStat("Speed", state.Speed)
	self:SetStat("Strength", state.Strength)
	self:SetStat("Eggs", state.Eggs)
	local rank = Formulas.Rank(state.Eggs)
	local rankLabel = hud.Stats.Rank
	rankLabel.Text = rank.Name
	rankLabel.TextColor3 = rank.Color
	local carry = hud.Carry
	carry.Text.Text = ("🥚 %s / %s"):format(Format.Short(state.Carry), Format.Short(state.Capacity))
	carry.Text.TextColor3 = state.Carry >= state.Capacity and UIConfig.Colors.Bad or Color3.new(1, 1, 1)
	if previous and state.Carry ~= previous.Carry then
		Ui.Pop(carry, 1.1)
	end
	progress.Contribution.Text = ("You: %s"):format(Ui.Comma(state.RoundPieces or 0))
	gui.TrainHint.Visible = state.Training ~= nil
end

function HudController:RenderServer(server)
	local fraction = server.Target > 0 and server.Progress / server.Target or 0
	progress.Title.Text = string.upper(server.ProjectName)
	Ui.Tween(progress.Bar.Fill, UIConfig.BarTweenTime, { Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) })
	progress.Bar.Percent.Text = Format.Percent(fraction)
	progress.Count.Text = ("%s / %s"):format(Ui.Comma(server.Progress), Ui.Comma(server.Target))
end

function HudController:RenderTimer()
	local server = ClientState.Server
	local phase = progress.Phase
	if not server or server.Phase == "Building" then
		phase.Visible = false
		return
	end
	local remaining = math.max(0, math.floor(server.PhaseEndsAt - Workspace:GetServerTimeNow()))
	phase.Visible = true
	if server.Phase == "Cutscene" then
		phase.Text = "THE EGG IS HATCHING!"
	else
		phase.Text = ("NEXT EGG IN %d:%02d"):format(remaining // 60, remaining % 60)
	end
end

return HudController
