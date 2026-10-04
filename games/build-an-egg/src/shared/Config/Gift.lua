return {
	RequireGroup = true,
	FavoriteWait = 20,
	GroupPrompt = { First = 300, Every = 900 },
	SocialPrompt = { First = 480, Every = 1500 },
	Rewards = {
		MinStat = 1500,
		StatShare = 0.1,
		MinCoins = 1000,
		CoinsPerCapacity = 2,
		MinShells = 100,
		ShellShare = 0.5,
	},
	Lines = {
		{ Key = "Shells", Icon = "🥚", Format = "+%s shells in your backpack" },
		{ Key = "Coins", Icon = "💰", Format = "+%s coins" },
		{ Key = "Speed", Icon = "⚡", Format = "+%s Speed" },
		{ Key = "Strength", Icon = "💪", Format = "+%s Strength" },
	},
}
