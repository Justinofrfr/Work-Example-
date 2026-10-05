local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LogService = game:GetService("LogService")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
local done = false
local function note(...)
	local parts = {}
	for _, value in { ... } do
		table.insert(parts, tostring(value))
	end
	table.insert(results, table.concat(parts, " "))
end

LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		note("[server " .. messageType.Name .. "]", message)
	end
end)

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
clientLog.OnServerEvent:Connect(function(_, message)
	note("[client]", message)
	if message:find("%[Trailer%] done") then
		done = true
	end
end)

local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local BuildService = require(Services.BuildService)
	local TrailerConfig = require(ReplicatedStorage.Shared.Config.Trailer)
	local waited = 0
	while not DataService:Get(player) and waited < 15 do
		task.wait(0.25)
		waited += 0.25
	end
	task.wait(workspace:GetAttribute("TrailerWait") or 4)
	workspace:SetAttribute(TrailerConfig.Attribute, true)
	workspace:SetAttribute(TrailerConfig.AutoAttribute, true)
	local started = os.clock()
	while not done and os.clock() - started < 260 do
		task.wait(0.5)
		if BuildService.Phase ~= "Building" and not results.phase then
			results.phase = true
			note("phase", BuildService.Phase, "at", math.floor(os.clock() - started))
		end
	end
	note("finished", done, "elapsed", math.floor(os.clock() - started), "phase", BuildService.Phase)
end)
if not ok then
	note("TEST ERROR", err)
end
StudioTestService:EndTest(table.concat(results, "\n"))
