local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientLog = ReplicatedStorage:WaitForChild("__TestLog")
local function log(...)
	local parts = {}
	for _, value in { ... } do
		table.insert(parts, tostring(value))
	end
	clientLog:FireServer(table.concat(parts, " "))
end
LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		clientLog:FireServer(messageType.Name .. ": " .. message)
	end
end)

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("Main")
local hud = gui:WaitForChild("Hud")
local controllers = player.PlayerScripts:WaitForChild("Client"):WaitForChild("Controllers")
local PanelController = require(controllers.PanelController)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local stage = ReplicatedStorage:WaitForChild("__TestStage")

local bubbleKinds = {}
local rainbowShown = false
ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bubble").OnClientEvent:Connect(function(action, _, kind)
	if action == "Spawn" then
		bubbleKinds[kind] = (bubbleKinds[kind] or 0) + 1
		task.wait(0.3)
		for _, bubble in player.PlayerGui:FindFirstChild("Bubbles") and player.PlayerGui.Bubbles:GetDescendants() or {} do
			if bubble.Name == "Rainbow" and bubble:IsA("UIGradient") and bubble.Enabled and bubble.Parent.Visible then
				rainbowShown = true
			end
		end
	end
end)

local function findText(pattern)
	for _, label in player.PlayerGui:GetDescendants() do
		if label:IsA("TextLabel") and label.Visible and label.Text:lower():find(pattern) then
			return label:GetFullName():gsub("Players%.[^%.]+%.PlayerGui%.", "") .. " = " .. label.Text
		end
	end
	return nil
end

local function onStage(name)
	if name == "Idle" then
		local inset = GuiService.TopbarInset
		task.wait(1.2)
		log(("insets topbarMaxY=%d topLeftY=%d topLeftBottom=%d offerVisible=%s offerY=%d"):format(inset.Max.Y, hud.TopLeft.AbsolutePosition.Y, hud.TopLeft.AbsolutePosition.Y + hud.TopLeft.AbsoluteSize.Y, tostring(hud.Offer.Visible), hud.Offer.AbsolutePosition.Y))
		local rigs = CollectionService:GetTagged("GooseRig")
		local bird = rigs[1]
		if bird then
			local head
			for _, bone in bird:GetDescendants() do
				if bone:IsA("Bone") and bone.Name == "Head" then
					head = bone
				end
			end
			local first = head and head.Transform
			task.wait(1.5)
			local second = head and head.Transform
			local camDistance = (workspace.CurrentCamera.CFrame.Position - bird.Position).Magnitude
			log(("goose rigs=%d head=%s moved=%s camDist=%.0f tex=%s"):format(#rigs, tostring(head ~= nil), tostring(first and second and (first.LookVector - second.LookVector).Magnitude > 1e-4), camDistance, bird.TextureID))
		else
			log("goose rigs=0")
		end
		local foam = CollectionService:GetTagged("Foam")
		local ripple = CollectionService:GetTagged("Ripple")
		local spriteTex = foam[1] and foam[1]:FindFirstChildOfClass("Decal") and foam[1].Sprite.Texture
		log(("water foam=%d ripple=%d foamTex=%s"):format(#foam, #ripple, tostring(spriteTex)))
		PanelController:Open("Social")
		task.wait(0.6)
		local social = PanelController:Get("Social")
		log(("social visible=%s favorite=%s group=%s"):format(tostring(social.Visible), tostring(social.Body:FindFirstChild("Favorite") ~= nil), tostring(social.Body:FindFirstChild("Group") ~= nil)))
		PanelController:Close()
	elseif name == "Interlude" then
		local found
		for _ = 1, 60 do
			found = findText("just hatched") or findText("egg hatching")
			if found then
				break
			end
			task.wait(0.25)
		end
		log("interlude text:", found)
	elseif name == "Training" then
		task.wait(25)
		local kinds = {}
		for kind, count in bubbleKinds do
			table.insert(kinds, kind .. "=" .. count)
		end
		log("bubbles", table.concat(kinds, ","), "rainbowShown", rainbowShown)
	elseif name == "Pets" then
		task.wait(2)
		PanelController:Open("Incubator")
		task.wait(1)
		local choices = PanelController:Get("Incubator").Body:FindFirstChild("Choices", true)
		if choices then
			local items = 0
			for _, child in choices:GetChildren() do
				if child:IsA("GuiObject") and child.Visible then
					items += 1
				end
			end
			log(("incubator items=%d canvasY=%d windowY=%d scrolling=%s auto=%s"):format(items, choices.AbsoluteCanvasSize.Y, choices.AbsoluteWindowSize.Y, tostring(choices.ScrollingEnabled), tostring(choices.AutomaticCanvasSize)))
		else
			log("incubator choices missing")
		end
		PanelController:Close()
	elseif name == "Offer" then
		Products.DevProducts.StarterPack.Id = 999
		task.wait(3)
		local panel = PanelController:Get("StarterOffer")
		local body = panel.Body
		log(("offer button=%s label=%s panelOpen=%s amount=%s value=%s sale=%s buy=%s timer=%s"):format(tostring(hud.Offer.Visible), hud.Offer.Label.Text, tostring(panel.Visible and PanelController.Current == panel), body.Amount.Text, body.Value.Text, body.Sale.Text.Text, body.Buy.Label.Text, body.Timer.Text))
		task.wait(5)
		log(("offer after bought button=%s panelCurrent=%s"):format(tostring(hud.Offer.Visible), tostring(PanelController.Current and PanelController.Current.Name)))
	end
end

stage.Changed:Connect(function(value)
	task.spawn(onStage, value)
end)
if stage.Value ~= "" then
	task.spawn(onStage, stage.Value)
end
