local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
local counts = {}
ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Effect").OnClientEvent:Connect(function(kind)
	counts[kind] = (counts[kind] or 0) + 1
end)
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		clientLog:FireServer("Error: " .. message)
	elseif message:find("%[Trailer%]") then
		local parts = {}
		for kind, count in counts do
			table.insert(parts, kind .. "=" .. count)
		end
		clientLog:FireServer(message .. " effects " .. table.concat(parts, ","))
	end
end)
