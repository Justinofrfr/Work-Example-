local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		clientLog:FireServer(messageType.Name .. ": " .. message)
	end
end)

task.delay(8, function()
	local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("Main")
	if not gui then
		clientLog:FireServer("no Main gui")
		return
	end
	local hud = gui.Hud
	local shopCards = 0
	for _, descendant in gui.Panels.Shop:GetDescendants() do
		if descendant.Name == "Buy" and descendant:IsA("GuiButton") then
			shopCards += 1
		end
	end
	local visibleSegments = 0
	for _, segment in workspace.Game.Site.Egg.Rings:GetDescendants() do
		if segment:IsA("BasePart") and segment.Transparency < 1 then
			visibleSegments += 1
		end
	end
	local glowingSteps = 0
	for _, step in workspace.Game.Site.Scaffold:GetChildren() do
		if step.Name == "Step" and step.Material == Enum.Material.Neon then
			glowingSteps += 1
		end
	end
	clientLog:FireServer(("UI coins=%s speed=%s eggs=%s carry=%s title=%s pct=%s shopCards=%d upgrades=%d settings=%d segmentsShown=%d glowSteps=%d"):format(
		hud.Stats.Coins.Value.Text,
		hud.Stats.Speed.Value.Text,
		hud.Stats.Eggs.Value.Text,
		hud.Carry.Text.Text,
		hud.Progress.Title.Text,
		hud.Progress.Bar.Percent.Text,
		shopCards,
		#gui.Panels.Upgrades.Body.List:GetChildren() - 1,
		#gui.Panels.Settings.Body.List:GetChildren() - 1,
		visibleSegments,
		glowingSteps
	))
end)
