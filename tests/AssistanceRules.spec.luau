local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local Rules = require(ReplicatedStorage.Shared.Domain.AssistanceRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("AssistanceRules", function()
	it("enforces private, friends, and open permissions", function()
		expect(Rules.canAssist("private", true)).toBe(false)
		expect(Rules.canAssist("friends", false)).toBe(false)
		expect(Rules.canAssist("friends", true)).toBe(true)
		expect(Rules.canAssist("open", false)).toBe(true)
	end)

	it("mints the approved helper wage and owner bonus", function()
		expect(Rules.helperWage(100, 0.3)).toBe(30)
		expect(Rules.ownerBonus(100, 0.1)).toBe(10)
	end)
end)
