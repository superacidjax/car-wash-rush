local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local Rules = require(ReplicatedStorage.Shared.Domain.AdvancedCleaningRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("AdvancedCleaningRules", function()
	it("converts traced distance into bounded progress units with carry", function()
		local units, carry = Rules.traceUnits(55, 0, 24)
		expect(units).toBe(2)
		expect(carry).toBe(7)
		local nextUnits, nextCarry = Rules.traceUnits(17, carry, 24)
		expect(nextUnits).toBe(1)
		expect(nextCarry).toBe(0)
	end)
end)
