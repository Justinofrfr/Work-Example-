local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UIConfig = require(Shared.Config.UI)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)

local NotifyController = {
	Queue = {},
	Showing = false,
	Toasts = {},
}

local M = UIConfig.Messages
local T = UIConfig.Toast
local gui
local remotes
local banner
local holder
local toastTemplate
local EffectController
local PurchaseFxController

function NotifyController:Init(modules, context)
	gui = context.Gui
	remotes = context.Remotes
	EffectController = modules.EffectController
	PurchaseFxController = modules.PurchaseFxController
	banner = gui:WaitForChild("Banner")
	holder = context.Player:WaitForChild("PlayerGui"):WaitForChild(Names.Gui.Notify):WaitForChild("Notifications")
	toastTemplate = holder:WaitForChild("Template")
	toastTemplate.Visible = false
end

function NotifyController:Start()
	remotes[Names.Remotes.Notify].OnClientEvent:Connect(function(kind, ...)
		self:Handle(kind, ...)
	end)
end

function NotifyController:Handle(kind, a, b)
	if kind == "Toast" then
		self:Toast(a)
	elseif kind == "Full" then
		self:Toast(a or M.Full, UIConfig.Colors.Bad)
		Audio.Play("Full")
	elseif kind == "Milestone" then
		if a < 0.9 then
			self:Banner(M.Milestone:format(math.floor(a * 100 + 0.5)), Color3.fromRGB(120, 220, 110))
			Audio.Play("Milestone")
			EffectController:Fireworks(4)
			PurchaseFxController:Confetti(UIConfig.Celebrate.Milestone)
		end
	elseif kind == "NextEgg" then
		local _, projectName = a, b
		self:Banner(M.NextEgg:format(string.upper(projectName and projectName.DisplayName or tostring(a))), Color3.fromRGB(255, 190, 60))
		Audio.Play("NextEgg")
	elseif kind == "Hatched" then
		self:Banner(M.Hatched:format(a), Color3.fromRGB(255, 210, 80))
		PurchaseFxController:Confetti(UIConfig.Celebrate.Hatched)
		Audio.Play("Prize")
	elseif kind == "RankUp" then
		self:Banner(M.RankUp:format(a), Color3.fromRGB(190, 120, 255))
		Audio.Play("RankUp")
		PurchaseFxController:Confetti(UIConfig.Celebrate.RankUp)
	elseif kind == "GymUnlocked" then
		local tier = Formulas.GymTier(a)
		self:Banner(M.GymUnlocked:format(tier and (tier.Multiplier .. "x") or a), Color3.fromRGB(90, 200, 255))
		Audio.Play("GymUnlocked")
		EffectController:Fireworks(3)
		PurchaseFxController:Confetti(UIConfig.Celebrate.GymUnlocked)
	elseif kind == "ServerPack" then
		self:Banner(M.ServerPack:format(a, Format.Short(b)), Color3.fromRGB(255, 200, 60))
		Audio.Play("ServerPack")
		EffectController:ShellRain()
	elseif kind == "Purchased" then
		PurchaseFxController:Celebrate(a)
	end
end

local function paint(toast, color)
	local main = toast:FindFirstChild("bg")
	local gradient = main and main:FindFirstChildOfClass("UIGradient")
	if gradient then
		local h, s, v = color:ToHSV()
		local top = Color3.fromHSV(h, math.clamp(s * T.TopSaturation, 0, 1), math.clamp(v * T.TopValue, 0, 1))
		gradient.Color = ColorSequence.new(top, color)
	end
end

local function fade(toast, transparency, backdrop, time)
	Ui.Tween(toast, time, { TextTransparency = transparency, BackgroundTransparency = backdrop })
	for _, descendant in toast:GetDescendants() do
		if descendant:IsA("TextLabel") then
			Ui.Tween(descendant, time, { TextTransparency = transparency })
		elseif descendant:IsA("UIStroke") then
			Ui.Tween(descendant, time, { Transparency = transparency })
		end
	end
end

function NotifyController:Layout()
	local base = toastTemplate.Position
	local step = toastTemplate.Size.Y.Scale + T.Gap
	for index, toast in self.Toasts do
		Ui.Tween(toast, T.SlideTime, { Position = base - UDim2.fromScale(0, (index - 1) * step) })
	end
end

function NotifyController:Toast(text, color)
	text = tostring(text)
	if #text > T.MaxChars then
		text = text:sub(1, T.MaxChars - 2) .. ".."
	end
	local tone = (color == UIConfig.Colors.Good and T.Good) or (color == UIConfig.Colors.Bad and T.Bad) or T.Neutral
	local toast = toastTemplate:Clone()
	toast.Name = "Toast"
	toast.Text = text
	toast.bg.Text = text
	paint(toast, tone)
	toast.Position = toastTemplate.Position + UDim2.fromScale(T.SlideFrom, 0)
	toast.TextTransparency = 1
	toast.BackgroundTransparency = 1
	for _, descendant in toast:GetDescendants() do
		if descendant:IsA("TextLabel") then
			descendant.TextTransparency = 1
		elseif descendant:IsA("UIStroke") then
			descendant.Transparency = 1
		end
	end
	toast.Visible = true
	toast.Parent = holder
	fade(toast, 0, toastTemplate.BackgroundTransparency, T.SlideTime)
	table.insert(self.Toasts, 1, toast)
	while #self.Toasts > T.Max do
		table.remove(self.Toasts):Destroy()
	end
	self:Layout()
	if color ~= UIConfig.Colors.Bad then
		Audio.Play("Tick")
	end
	task.delay(T.Duration, function()
		local index = table.find(self.Toasts, toast)
		if index then
			table.remove(self.Toasts, index)
		end
		if toast.Parent then
			fade(toast, 1, 1, T.FadeOut)
			task.wait(T.FadeOut)
			toast:Destroy()
		end
		self:Layout()
	end)
end

function NotifyController:Banner(text, color)
	table.insert(self.Queue, { Text = text, Color = color })
	if not self.Showing then
		task.spawn(self.RunQueue, self)
	end
end

function NotifyController:RunQueue()
	self.Showing = true
	while #self.Queue > 0 do
		local entry = table.remove(self.Queue, 1)
		banner.Text.Text = entry.Text
		Ui.SetColor(banner, entry.Color or Color3.fromRGB(255, 190, 60))
		banner.Position = UDim2.fromScale(0.5, -0.2)
		banner.Visible = true
		Ui.Tween(banner, UIConfig.BannerIn, { Position = UDim2.fromScale(0.5, 0.17) }, Enum.EasingStyle.Back).Completed:Wait()
		task.wait(UIConfig.BannerHold)
		Ui.Tween(banner, UIConfig.BannerOut, { Position = UDim2.fromScale(0.5, -0.2) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait()
		banner.Visible = false
	end
	self.Showing = false
end

return NotifyController
