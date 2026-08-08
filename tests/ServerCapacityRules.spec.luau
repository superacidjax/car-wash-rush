local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local Rules = require(ReplicatedStorage.Shared.Domain.ServerCapacityRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("ServerCapacityRules", function()
	it("never allocates a ninth prototype bay", function()
		local occupied = {}
		for index = 1, 8 do
			occupied[index] = true
		end
		expect(Rules.firstAvailableSlot(occupied, 8)).toBeNil()
	end)

	it("reuses a released slot inside the cap", function()
		expect(Rules.firstAvailableSlot({ [1] = true, [3] = true }, 8)).toBe(2)
	end)
end)
