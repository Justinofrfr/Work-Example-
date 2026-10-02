local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIConfig = require(Shared.Config.UI)

local Audio = require(script.Parent.Audio)

local Ui = {}

local FX = UIConfig.Fx
local scales = setmetatable({}, { __mode = "k" })
local shining = setmetatable({}, { __mode = "k" })

function Ui.Tween(instance, time, props, style, direction)
	local tween = TweenService:Create(instance, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

function Ui.Scale(guiObject)
	local scale = scales[guiObject]
	if not scale then
		scale = guiObject:FindFirstChildOfClass("UIScale")
		scales[guiObject] = scale
	end
	return scale
end

function Ui.Pop(guiObject, peak)
	local scale = Ui.Scale(guiObject)
	if not scale then
		return
	end
	scale.Scale = 1
	Ui.Tween(scale, 0.1, { Scale = peak or UIConfig.StatPulseScale }).Completed:Once(function()
		Ui.Tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end

function Ui.Shine(target)
	if not target then
		return
	end
	local fx = target:FindFirstChild("ShineFX")
	if not fx then
		for _, child in target:GetChildren() do
			if child:IsA("GuiObject") and child:FindFirstChild("ShineFX") then
				fx = child.ShineFX
				break
			end
		end
	end
	if not fx or shining[fx] then
		return
	end
	local gradient = fx:FindFirstChildOfClass("UIGradient")
	if not gradient then
		return
	end
	shining[fx] = true
	gradient.Offset = Vector2.new(-1, 0)
	fx.BackgroundTransparency = FX.ShinePeak
	Ui.Tween(gradient, FX.ShineTime, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut).Completed:Once(function()
		fx.BackgroundTransparency = 1
		gradient.Offset = Vector2.new(-1, 0)
		shining[fx] = nil
	end)
end

function Ui.Shake(guiObject)
	local origin = guiObject.Rotation
	for _, angle in { 6, -6, 4, -4, 0 } do
		Ui.Tween(guiObject, 0.04, { Rotation = origin + angle }).Completed:Wait()
	end
end

function Ui.Feel(button, onClick)
	if onClick then
		button.Activated:Connect(onClick)
	end
	if button:GetAttribute("FeelBound") then
		return
	end
	button:SetAttribute("FeelBound", true)
	local scale = Ui.Scale(button)
	if not scale then
		return
	end
	local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local shineAt = 0
	button.Activated:Connect(function()
		scale.Scale = UIConfig.ButtonPressScale
		Ui.Tween(scale, UIConfig.ReleaseTime * 1.8, { Scale = touch and 1 or UIConfig.ButtonHoverScale }, Enum.EasingStyle.Back)
	end)
	if not touch then
		button.MouseEnter:Connect(function()
			Ui.Tween(scale, UIConfig.HoverTime, { Scale = UIConfig.ButtonHoverScale })
			Audio.Play("Hover", 1.05, FX.HoverVolume)
			local now = os.clock()
			if now - shineAt >= FX.HoverShineGap then
				shineAt = now
				Ui.Shine(button)
			end
		end)
		button.MouseLeave:Connect(function()
			Ui.Tween(scale, UIConfig.HoverTime, { Scale = 1 })
		end)
	end
	button.MouseButton1Down:Connect(function()
		Ui.Tween(scale, UIConfig.PressTime, { Scale = UIConfig.ButtonPressScale })
	end)
	button.MouseButton1Up:Connect(function()
		Ui.Tween(scale, UIConfig.ReleaseTime, { Scale = touch and 1 or UIConfig.ButtonHoverScale }, Enum.EasingStyle.Back)
	end)
end

function Ui.SetText(guiObject, text)
	local labelObject = guiObject:FindFirstChild("Label") or guiObject
	if labelObject:IsA("TextLabel") or labelObject:IsA("TextButton") then
		labelObject.Text = text
	end
end

function Ui.SetColor(button, color)
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient then
		local h, s, v = color:ToHSV()
		gradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.25), Color3.fromHSV(h, math.clamp(s + 0.018, 0, 1), math.clamp(v - 0.18, 0, 1)))
	end
end

function Ui.Comma(value)
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

return Ui
