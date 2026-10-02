local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AntiCheatConfig = require(Shared.Config.AntiCheat)

local MovementGuardService = {
	Tracks = {},
}

local DataService
local StateService

function MovementGuardService:Init(modules)
	DataService = modules.DataService
	StateService = modules.StateService
end

function MovementGuardService:Start()
	if not AntiCheatConfig.Enabled then
		return
	end
	DataService.Releasing:Connect(function(player)
		self.Tracks[player] = nil
	end)
	task.spawn(function()
		while true do
			local dt = task.wait(AntiCheatConfig.CheckInterval)
			for player in StateService.Runtime do
				self:Check(player, dt)
			end
		end
	end)
end

function MovementGuardService:Grace(player)
	local track = self.Tracks[player]
	if track then
		track.GraceUntil = os.clock() + AntiCheatConfig.TeleportGrace
		track.Last = nil
	else
		self.Tracks[player] = { GraceUntil = os.clock() + AntiCheatConfig.TeleportGrace, Strikes = 0 }
	end
end

function MovementGuardService:Check(player, dt)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		self.Tracks[player] = nil
		return
	end
	local track = self.Tracks[player]
	if not track then
		track = { Strikes = 0, GraceUntil = 0 }
		self.Tracks[player] = track
	end
	local position = rootPart.Position
	if not track.Last or os.clock() < track.GraceUntil then
		track.Last = position
		track.Strikes = 0
		return
	end
	local delta = position - track.Last
	local flat = Vector2.new(delta.X, delta.Z).Magnitude
	local allowed = math.max(humanoid.WalkSpeed, 16) * dt * AntiCheatConfig.SpeedSlack + AntiCheatConfig.FlatAllowance
	local vertical = delta.Y
	if flat > allowed or vertical > AntiCheatConfig.VerticalAllowance then
		track.Strikes += 1
		if track.Strikes >= AntiCheatConfig.StrikesBeforeRewind then
			rootPart.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(CFrame.new(track.Last) * rootPart.CFrame.Rotation)
			track.Strikes = 0
			return
		end
	else
		track.Strikes = 0
	end
	track.Last = position
end

return MovementGuardService
