return {
	Order = { "BulkPickup", "BulkPlace", "Range" },
	List = {
		BulkPickup = {
			DisplayName = "Bulk Pickup",
			Costs = { 0, 60, 180, 500, 1400, 3500, 8000, 18000, 40000, 90000, 200000, 450000, 1000000, 2200000, 5000000 },
			PerLevel = 1,
		},
		BulkPlace = {
			DisplayName = "Bulk Place",
			Costs = { 15, 60, 180, 500, 1400, 3500, 8000, 18000, 40000, 90000, 200000, 450000, 1000000 },
			PerLevel = 1,
		},
		Range = {
			DisplayName = "Placement Range",
			Costs = { 10, 40, 120, 350, 1000, 2500, 6000, 14000, 32000, 75000 },
			PerLevel = 0.2,
		},
	},
	FreeText = "FREE",
	RobuxText = "+1 R$%d",
	BuyLayout = {
		Solo = { Size = UDim2.fromScale(0.21, 0.64), Position = UDim2.fromScale(0.97, 0.18) },
		Stacked = { Size = UDim2.fromScale(0.21, 0.44), Position = UDim2.fromScale(0.97, 0.06) },
		Robux = { Size = UDim2.fromScale(0.21, 0.36), Position = UDim2.fromScale(0.97, 0.56) },
	},
}
