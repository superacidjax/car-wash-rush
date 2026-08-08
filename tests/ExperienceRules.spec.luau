local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local ExperienceRules = require(ReplicatedStorage.Shared.Domain.ExperienceRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("ExperienceRules", function()
	it("rounds every requirement upward to the next ten", function()
		expect(ExperienceRules.requirementForLevel(0)).toBe(50)
		expect(ExperienceRules.requirementForLevel(1)).toBe(70)
		expect(ExperienceRules.requirementForLevel(2)).toBe(80)
	end)

	it("applies enough experience to cross multiple levels", function()
		local level, experience, levelsGained = ExperienceRules.applyExperience(0, 0, 125)
		expect(level).toBe(2)
		expect(experience).toBe(5)
		expect(levelsGained).toBe(2)
	end)
end)
