local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StudioTestService = game:GetService("StudioTestService")
local LogService = game:GetService("LogService")

local results = {}
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		table.insert(results, "[server " .. messageType.Name .. "] " .. message)
	end
end)
ReplicatedStorage:WaitForChild("__TestLog").OnServerEvent:Connect(function(_, message)
	table.insert(results, "[client] " .. message)
end)
task.wait(82)
StudioTestService:EndTest(table.concat(results, "\n"))
