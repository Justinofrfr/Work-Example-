local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Names = require(Shared.Config.Names)
local EffectsConfig = require(Shared.Config.Effects)

local Ui = require(script.Parent.Parent.Util.Ui)
local Audio = require(script.Parent.Parent.Util.Audio)
local Settings = require(script.Parent.Parent.Util.Settings)

local CutsceneController = {
	Playing = false,
	IntroDone = false,
}

local ClientState
local EggController
local remotes
local gui
local camera = Workspace.CurrentCamera

function CutsceneController:Init(modules, context)
	ClientState = modules.ClientState
	EggController = modules.EggController
	remotes = context.Remotes
	gui = context.Gui
end

function CutsceneController:Start()
	gui:WaitForChild("Cutscene").Skip.Activated:Connect(function()
		self.SkipRequested = true
	end)
	local function tryIntro(state)
		if self.IntroDone or not state then
			return
		end
		self.IntroDone = true
		if EffectsConfig.Intro.Enabled and Settings:Get("Cutscenes") and state.Eggs == 0 and state.PiecesPlaced == 0 then
			task.spawn(self.Play, self, EffectsConfig.Intro.Shots)
		end
	end
	ClientState.StateChanged:Connect(tryIntro)
	tryIntro(ClientState.State)
	remotes[Names.Remotes.Notify].OnClientEvent:Connect(function(kind)
		if kind == "NextEgg" and EffectsConfig.NextEggShot.Enabled and Settings:Get("Cutscenes") then
			task.delay(0.4, function()
				self:Play({ EffectsConfig.NextEggShot })
			end)
		end
	end)
end

function CutsceneController:Letterbox(show)
	local cutscene = gui.Cutscene
	if show then
		cutscene.Visible = true
		Ui.Tween(cutscene.Top, 0.35, { Position = UDim2.fromScale(0, 0) })
		Ui.Tween(cutscene.Bottom, 0.35, { Position = UDim2.fromScale(0, 0.88) })
	else
		cutscene.Caption.Text = ""
		Ui.Tween(cutscene.Top, 0.3, { Position = UDim2.fromScale(0, -0.12) })
		Ui.Tween(cutscene.Bottom, 0.3, { Position = UDim2.fromScale(0, 1) }).Completed:Wait()
		cutscene.Visible = false
	end
end

function CutsceneController:Play(shots)
	if self.Playing or EggController.InCutscene then
		return
	end
	self.Playing = true
	self.SkipRequested = false
	local previousType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	self:Letterbox(true)
	Audio.Play("Open")
	for _, shot in shots do
		if self.SkipRequested or EggController.InCutscene then
			break
		end
		gui.Cutscene.Caption.Text = shot.Caption or ""
		local started = os.clock()
		while os.clock() - started < shot.Time and not self.SkipRequested and not EggController.InCutscene do
			local alpha = (os.clock() - started) / shot.Time
			local eased = alpha < 0.5 and 2 * alpha * alpha or 1 - (-2 * alpha + 2) ^ 2 / 2
			camera.CFrame = CFrame.lookAt(shot.From:Lerp(shot.To, eased), shot.Focus)
			RunService.RenderStepped:Wait()
		end
	end
	if not EggController.InCutscene then
		camera.CameraType = previousType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or previousType
	end
	self:Letterbox(false)
	self.Playing = false
end

return CutsceneController
