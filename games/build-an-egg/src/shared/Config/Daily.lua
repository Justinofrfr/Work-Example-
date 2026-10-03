return {
	DayLength = 86400,
	BaseCoins = 500,
	CoinsPerCapacity = 1,
	MinShells = 50,
	MinStat = 500,
	Days = {
		{ Coins = 1, Shells = 0.25, Stats = 0 },
		{ Coins = 1.5, Shells = 0.35, Stats = 0 },
		{ Coins = 2, Shells = 0.5, Stats = 0.03 },
		{ Coins = 3, Shells = 0.6, Stats = 0 },
		{ Coins = 4, Shells = 0.75, Stats = 0.05 },
		{ Coins = 5, Shells = 0.9, Stats = 0 },
		{ Coins = 8, Shells = 1, Stats = 0.1 },
	},
	AutoOpenDelay = 8,
	AutoOpenAfterTutorial = 7,
	Messages = {
		Claimed = "Come back tomorrow for Day %d!",
		Ready = "Day %d reward ready!",
		Next = "Next reward in %s",
	},
}
