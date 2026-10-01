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
}

local M = UIConfig.Messages
local gui
local remotes
local banner
local toasts
local toastTemplate
local EffectController

function NotifyController:Init(modules, context)
	gui = context.Gui
	remotes = context.Remotes
	EffectController = modules.EffectController
	banner = gui:WaitForChild("Banner")
	toasts = gui:WaitForChild("Toasts")
	toastTemplate = gui:WaitForChild("Templates"):WaitForChild("Toast")
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
		end
	elseif kind == "NextEgg" then
		local _, projectName = a, b
		self:Banner(M.NextEgg:format(string.upper(projectName and projectName.DisplayName or tostring(a))), Color3.fromRGB(255, 190, 60))
		Audio.Play("NextEgg")
	elseif kind == "Hatched" then
		self:Banner(M.Hatched:format(a), Color3.fromRGB(255, 210, 80))
	elseif kind == "RankUp" then
		self:Banner(M.RankUp:format(a), Color3.fromRGB(190, 120, 255))
		Audio.Play("RankUp")
	elseif kind == "GymUnlocked" then
		local tier = Formulas.GymTier(a)
		self:Banner(M.GymUnlocked:format(tier and (tier.Multiplier .. "x") or a), Color3.fromRGB(90, 200, 255))
		Audio.Play("GymUnlocked")
		EffectController:Fireworks(3)
	elseif kind == "ServerPack" then
		self:Banner(M.ServerPack:format(a, Format.Short(b)), Color3.fromRGB(255, 200, 60))
		Audio.Play("ServerPack")
		EffectController:ShellRain()
	elseif kind == "PassOwned" then
		self:Toast(M.PassOwned, UIConfig.Colors.Good)
		Audio.Play("RobuxSuccess")
	end
end

function NotifyController:Toast(text, color)
	local toast = toastTemplate:Clone()
	toast.Visible = true
	local label = toast:FindFirstChild("Text")
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	toast.LayoutOrder = math.floor(os.clock() * 100)
	toast.Parent = toasts
	local frames = {}
	for _, child in toasts:GetChildren() do
		if child:IsA("Frame") then
			table.insert(frames, child)
		end
	end
	table.sort(frames, function(x, y)
		return x.LayoutOrder < y.LayoutOrder
	end)
	while #frames > UIConfig.ToastMax do
		table.remove(frames, 1):Destroy()
	end
	Ui.Pop(toast, 1.08)
	task.delay(UIConfig.ToastHold, function()
		if toast.Parent then
			Ui.Tween(toast, 0.2, { BackgroundTransparency = 1 })
			Ui.Tween(label, 0.2, { TextTransparency = 1 })
			task.wait(0.22)
			toast:Destroy()
		end
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
