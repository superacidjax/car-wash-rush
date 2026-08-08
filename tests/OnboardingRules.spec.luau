local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local OnboardingRules = require(ReplicatedStorage.Shared.Domain.OnboardingRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("OnboardingRules", function()
	it("allows a missing-rag player one attempt at a shared emptied can", function()
		local firstAttempt = OnboardingRules.canSearchSharedCan(false, true, false)
		local repeatedAttempt = OnboardingRules.canSearchSharedCan(false, true, true)
		expect(firstAttempt).toBe(true)
		expect(repeatedAttempt).toBe(false)
	end)

	it("keeps shared coin loot depleted", function()
		expect(OnboardingRules.canAwardSharedCoins(false)).toBe(true)
		expect(OnboardingRules.canAwardSharedCoins(true)).toBe(false)
	end)

	it("rejects globally emptied cans after onboarding", function()
		local allowed = OnboardingRules.canSearchSharedCan(true, true, false)
		expect(allowed).toBe(false)
	end)
end)
