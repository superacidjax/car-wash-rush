local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local PurchaseRules = require(ReplicatedStorage.Shared.Domain.PurchaseRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("PurchaseRules", function()
	it("calculates the missing coins without returning a negative number", function()
		expect(PurchaseRules.shortfall(40, 100)).toBe(60)
		expect(PurchaseRules.shortfall(120, 100)).toBe(0)
	end)

	it("uses the shared unaffordable message", function()
		expect(PurchaseRules.cannotAffordMessage(40, 100)).toBe(
			"You can't afford that. You need 60 more coins."
		)
	end)
end)
