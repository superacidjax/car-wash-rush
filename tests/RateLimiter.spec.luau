local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local RateLimiter = require(ServerScriptService.Infrastructure.RateLimiter)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("RateLimiter", function()
	it("allows a burst and then rejects excess calls", function()
		local now = 0
		local limiter = RateLimiter.new(function()
			return now
		end)
		expect(limiter:allow("player", "click", 2, 3)).toBe(true)
		expect(limiter:allow("player", "click", 2, 3)).toBe(true)
		expect(limiter:allow("player", "click", 2, 3)).toBe(true)
		expect(limiter:allow("player", "click", 2, 3)).toBe(false)
	end)

	it("refills over time and isolates actions", function()
		local now = 0
		local limiter = RateLimiter.new(function()
			return now
		end)
		expect(limiter:allow("player", "click", 2, 1)).toBe(true)
		expect(limiter:allow("player", "buy", 2, 1)).toBe(true)
		expect(limiter:allow("player", "click", 2, 1)).toBe(false)
		now = 0.5
		expect(limiter:allow("player", "click", 2, 1)).toBe(true)
	end)

	it("forgets disconnected players", function()
		local limiter = RateLimiter.new(function()
			return 0
		end)
		limiter:allow("player", "click", 1, 1)
		expect(limiter:allow("player", "click", 1, 1)).toBe(false)
		limiter:forget("player")
		expect(limiter:allow("player", "click", 1, 1)).toBe(true)
	end)
end)
