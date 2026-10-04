local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local GymsConfig = require(Shared.Config.Gyms)
local Format = require(Shared.Util.Format)

local RunService = game:GetService("RunService")
local ProductsConfig = require(Shared.Config.Products)

local Ui = require(script.Parent.Parent.Util.Ui)
local Purchase = require(script.Parent.Parent.Util.Purchase)
local Audio = require(script.Parent.Parent.Util.Audio)

local BubbleController = {
	Active = {},
	Popped = {},
}

local B = GymsConfig.Bubbles
local ClientState
local remotes
local layer
local template
local floatTemplate
local random = Random.new()

function BubbleController:Init(modules, context)
	ClientState = modules.ClientState
	remotes = context.Remotes
	layer = context.Player:WaitForChild("PlayerGui"):WaitForChild(Names.Gui.Bubbles):WaitForChild("Layer")
	template = layer:WaitForChild("Bubble")
	floatTemplate = layer:WaitForChild("Float")
	template.Visible = false
	floatTemplate.Visible = false
end

function BubbleController:Start()
	remotes[Names.Remotes.Bubble].OnClientEvent:Connect(function(action, id, a, b)
		if action == "Spawn" then
			self:Spawn(id, a)
		elseif action == "Popped" then
			self:ShowGain(id, a, b)
		elseif action == "Clear" then
			self:Clear()
		end
	end)
	ClientState.StateChanged:Connect(function(state)
		if state and not state.Training then
			self:Clear()
		end
	end)
end

function BubbleController:PickPosition()
	local chosen
	for _ = 1, B.PlaceTries do
		local candidate = Vector2.new(random:NextNumber(B.Area.Min.X, B.Area.Max.X), random:NextNumber(B.Area.Min.Y, B.Area.Max.Y))
		local clear = true
		for _, entry in self.Active do
			if (entry.Position - candidate).Magnitude < B.MinSpacing then
				clear = false
				break
			end
		end
		chosen = candidate
		if clear then
			break
		end
	end
	return chosen
end

function BubbleController:Spawn(id, kind)
	local def = B.Kinds[kind]
	if not def or type(id) ~= "number" or self.Active[id] then
		return
	end
	local position = self:PickPosition()
	local bubble = template:Clone()
	bubble.Name = "Bubble" .. id
	bubble.Position = UDim2.fromScale(position.X, position.Y)
	bubble.Size = UDim2.fromScale(0, 0)
	bubble.BackgroundColor3 = def.Color
	bubble.UIStroke.Color = def.Stroke
	bubble.Icon.Text = def.Icon
	bubble.Approach.UIStroke.Color = def.Color
	bubble.Approach.Size = UDim2.fromScale(B.ApproachScale, B.ApproachScale)
	local gradient = bubble:FindFirstChildOfClass("UIGradient")
	local rainbowGradient = bubble:FindFirstChild("Rainbow")
	if def.Product and rainbowGradient then
		if gradient then
			gradient.Enabled = false
		end
		rainbowGradient.Enabled = true
		bubble.BackgroundTransparency = 0
		local spin
		spin = RunService.RenderStepped:Connect(function(dt)
			if not bubble.Parent then
				spin:Disconnect()
				return
			end
			rainbowGradient.Rotation = (rainbowGradient.Rotation + dt * B.Rainbow.GradientSpeed) % 360
		end)
	end
	bubble.Visible = true
	bubble.Parent = layer
	local entry = { Bubble = bubble, Position = position, Kind = kind }
	self.Active[id] = entry
	Ui.Tween(bubble, B.SpawnTime, { Size = UDim2.fromScale(def.Size, def.Size) }, Enum.EasingStyle.Back)
	Ui.Tween(bubble.Approach, def.Lifetime, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
	Audio.Play("Tick", def.SpawnPitch)
	bubble.Activated:Connect(function()
		if def.Product then
			local product = ProductsConfig.DevProducts[def.Product]
			Purchase.Product(product and product.Id)
			self:Miss(id)
		else
			self:Pop(id)
		end
	end)
	task.delay(def.Lifetime, function()
		if self.Active[id] == entry then
			self:Miss(id)
		end
	end)
end

function BubbleController:Pop(id)
	local entry = self.Active[id]
	if not entry then
		return
	end
	self.Active[id] = nil
	self.Popped[id] = entry
	remotes[Names.Remotes.PopBubble]:FireServer(id)
	local def = B.Kinds[entry.Kind]
	Audio.Play(def.PopSound, def.PopPitch)
	local bubble = entry.Bubble
	bubble.Active = false
	bubble.Approach.Visible = false
	local size = bubble.Size
	Ui.Tween(bubble, B.PopTime, {
		Size = UDim2.fromScale(size.X.Scale * B.PopScale, size.Y.Scale * B.PopScale),
		BackgroundTransparency = 1,
	})
	Ui.Tween(bubble.UIStroke, B.PopTime, { Transparency = 1 })
	Ui.Tween(bubble.Shine, B.PopTime, { BackgroundTransparency = 1 })
	Ui.Tween(bubble.Icon, B.PopTime, { TextTransparency = 1 })
	Ui.Tween(bubble.Icon.UIStroke, B.PopTime, { Transparency = 1 })
	task.delay(B.PopTime, function()
		bubble:Destroy()
	end)
	task.delay(B.FloatTime * 2, function()
		self.Popped[id] = nil
	end)
end

function BubbleController:ShowGain(id, stat, gain)
	local entry = self.Popped[id]
	if not entry or type(gain) ~= "number" then
		return
	end
	self.Popped[id] = nil
	local def = B.Kinds[entry.Kind]
	local float = floatTemplate:Clone()
	float.Text = "+" .. Format.Short(gain) .. " " .. (B.StatText[stat] or "")
	float.TextColor3 = def.FloatColor
	float.Position = UDim2.fromScale(entry.Position.X, entry.Position.Y)
	float.Size = UDim2.fromScale(B.FloatSize.X, B.FloatSize.Y)
	float.Visible = true
	float.Parent = layer
	Ui.Tween(float, B.FloatTime, { Position = UDim2.fromScale(entry.Position.X, entry.Position.Y - B.FloatRise), TextTransparency = 1 })
	Ui.Tween(float.UIStroke, B.FloatTime, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(B.FloatTime, function()
		float:Destroy()
	end)
end

function BubbleController:Miss(id)
	local entry = self.Active[id]
	if not entry then
		return
	end
	self.Active[id] = nil
	local bubble = entry.Bubble
	bubble.Active = false
	Ui.Tween(bubble, B.MissTime, { Size = UDim2.fromScale(0, 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	Ui.Tween(bubble.Approach.UIStroke, B.MissTime, { Transparency = 1 })
	task.delay(B.MissTime, function()
		bubble:Destroy()
	end)
end

function BubbleController:Clear()
	for id in self.Active do
		self:Miss(id)
	end
end

return BubbleController
