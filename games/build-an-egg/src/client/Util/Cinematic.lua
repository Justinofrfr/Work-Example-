local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Cinematic = {
	Depth = 0,
}

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
