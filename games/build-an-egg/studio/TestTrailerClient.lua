local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		clientLog:FireServer("Error: " .. message)
	elseif message:find("%[Trailer%]") then
		clientLog:FireServer(message)
	end
end)
