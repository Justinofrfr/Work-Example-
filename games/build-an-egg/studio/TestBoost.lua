local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local results = {}
local function note(...)
	local parts = {}
	for _, value in { ... } do
		table.insert(parts, tostring(value))
	end
	table.insert(results, table.concat(parts, " "))
	print("[boosttest] " .. table.concat(parts, " "))
end

ReplicatedStorage:WaitForChild("__TestLog").OnServerEvent:Connect(function(_, message)
	note("[client]", message)
end)

local ok, err = pcall(function()
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local Services = ServerScriptService.Server.Services
	local DataService = require(Services.DataService)
	local StateService = require(Services.StateService)
	local GymService = require(Services.GymService)
	local Monetization = require(Services.MonetizationService)
	local Products = require(ReplicatedStorage.Shared.Config.Products)
	while not DataService:Get(player) do
		task.wait(0.2)
	end
	task.wait(2)
	local data = DataService:Get(player)
	for _, stat in { "Strength", "Speed" } do
		local key = stat .. "Boost"
		local before = StateService:AwardStat(player, stat, 10)
		local level = data.BoostLevels[key] or 0
		local tier = Products.DevProducts[key].Tiers[level + 1]
		local decision = Monetization:ProcessReceipt({ PlayerId = player.UserId, ProductId = tier.Id, PurchaseId = "test-" .. key .. os.clock(), CurrencySpent = tier.Price })
		local after = StateService:AwardStat(player, stat, 10)
		note(key, "level", level, "->", data.BoostLevels[key], decision, "gain for 10 reps", before, "->", after, "ratio", math.floor(after / math.max(before, 1e-9) * 100 + 0.5) / 100)
	end
	local pad
	for _, candidate in GymService.Pads do
		if candidate:GetAttribute("Tier") == "Gym1" and candidate:GetAttribute("Stat") == "Strength" then
			pad = candidate
			break
		end
	end
	StateService:Teleport(player, pad.CFrame)
	task.wait(1.5)
	local runtime = StateService:Get(player)
	note("training", runtime.Training and runtime.Training.Stat)
	if runtime.Training then
		runtime.Training.NextRainbow = os.clock()
	end
	task.wait(0.6)
	note("rainbow offer", runtime.RainbowOffer and runtime.RainbowOffer.Id, runtime.RainbowOffer and runtime.RainbowOffer.Stat)
	local single = StateService:AwardStat(player, "Strength", 1)
	local strengthBefore = data.Strength
	local decision = Monetization:ProcessReceipt({ PlayerId = player.UserId, ProductId = Products.DevProducts.TrainBoost20.Id, PurchaseId = "test-rainbow" .. os.clock(), CurrencySpent = 9 })
	note("rainbow", decision, "strength gained", data.Strength - strengthBefore, "expected", single * 3 * 20, "timed boost active", (data.TrainBoostUntil or 0) > os.time())
	task.wait(2)
	GymService:Stop(player, true)
end)
if not ok then
	note("TEST ERROR", err)
end
task.wait(1)
StudioTestService:EndTest(table.concat(results, "\n"))
