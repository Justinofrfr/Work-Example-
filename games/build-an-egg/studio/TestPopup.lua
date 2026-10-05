local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
local finished = false
clientLog.OnServerEvent:Connect(function(_, message)
	table.insert(results, "[client] " .. message)
	if message == "done" then
		finished = true
	end
end)
local started = os.clock()
while not finished and os.clock() - started < 40 do
	task.wait(0.5)
end
StudioTestService:EndTest(table.concat(results, "\n"))
