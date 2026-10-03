local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(maxPerWindow: number, window: number)
	return setmetatable({
		Max = maxPerWindow,
		Window = window,
		Buckets = {},
	}, RateLimiter)
end

function RateLimiter:Check(key: any): boolean
	local now = os.clock()
	local bucket = self.Buckets[key]
	if not bucket or now - bucket.Start >= self.Window then
		self.Buckets[key] = { Start = now, Count = 1 }
		return true
	end
	if bucket.Count >= self.Max then
		return false
	end
	bucket.Count += 1
	return true
end

function RateLimiter:Remove(key: any)
	self.Buckets[key] = nil
end

return RateLimiter
