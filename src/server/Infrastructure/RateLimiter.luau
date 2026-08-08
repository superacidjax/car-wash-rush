--!strict

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = typeof(setmetatable(
	{} :: {
		now: () -> number,
		buckets: { [any]: { [string]: { tokens: number, updatedAt: number } } },
	},
	RateLimiter
))

function RateLimiter.new(now: (() -> number)?): RateLimiter
	return setmetatable({
		now = now or os.clock,
		buckets = {},
	}, RateLimiter)
end

function RateLimiter:allow(subject: any, action: string, rate: number, burst: number): boolean
	if rate <= 0 or burst <= 0 then
		return false
	end
	local now = self.now()
	local subjectBuckets = self.buckets[subject]
	if not subjectBuckets then
		subjectBuckets = {}
		self.buckets[subject] = subjectBuckets
	end
	local bucket = subjectBuckets[action]
	if not bucket then
		bucket = { tokens = burst, updatedAt = now }
		subjectBuckets[action] = bucket
	end

	local elapsed = math.max(0, now - bucket.updatedAt)
	bucket.tokens = math.min(burst, bucket.tokens + elapsed * rate)
	bucket.updatedAt = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RateLimiter:forget(subject: any)
	self.buckets[subject] = nil
end

return RateLimiter
