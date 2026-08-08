local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local CleaningRules = require(ReplicatedStorage.Shared.Domain.CleaningRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("CleaningRules", function()
	it("requires a tool that meets the vehicle cleaning tier", function()
		expect(CleaningRules.canClean(1, 1)).toBe(true)
		expect(CleaningRules.canClean(1, 2)).toBe(false)
		expect(CleaningRules.canClean(2, 2)).toBe(true)
	end)
end)
