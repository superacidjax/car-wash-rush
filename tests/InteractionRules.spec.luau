local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local InteractionRules = require(ReplicatedStorage.Shared.Domain.InteractionRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("InteractionRules", function()
	it("rejects absent, reversed, and incomplete holds", function()
		expect(InteractionRules.hasCompletedHold(nil, 10, 6)).toBe(false)
		expect(InteractionRules.hasCompletedHold(11, 10, 6)).toBe(false)
		expect(InteractionRules.hasCompletedHold(10, 15.8, 6, 0.1)).toBe(false)
	end)

	it("allows a completed hold with small engine timing tolerance", function()
		expect(InteractionRules.hasCompletedHold(10, 15.9, 6, 0.1)).toBe(true)
	end)
end)
