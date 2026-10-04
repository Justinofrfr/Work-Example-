return {
	StorePrefix = "BuildAnEgg_LB_v1_",
	Rows = 10,
	RefreshInterval = 120,
	Boards = {
		{ Key = "Eggs", Field = "Eggs", Title = "🥚 MOST EGGS", Color = Color3.fromRGB(255, 220, 120) },
		{ Key = "Pieces", Field = "PiecesPlaced", Title = "🧱 MOST PIECES", Color = Color3.fromRGB(160, 230, 255) },
		{ Key = "Speed", Field = "Speed", Title = "⚡ FASTEST", Color = Color3.fromRGB(120, 210, 255) },
		{ Key = "Strength", Field = "Strength", Title = "💪 STRONGEST", Color = Color3.fromRGB(255, 140, 110) },
	},
	Positions = {
		Vector3.new(-52, 0, -332),
		Vector3.new(-20, 0, -357),
		Vector3.new(20, 0, -357),
		Vector3.new(52, 0, -332),
	},
	BoardSize = Vector3.new(22, 30, 1.5),
	FacingTarget = Vector3.new(0, 0, -290),
}
