local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
clientLog.OnServerEvent:Connect(function(_, message)
	table.insert(results, "[client] " .. message)
end)
local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local StateService = require(Services.StateService)
	local TrailerService = require(Services.TrailerService)
	local waited = 0
	while not DataService:Get(player) and waited < 15 do
		task.wait(0.25)
		waited += 0.25
	end
	task.wait(4)
	workspace:SetAttribute("Trailer", true)
	workspace:SetAttribute("TrailerAuto", true)
	local started = os.clock()
	while os.clock() - started < 50 do
		task.wait(0.5)
		local runtime = StateService:Get(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local v = root and root.AssemblyLinearVelocity or Vector3.zero
		table.insert(results, ("t=%.1f gen=%d carry=%s speed=%.1f"):format(os.clock() - started, TrailerService.Generation, tostring(runtime and runtime.Carry), Vector3.new(v.X, 0, v.Z).Magnitude))
	end
end)
if not ok then
	table.insert(results, "TEST ERROR " .. tostring(err))
end
StudioTestService:EndTest(table.concat(results, "\n"))
