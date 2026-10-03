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

local profile
local spin

function EggShape.ShellRadius(height: number): number
	local fraction = (height - EggConfig.Center.Y - EggConfig.BaseOffset) / EggConfig.Height
	if fraction < 0 or fraction > 1 then
		return 0
	end
	return EggShape.Radius(fraction)
end

local function buildProfile()
	profile, spin = {}, {}
	local step = EggConfig.ScaffoldProfileStep
	local run = step / math.tan(math.rad(EggConfig.ScaffoldMaxAngle))
	local count = math.ceil(EggShape.ScaffoldHeight() / step)
	local widestAbove = {}
	local widest = 0
	for index = count, 0, -1 do
		widest = math.max(widest, EggShape.ShellRadius(EggConfig.Center.Y + index * step))
		widestAbove[index] = widest
	end
	local half = EggConfig.ScaffoldWidth / 2
	local nest = EggConfig.ScaffoldNestRadius + half
	local angle = 0
	for index = 0, count do
		local height = index * step
		local hug = widestAbove[index] + EggConfig.ScaffoldShellClearance + half
		local blend = math.clamp((height - EggConfig.ScaffoldNestTop) / EggConfig.ScaffoldNestBlend, 0, 1)
		blend = blend * blend * (3 - 2 * blend)
		local distance = math.max(hug, nest + (hug - nest) * blend)
		if index > 0 then
			local radial = distance - profile[index - 1]
			local tangential = math.sqrt(math.max(run * run - radial * radial, 0))
			angle += tangential / ((distance + profile[index - 1]) / 2)
		end
		profile[index] = distance
		spin[index] = angle
	end
end

local function sample(list, height)
	if not profile then
		buildProfile()
	end
	local position = math.clamp((height - EggConfig.Center.Y) / EggConfig.ScaffoldProfileStep, 0, #profile)
	local low = math.floor(position)
	local high = math.min(low + 1, #profile)
	return list[low] + (list[high] - list[low]) * (position - low)
end

function EggShape.ScaffoldDistance(height: number): number
	if not profile then
		buildProfile()
	end
	return sample(profile, height)
end

function EggShape.ScaffoldAngle(height: number): number
	if not profile then
		buildProfile()
	end
	return sample(spin, height) * EggConfig.ScaffoldSpin
end

function EggShape.ScaffoldPoint(height: number): (Vector3, number)
	local angle = EggShape.ScaffoldAngle(height)
	local direction = CFrame.Angles(0, angle, 0):VectorToWorldSpace(EggConfig.ScaffoldDirection.Unit)
	local center = EggConfig.Center
	local distance = EggShape.ScaffoldDistance(height)
	return Vector3.new(center.X + direction.X * distance, height, center.Z + direction.Z * distance), angle
end

function EggShape.RampSegment(ringIndex: number): (Vector3, Vector3)
	local lowHeight = ringIndex > 1 and EggShape.BandHeight(ringIndex - 1) or EggConfig.Center.Y
	return EggShape.ScaffoldPoint(lowHeight), EggShape.ScaffoldPoint(EggShape.BandHeight(ringIndex))
end

function EggShape.InBand(position: Vector3, ringIndex: number, reachMultiplier: number, tolerance: number): boolean
	local bandY = EggShape.BandHeight(ringIndex)
	local feetY = position.Y - EggConfig.StandHeight
	local vertical = EggConfig.BandVerticalReach * reachMultiplier + tolerance
	if math.abs(feetY - bandY) > vertical then
		return false
	end
	local stair = EggShape.ScaffoldPoint(feetY)
	local flat = Vector2.new(position.X - stair.X, position.Z - stair.Z).Magnitude
	local outer = EggConfig.ScaffoldWidth / 2 + EggConfig.BandHorizontalReach * reachMultiplier + tolerance
	return flat <= outer
end

return EggShape
