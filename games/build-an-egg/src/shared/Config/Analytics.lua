return {
	Onboarding = {
		JoinedStep = "Joined",
	},
	Funnels = {
		Shop = {
			Panel = "Shop",
			Steps = { "OpenShop", "ClickBuy", "Purchased" },
		},
		StarterOffer = {
			Panel = "StarterOffer",
			Steps = { "OfferShown", "OpenOffer", "ClickBuy", "Purchased" },
		},
	},
	ClientEvents = {
		Open = true,
		Shown = true,
		Buy = true,
	},
	RateLimit = { Count = 12, Window = 5 },
}
