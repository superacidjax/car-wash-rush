local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local Config = require(ReplicatedStorage.Shared.Config)
local DemandRules = require(ReplicatedStorage.Shared.Domain.DemandRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("DemandRules", function()
	it("returns identical global state for servers using the same timestamp", function()
		local first = DemandRules.stateAt(1_800_000_123, Config.Demand)
		local second = DemandRules.stateAt(1_800_000_123, Config.Demand)
		expect(first.id).toBe(second.id)
		expect(first.endsAt).toBe(second.endsAt)
	end)

	it("moves to the next globally scheduled event every twenty minutes", function()
		local first = DemandRules.stateAt(1_800_000_000, Config.Demand)
		local second =
			DemandRules.stateAt(1_800_000_000 + Config.Demand.IntervalSeconds, Config.Demand)
		expect(first.id == second.id).toBe(false)
		expect(second.startsAt - first.startsAt).toBe(Config.Demand.IntervalSeconds)
	end)

	it("only buffs manual tools during a power shortage", function()
		local state = {
			active = true,
			eventId = "power_shortage",
			coinMultiplier = 1,
			manualToolMultiplier = 1.35,
		}
		expect(DemandRules.coinMultiplier(state, "tool_rag")).toBe(1.35)
		expect(DemandRules.coinMultiplier(state, "tool_pressure_washer")).toBe(1)
	end)
end)
