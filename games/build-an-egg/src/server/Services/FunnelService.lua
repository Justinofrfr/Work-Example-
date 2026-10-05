local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnalyticsConfig = require(Shared.Config.Analytics)
local TutorialConfig = require(Shared.Config.Tutorial)
local ProductsConfig = require(Shared.Config.Products)
local Names = require(Shared.Config.Names)
local RateLimiter = require(Shared.Util.RateLimiter)

local FunnelService = {
	Sessions = {},
}

local DataService
local TrailerService
local remotes

local FUNNELS = AnalyticsConfig.Funnels
local limiter = RateLimiter.new(AnalyticsConfig.RateLimit.Count, AnalyticsConfig.RateLimit.Window)

local function log(method, ...)
	if TrailerService:IsServer() then
		return
	end
	pcall(AnalyticsService[method], AnalyticsService, ...)
end

local function knownKey(key)
	return type(key) == "string" and (ProductsConfig.DevProducts[key] ~= nil or ProductsConfig.GamePasses[key] ~= nil)
end

function FunnelService:Init(modules, context)
	DataService = modules.DataService
	TrailerService = modules.TrailerService
	remotes = context.Remotes
end

function FunnelService:Start()
	DataService.Loaded:Connect(function(player)
		self.Sessions[player] = {}
		local data = DataService:Get(player)
		if data and (data.TutorialStep or 0) < #TutorialConfig.Steps then
			self:Onboarding(player, 0)
		end
	end)
	remotes[Names.Remotes.Funnel].OnServerEvent:Connect(function(player, kind, key)
		if limiter:Check(player) and type(kind) == "string" and AnalyticsConfig.ClientEvents[kind] then
			self:Client(player, kind, key)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.Sessions[player] = nil
		limiter:Remove(player)
	end)
end

function FunnelService:Onboarding(player, completed)
	if completed == 0 then
		log("LogOnboardingFunnelStepEvent", player, 1, AnalyticsConfig.Onboarding.JoinedStep)
		return
	end
	local step = TutorialConfig.Steps[completed]
	if step then
		log("LogOnboardingFunnelStepEvent", player, completed + 1, step.Key)
	end
end

function FunnelService:Step(player, name, index)
	local funnel = FUNNELS[name]
	local sessions = self.Sessions[player]
	if not funnel or not sessions then
		return
	end
	local session = sessions[name]
	if index == 1 then
		session = { Id = HttpService:GenerateGUID(false), Step = 0 }
		sessions[name] = session
	end
	if not session or index <= session.Step then
		return
	end
	session.Step = index
	log("LogFunnelStepEvent", player, name, session.Id, index, funnel.Steps[index])
	if index >= #funnel.Steps then
		sessions[name] = nil
	end
end

function FunnelService:Client(player, kind, key)
	local offerKey = ProductsConfig.StarterOffer.Product
	if kind == "Open" then
		if key == FUNNELS.Shop.Panel then
			self:Step(player, "Shop", 1)
		elseif key == FUNNELS.StarterOffer.Panel then
			self:Step(player, "StarterOffer", 2)
		end
	elseif kind == "Shown" and key == FUNNELS.StarterOffer.Panel then
		self:Step(player, "StarterOffer", 1)
	elseif kind == "Buy" and knownKey(key) then
		if key == offerKey then
			self:Step(player, "StarterOffer", 3)
		else
			self:Step(player, "Shop", 2)
		end
	end
end

function FunnelService:Purchased(player, key)
	if key == ProductsConfig.StarterOffer.Product then
		self:Step(player, "StarterOffer", #FUNNELS.StarterOffer.Steps)
	else
		self:Step(player, "Shop", #FUNNELS.Shop.Steps)
	end
end

return FunnelService
