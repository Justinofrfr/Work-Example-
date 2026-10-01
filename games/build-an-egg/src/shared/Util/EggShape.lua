local Shared = script.Parent.Parent
local EggConfig = require(Shared.Config.Egg)
local GameConfig = require(Shared.Config.Game)

local EggShape = {}

local ringCache
local totalSegments = 0

function EggShape.Radius(fraction: number): number
	local widest = EggConfig.WidestFraction
	local span = fraction < widest and widest or (1 - widest)
	local t = (fraction - widest) / span
	return EggConfig.MaxRadius * math.sqrt(math.max(0, 1 - t * t))
end

function EggShape.RingHeight(index: number): (number, number)
	local step = EggConfig.Height / GameConfig.RingCount
	local base = EggConfig.Center.Y + EggConfig.BaseOffset
	return base + (index - 1) * step, base + index * step
end

local function build()
	ringCache = {}
	totalSegments = 0
	local count = GameConfig.RingCount
	for index = 1, count do
		local bottom, top = EggShape.RingHeight(index)
		local r0 = math.max(EggShape.Radius((index - 1) / count), 2)
		local r1 = math.max(EggShape.Radius(index / count), 2)
		local mid = (r0 + r1) / 2
		local segments = math.max(EggConfig.MinSegments, math.floor(2 * math.pi * mid / EggConfig.SegmentArcLength))
		ringCache[index] = {
			Index = index,
			Bottom = bottom,
			Top = top,
			BottomRadius = r0,
			TopRadius = r1,
			Radius = mid,
			Segments = segments,
			First = totalSegments + 1,
		}
		totalSegments += segments
	end
end

function EggShape.Rings()
	if not ringCache then
		build()
	end
	return ringCache
end

function EggShape.TotalSegments(): number
	EggShape.Rings()
	return totalSegments
end

function EggShape.VisibleSegments(progress: number, target: number): number
	if target <= 0 then
		return 0
	end
	return math.clamp(math.floor(progress / target * EggShape.TotalSegments()), 0, EggShape.TotalSegments())
end

function EggShape.ActiveRing(progress: number, target: number): number
	local nextSegment = EggShape.VisibleSegments(progress, target) + 1
	for _, ring in EggShape.Rings() do
		if nextSegment < ring.First + ring.Segments then
			return ring.Index
		end
	end
	return GameConfig.RingCount
end

function EggShape.BandHeight(ringIndex: number): number
	local ring = EggShape.Rings()[ringIndex]
	return (ring.Bottom + ring.Top) / 2
end

function EggShape.ScaffoldHeight(): number
	return EggConfig.Height + EggConfig.BaseOffset
end

function EggShape.ScaffoldPoint(height: number): (Vector3, number)
	local fraction = math.clamp((height - EggConfig.Center.Y) / EggShape.ScaffoldHeight(), 0, 1)
	local angle = EggConfig.ScaffoldStartAngle + fraction * EggConfig.ScaffoldTurns * 2 * math.pi
	local center = EggConfig.Center
	local point = Vector3.new(center.X + math.cos(angle) * EggConfig.ScaffoldRadius, height, center.Z + math.sin(angle) * EggConfig.ScaffoldRadius)
	return point, angle
end

function EggShape.InBand(position: Vector3, ringIndex: number, reachMultiplier: number, tolerance: number): boolean
	local bandY = EggShape.BandHeight(ringIndex)
	local feetY = position.Y - EggConfig.StandHeight
	local vertical = EggConfig.BandVerticalReach * reachMultiplier + tolerance
	if math.abs(feetY - bandY) > vertical then
		return false
	end
	local center = EggConfig.Center
	local flat = Vector2.new(position.X - center.X, position.Z - center.Z).Magnitude
	local outer = EggConfig.ScaffoldRadius + EggConfig.ScaffoldWidth / 2 + EggConfig.BandHorizontalReach * reachMultiplier + tolerance
	return flat <= outer
end

return EggShape
