local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local TravelRules = require(ReplicatedStorage.Shared.Domain.TravelRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("TravelRules", function()
	it("requires both the configured level and ladder", function()
		local allowedAtLowLevel, levelMessage =
			TravelRules.checkProgression(9, true, 10, true, "Aircraft Yard")
		local allowedWithoutLadder, ladderMessage =
			TravelRules.checkProgression(10, false, 10, true, "Aircraft Yard")

		expect(allowedAtLowLevel).toBe(false)
		expect(levelMessage).toBe("Level 10 required for Aircraft Yard.")
		expect(allowedWithoutLadder).toBe(false)
		expect(ladderMessage).toBe("Place your Salvage Ladder before unlocking the Aircraft Yard.")
	end)

	it("allows destinations with completed progression", function()
		local allowed = TravelRules.checkProgression(10, true, 10, true, "Aircraft Yard")
		expect(allowed).toBe(true)
	end)
end)
