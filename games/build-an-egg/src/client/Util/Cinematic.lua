local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local EffectsConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.Effects)
local Settings = require(script.Parent.Settings)

local Cinematic = {
	Depth = 0,
}

local FOCUS = EffectsConfig.Cutscene.Focus

function Cinematic.Focus(point)
	local focus = Lighting:FindFirstChild("CutsceneFocus")
	if not focus then
		return
	end
	local scenery = Lighting:FindFirstChild("SceneryDepth")
	local distance = point and (Workspace.CurrentCamera.CFrame.Position - point).Magnitude
	if distance and distance < FOCUS.MaxDistance and Settings:EffectScale() > 0 then
		if not focus.Enabled then
			Cinematic.SceneryWas = scenery and scenery.Enabled
			if scenery then
				scenery.Enabled = false
			end
			focus.FarIntensity = 0
			focus.Enabled = true
		end
		focus.FarIntensity = math.min(FOCUS.Far, focus.FarIntensity + FOCUS.Far * FOCUS.Ramp)
		focus.FocusDistance = math.clamp(distance, 0, 200)
	elseif focus.Enabled then
		focus.Enabled = false
		if scenery and Cinematic.SceneryWas ~= nil then
			scenery.Enabled = Cinematic.SceneryWas
		end
	end
end

function Cinematic.Blur(enabled)
	local blur = Lighting:FindFirstChild("RevealBlur")
	if blur then
		blur.Enabled = enabled and Settings:EffectScale() > 0
	end
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

function Cinematic.Gui()
	return playerGui:WaitForChild("Cinematic")
end

local function setCore(enabled)
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, enabled)
end

function Cinematic.Enter()
	Cinematic.Depth += 1
	if Cinematic.Depth == 1 then
		local main = playerGui:FindFirstChild("Main")
		if main then
			main.Enabled = false
		end
		setCore(false)
	end
end

function Cinematic.Exit()
	Cinematic.Depth = math.max(0, Cinematic.Depth - 1)
	if Cinematic.Depth == 0 then
		local main = playerGui:FindFirstChild("Main")
		if main then
			main.Enabled = true
		end
		setCore(true)
	end
end

return Cinematic
