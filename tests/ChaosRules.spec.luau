local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local ChaosRules = require(ReplicatedStorage.Shared.Domain.ChaosRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("ChaosRules", function()
	it("protects the first three completed cars", function()
		expect(ChaosRules.choose(2, 3, false, 0.12, 0.01, 0, { "roll" })).toBeNil()
		expect(ChaosRules.choose(3, 3, false, 0.12, 0.01, 0, { "roll" })).toBe("roll")
	end)

	it("prevents consecutive chaos vehicles and respects the chance", function()
		expect(ChaosRules.choose(10, 3, true, 0.12, 0.01, 0, { "roll" })).toBeNil()
		expect(ChaosRules.choose(10, 3, false, 0.12, 0.13, 0, { "roll" })).toBeNil()
	end)

	it("selects between the approved chaos types", function()
		local types = { "customer_roll", "unusual_dirt" }
		expect(ChaosRules.choose(10, 3, false, 0.12, 0.1, 0.1, types)).toBe("customer_roll")
		expect(ChaosRules.choose(10, 3, false, 0.12, 0.1, 0.9, types)).toBe("unusual_dirt")
	end)
end)
