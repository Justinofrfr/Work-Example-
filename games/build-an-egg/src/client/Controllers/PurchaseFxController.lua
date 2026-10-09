local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local UIConfig = require(Shared.Config.UI)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)
local Purchase = require(script.Parent.Parent.Util.Purchase)

local PurchaseFxController = {
	Active = {},
	Slots = {},
	Homes = {},
	Counter = 0,
	BackgroundOn = false,
	Token = 0,
}

local P = UIConfig.PurchaseFx
local AL = UIConfig.Alert
local CF = UIConfig.Confetti
local background
local backgroundGradient
local blur
local savedBlur = 0
local confettiLayer
local confettiBit
local random = Random.new()

local function setAlpha(label, alpha)
	label.TextTransparency = alpha
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = alpha
	end
end

local function ramp(label, from, to, time, style, direction)
	local started = os.clock()
	task.spawn(function()
		while label.Parent do
			local progress = math.clamp((os.clock() - started) / math.max(time, 0.01), 0, 1)
			local eased = TweenService:GetValue(progress, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
			setAlpha(label, from + (to - from) * eased)
			if progress >= 1 then
				break
			end
			task.wait()
		end
	end)
end

function PurchaseFxController:Init(_, context)
	local playerGui = context.Player:WaitForChild("PlayerGui")
	background = playerGui:WaitForChild(Names.Gui.Overlay):WaitForChild("PurchaseBackground")
	backgroundGradient = background:FindFirstChildOfClass("UIGradient")
	background.Visible = false
	blur = Lighting:FindFirstChild(Names.Gui.PurchaseBlur)
	local alertFrame = playerGui:WaitForChild(Names.Gui.Alert):WaitForChild("MainFrame")
	for _, name in AL.Slots do
		local slot = alertFrame:WaitForChild(name)
		table.insert(self.Slots, slot)
		self.Homes[#self.Slots] = { Position = slot.Position, Size = slot.Size }
		slot.Text = ""
		setAlpha(slot, 1)
	end
	confettiLayer = playerGui:WaitForChild(Names.Gui.Fx):WaitForChild("ConfettiLayer")
	confettiBit = confettiLayer:WaitForChild("Bit")
end

function PurchaseFxController:Start()
	Purchase.Prompted:Connect(function()
		self:Background(true)
	end)
	Purchase.Finished:Connect(function()
		self:Background(false)
	end)
	RunService.RenderStepped:Connect(function(dt)
		if self.BackgroundOn and backgroundGradient then
			backgroundGradient.Rotation = (backgroundGradient.Rotation + dt * P.SpinSpeed) % 360
		end
	end)
end

function PurchaseFxController:Background(on)
	self.Token += 1
	local token = self.Token
	if on then
		if not self.BackgroundOn then
			self.BackgroundOn = true
			background.Visible = true
			if blur then
				savedBlur = blur.Size
				Ui.Tween(blur, P.BlurTime, { Size = math.max(savedBlur, P.Blur) })
			end
		end
		task.delay(P.Timeout, function()
			if self.Token == token and self.BackgroundOn then
				self:Background(false)
			end
		end)
	elseif self.BackgroundOn then
		self.BackgroundOn = false
		background.Visible = false
		if blur then
			Ui.Tween(blur, P.BlurTime, { Size = savedBlur })
		end
	end
end

function PurchaseFxController:FreeSlot()
	for index, slot in self.Slots do
		local used = false
		for _, entry in self.Active do
			if entry.Label == slot then
				used = true
				break
			end
		end
		if not used then
			return slot, index
		end
	end
	return self.Slots[1], 1
end

function PurchaseFxController:MoveTo(label, index)
	local home = self.Homes[index]
	if home then
		Ui.Tween(label, AL.MoveTime, { Position = home.Position })
	end
end

function PurchaseFxController:Alert(text)
	if #self.Slots == 0 then
		return
	end
	if #self.Active >= #self.Slots then
		local oldest = table.remove(self.Active)
		ramp(oldest.Label, 0, 1, AL.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	for index, entry in self.Active do
		self:MoveTo(entry.Label, index + 1)
	end
	local label, slotIndex = self:FreeSlot()
	local size = self.Homes[slotIndex].Size
	label.Text = text
	label.Position = self.Homes[1].Position
	label.Size = UDim2.fromScale(size.X.Scale * AL.PopFrom, size.Y.Scale * AL.PopFrom)
	self.Counter += 1
	local id = self.Counter
	table.insert(self.Active, 1, { Label = label, Id = id })
	Ui.Tween(label, AL.PopTime, { Size = size }, Enum.EasingStyle.Back)
	ramp(label, 1, 0, AL.PopTime, Enum.EasingStyle.Quad)
	task.delay(AL.Hold, function()
		for index, entry in self.Active do
			if entry.Id == id then
				table.remove(self.Active, index)
				ramp(entry.Label, 0, 1, AL.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				for later = index, #self.Active do
					self:MoveTo(self.Active[later].Label, later)
				end
				break
			end
		end
	end)
end

function PurchaseFxController:Confetti(count)
	for _ = 1, count or CF.Count do
		local bit = confettiBit:Clone()
		bit.Visible = true
		bit.BackgroundColor3 = CF.Colors[random:NextInteger(1, #CF.Colors)]
		local x = random:NextNumber()
		bit.Position = UDim2.fromScale(x, -0.06 - random:NextNumber() * 0.12)
		bit.Rotation = random:NextInteger(0, 360)
		bit.Parent = confettiLayer
		local fall = Ui.Tween(bit, CF.Time * random:NextNumber(0.75, 1.25), {
			Position = UDim2.fromScale(x + random:NextNumber(-0.5, 0.5) * CF.Drift, 1.08),
			Rotation = bit.Rotation + random:NextInteger(-CF.Spin, CF.Spin),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		fall.Completed:Once(function()
			bit:Destroy()
		end)
	end
end

function PurchaseFxController:Celebrate(itemName)
	self:Background(false)
	self:Alert(AL.Text:format(tostring(itemName)))
	self:Confetti(P.Confetti)
	Audio.Play(P.Sound)
	Audio.Play("RobuxSuccess")
end

return PurchaseFxController
