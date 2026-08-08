local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local LootRules = require(ReplicatedStorage.Shared.Domain.LootRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("LootRules", function()
	it("uses the onboarding rag and coin boundaries", function()
		expect(LootRules.rollTrashCan(false, 40).kind).toBe("rag")
		expect(LootRules.rollTrashCan(false, 41).coins).toBe(10)
		expect(LootRules.rollTrashCan(false, 60).coins).toBe(10)
		expect(LootRules.rollTrashCan(false, 61).kind).toBe("nothing")
	end)

	it("uses the post-rag reward boundaries", function()
		expect(LootRules.rollTrashCan(true, 60).coins).toBe(10)
		expect(LootRules.rollTrashCan(true, 61).coins).toBe(30)
		expect(LootRules.rollTrashCan(true, 90).coins).toBe(30)
		expect(LootRules.rollTrashCan(true, 91).coins).toBe(75)
	end)

	it("doubles dumpster coin rewards", function()
		expect(LootRules.rollDumpster(true, 91, 2).coins).toBe(150)
	end)
end)
