local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local ProfileSchema = require(ReplicatedStorage.Shared.Domain.ProfileSchema)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("ProfileSchema", function()
	it("migrates the legacy global quality charge to the equipped sponge", function()
		local profile = ProfileSchema.normalize({
			coins = 55,
			qualitySpongeCharge = 7,
			equippedItemId = "quality-2",
			inventory = {
				{ id = "quality-1", toolId = "tool_quality_sponge", durability = 100 },
				{ id = "quality-2", toolId = "tool_quality_sponge", durability = 200 },
			},
		})

		expect(profile.version).toBe(6)
		expect(profile.inventory[1].qualityCharge).toBe(0)
		expect(profile.inventory[2].qualityCharge).toBe(7)
	end)

	it("persists placed ladder access", function()
		local profile = ProfileSchema.normalize({ ladderPlaced = true })

		expect(profile.ladderPlaced).toBe(true)
	end)

	it("persists known teleport unlocks and rejects unknown destinations", function()
		local profile = ProfileSchema.normalize({
			unlockedTeleports = { shop = true, aircraft = true, exploit = true },
		})

		expect(profile.unlockedTeleports.home).toBe(true)
		expect(profile.unlockedTeleports.shop).toBe(true)
		expect(profile.unlockedTeleports.aircraft).toBe(true)
		expect(profile.unlockedTeleports.exploit).toBeNil()
	end)

	it("drops broken or unknown tools and repairs duplicate ids", function()
		local nextId = 0
		local profile = ProfileSchema.normalize({
			inventory = {
				{ id = "same", toolId = "tool_rag", durability = 10 },
				{ id = "same", toolId = "tool_sponge", durability = 10 },
				{ id = "broken", toolId = "tool_rag", durability = 0 },
				{ id = "unknown", toolId = "missing", durability = 10 },
			},
		}, function()
			nextId += 1
			return "generated-" .. nextId
		end)

		expect(#profile.inventory).toBe(2)
		expect(profile.inventory[1].id).toBe("same")
		expect(profile.inventory[2].id).toBe("generated-1")
	end)

	it("does not duplicate an equipped item in a generated hotbar", function()
		local profile = ProfileSchema.normalize({
			equippedItemId = "rag-1",
			inventory = {
				{ id = "rag-1", toolId = "tool_rag", durability = 50 },
			},
		})

		expect(#profile.hotbarItemIds).toBe(1)
		expect(profile.hotbarItemIds[1]).toBe("rag-1")
	end)
end)
