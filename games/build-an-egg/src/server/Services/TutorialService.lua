local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TutorialConfig = require(Shared.Config.Tutorial)
local Names = require(Shared.Config.Names)
local RateLimiter = require(Shared.Util.RateLimiter)

local TutorialService = {}

local DataService
local StateService
local OfferService
local FunnelService
local remotes

local limiter = RateLimiter.new(10, 1)

function TutorialService:Init(modules, context)
	DataService = modules.DataService
	StateService = modules.StateService
	OfferService = modules.OfferService
	FunnelService = modules.FunnelService
	remotes = context.Remotes
end

function TutorialService:Start()
	remotes[Names.Remotes.Tutorial].OnServerEvent:Connect(function(player, step)
		if limiter:Check(player) then
			self:SetStep(player, step)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		limiter:Remove(player)
	end)
end

function TutorialService:SetStep(player, step)
	local data = DataService:Get(player)
	if not data or type(step) ~= "number" or step ~= step then
		return
	end
	step = math.clamp(math.floor(step), 0, #TutorialConfig.Steps)
	local previous = data.TutorialStep or 0
	if step > previous then
		data.TutorialStep = step
		if FunnelService then
			for completed = previous + 1, step do
				FunnelService:Onboarding(player, completed)
			end
		end
		DataService:MarkDirty(player)
		StateService:Dirty(player)
		if OfferService then
			OfferService:Check(player)
		end
	end
end

return TutorialService
