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
}
