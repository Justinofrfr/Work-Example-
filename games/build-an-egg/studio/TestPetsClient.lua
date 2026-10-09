local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		clientLog:FireServer("Error: " .. message)
	end
end)

local player = Players.LocalPlayer
task.spawn(function()
	task.wait(5.5)
	local controllers = player.PlayerScripts.Client.Controllers
	local PanelController = require(controllers.PanelController)
	PanelController:Open("Pets")
	task.wait(0.6)
	local main = player.PlayerGui.Main
	local cards = 0
	for _, child in main.Panels.Pets.Body.List:GetChildren() do
		if child:IsA("Frame") then
			cards += 1
		end
	end
	local followers = 0
	for _, child in workspace:GetChildren() do
		if child:IsA("Model") and child.Name:find("_%d$") then
			followers += 1
		end
	end
	clientLog:FireServer(("pets panel cards %d info %s boosts %s followers %d"):format(cards, main.Panels.Pets.Body.Info.Text, main.Panels.Pets.Body.Boosts.Text, followers))
	PanelController:Open("Incubator")
	task.wait(0.6)
	local rows = 0
	for _, child in main.Panels.Incubator.Body.Choices:GetChildren() do
		if child:IsA("Frame") then
			rows += 1
		end
	end
	clientLog:FireServer(("incubator rows %d odds %s"):format(rows, (main.Panels.Incubator.Body.Odds.Text:gsub("\n", " | "))))
	local choices = main.Panels.Incubator.Body.Choices
	local firstRow = choices:FindFirstChildWhichIsA("Frame")
	clientLog:FireServer(("choices canvas %s window %s row %s"):format(tostring(choices.AbsoluteCanvasSize), tostring(choices.AbsoluteWindowSize), firstRow and tostring(firstRow.AbsoluteSize) or "none"))
	PanelController:Close()
	local IncubatorController = require(controllers.IncubatorController)
	task.spawn(IncubatorController.Reveal, IncubatorController, { Collection = "Common", Rarity = 1, Id = 0 })
	task.wait(3)
	local view = main.Reveal.View
	local pet = view:FindFirstChild("Pet")
	local parts = 0
	for _, d in pet and pet:GetDescendants() or {} do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	clientLog:FireServer(("reveal visible %s view %s size %s pet %s parts %d current %s"):format(tostring(main.Reveal.Visible), tostring(view.Visible), tostring(view.AbsoluteSize), tostring(pet ~= nil), parts, tostring(view.CurrentCamera)))
end)
