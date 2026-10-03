local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UIConfig = require(Shared.Config.UI)
local DailyConfig = require(Shared.Config.Daily)
local GiftConfig = require(Shared.Config.Gift)
local DailyRules = require(Shared.Util.DailyRules)
local Format = require(Shared.Util.Format)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local DailyController = {
	AutoOpened = false,
}

local ClientState
local PanelController
local NotifyController
local PurchaseFxController
local EggController
local CutsceneController
local remotes
local gui
local body
local button

local function lines(reward)
	local list = {}
	for _, line in GiftConfig.Lines do
		local amount = reward[line.Key]
		if amount and amount > 0 then
			table.insert(list, line.Icon .. " +" .. Format.Short(amount))
		end
	end
	return table.concat(list, "\n")
end

function DailyController:Init(modules, context)
	ClientState = modules.ClientState
	PanelController = modules.PanelController
	NotifyController = modules.NotifyController
	PurchaseFxController = modules.PurchaseFxController
	EggController = modules.EggController
	CutsceneController = modules.CutsceneController
	remotes = context.Remotes
	gui = context.Gui
end

function DailyController:Start()
	body = PanelController:Get("Daily").Body
	button = gui:WaitForChild("Hud"):WaitForChild("TopLeft"):WaitForChild("Daily")
	button.Activated:Connect(function()
		PanelController:Toggle("Daily")
	end)
	Ui.Feel(body.Claim, function()
		self:Claim()
	end)
	PanelController.Opened:Connect(function(name)
		if name == "Daily" then
			self:Render()
		end
	end)
	ClientState.StateChanged:Connect(function()
		self:Render()
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			self:Render()
			self:TryAutoOpen()
		end
	end)
end

function DailyController:Status()
	local state = ClientState.State
	if not state then
		return nil
	end
	local now = Workspace:GetServerTimeNow()
	local today = DailyRules.Today(now)
	local day, ready = DailyRules.NextDay(state.DailyStreak or 0, state.DailyLast or -1, today)
	return day, ready, (today + 1) * DailyConfig.DayLength - now
end

function DailyController:Render()
	local state = ClientState.State
	local day, ready, remaining = self:Status()
	if not day then
		return
	end
	button.Badge.Visible = ready
	if not PanelController.Current or PanelController.Current.Name ~= "Daily" then
		return
	end
	for index = 1, #DailyConfig.Days do
		local card = body.Days["Day" .. index]
		local reward = DailyRules.Reward(index, state.Capacity, state.Carry, state.Speed, state.Strength)
		card.Reward.Text = lines(reward)
		local done = index < day or (index == day and not ready)
		card.Done.Visible = done
		card.BackgroundColor3 = index == day and ready and Color3.fromRGB(255, 220, 90) or (done and Color3.fromRGB(170, 230, 150) or Color3.fromRGB(255, 252, 240))
	end
	if ready then
		body.Status.Text = DailyConfig.Messages.Ready:format(day)
		Ui.SetText(body.Claim, "CLAIM!")
		Ui.SetColor(body.Claim, UIConfig.Colors.Good)
	else
		local seconds = math.max(0, math.floor(remaining))
		body.Status.Text = DailyConfig.Messages.Next:format(("%d:%02d:%02d"):format(seconds // 3600, seconds % 3600 // 60, seconds % 60))
		Ui.SetText(body.Claim, "CLAIMED")
		Ui.SetColor(body.Claim, UIConfig.Colors.Locked)
	end
end

function DailyController:TryAutoOpen()
	if self.AutoOpened then
		return
	end
	local state = ClientState.State
	local _, ready = self:Status()
	if not state or not ready or (state.TutorialStep or 0) < DailyConfig.AutoOpenAfterTutorial then
		return
	end
	if os.clock() < DailyConfig.AutoOpenDelay or PanelController.Current or EggController.InCutscene or CutsceneController.Playing then
		return
	end
	self.AutoOpened = true
	PanelController:Open("Daily")
end

function DailyController:Claim()
	if self.Busy then
		return
	end
	self.Busy = true
	local ok, day, reward = remotes[Names.Remotes.ClaimDaily]:InvokeServer()
	self.Busy = false
	if ok then
		Audio.Play("Reward")
		PurchaseFxController:Confetti(UIConfig.Celebrate.GymUnlocked)
		NotifyController:Toast(("Day %d claimed!"):format(day), UIConfig.Colors.Good)
		local card = body.Days:FindFirstChild("Day" .. day)
		if card then
			card.Reward.Text = lines(reward)
			Ui.Pop(card, 1.15)
		end
	else
		Audio.Play("Error")
		local nextDay = self:Status()
		NotifyController:Toast(DailyConfig.Messages.Claimed:format(nextDay or 1), UIConfig.Colors.Bad)
	end
	self:Render()
end

return DailyController
