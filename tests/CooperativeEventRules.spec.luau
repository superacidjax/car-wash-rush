local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local Rules = require(ReplicatedStorage.Shared.Domain.CooperativeEventRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("CooperativeEventRules", function()
	it("scales phase work for one through four nearby participants", function()
		expect(Rules.phaseGoal(24, 0)).toBe(24)
		expect(Rules.phaseGoal(24, 3)).toBe(72)
		expect(Rules.phaseGoal(24, 8)).toBe(96)
	end)

	it("only gives phase tokens for meaningful phase work", function()
		expect(Rules.phaseToken(1)).toBe(0)
		expect(Rules.phaseToken(2)).toBe(1)
	end)

	it("keeps completion and combo awards within the approved ranges", function()
		local participation, combo = Rules.completionTokens(40, 80, 2, 30)
		expect(participation >= 4 and participation <= 19).toBe(true)
		expect(combo).toBe(5)
	end)
end)
