local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local InventoryRules = require(ReplicatedStorage.Shared.Domain.InventoryRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("InventoryRules", function()
	it("reduces resale value with durability", function()
		expect(InventoryRules.resaleValue(60, 75, 75)).toBe(60)
		expect(InventoryRules.resaleValue(60, 25, 75)).toBe(20)
	end)

	it("caps quality charge until it is claimed", function()
		expect(InventoryRules.addQualityCharge(9, 3, 10)).toBe(10)
		expect(InventoryRules.canClaimQualityCharge(10, 10)).toBe(true)
	end)
end)
