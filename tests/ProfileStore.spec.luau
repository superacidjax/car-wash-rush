local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local ProfileStore = require(ServerScriptService.Infrastructure.ProfileStore)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

local function fakeDataStore(initial)
	local values = initial or {}
	local store = {}

	function store:UpdateAsync(key, transform)
		local result = transform(values[key])
		if result ~= nil then
			values[key] = result
		end
		return result
	end

	function store:get(key)
		return values[key]
	end

	return store
end

local function newRepository(store, sessionId, now)
	return ProfileStore.new({
		store = store,
		sessionId = sessionId,
		now = function()
			return now.value
		end,
		wait = function() end,
		normalize = function(raw)
			return raw or { coins = 0 }
		end,
		leaseSeconds = 100,
		retryCount = 2,
	})
end

describe("ProfileStore", function()
	it("acquires and releases an owned session", function()
		local store = fakeDataStore({ player_1 = { coins = 9 } })
		local now = { value = 1000 }
		local repository = newRepository(store, "server-a", now)
		local profile, acquireError = repository:acquire("player_1")

		expect(acquireError).toBeNil()
		expect(profile.coins).toBe(9)
		expect(store:get("player_1").session.id).toBe("server-a")
		expect(repository:release("player_1")).toBe(true)
		expect(store:get("player_1").session).toBeNil()
	end)

	it("blocks a second live server until the lease expires", function()
		local store = fakeDataStore()
		local now = { value = 1000 }
		local first = newRepository(store, "server-a", now)
		local second = newRepository(store, "server-b", now)
		expect(first:acquire("player_1")).never.toBeNil()

		local profile, acquireError = second:acquire("player_1")
		expect(profile).toBeNil()
		expect(acquireError).toBe("profile is active in another server")

		now.value = 1101
		expect(second:acquire("player_1")).never.toBeNil()
	end)

	it("refuses a save after session ownership is lost", function()
		local store = fakeDataStore()
		local now = { value = 1000 }
		local first = newRepository(store, "server-a", now)
		local second = newRepository(store, "server-b", now)
		first:acquire("player_1")
		now.value = 1101
		second:acquire("player_1")

		local success, saveError = first:save("player_1", { coins = 999 })
		expect(success).toBe(false)
		expect(saveError).toBe("profile session ownership was lost")
		expect(store:get("player_1").data.coins).toBe(0)
	end)

	it("saves an immutable snapshot", function()
		local store = fakeDataStore()
		local now = { value = 1000 }
		local repository = newRepository(store, "server-a", now)
		repository:acquire("player_1")
		local profile = { coins = 10, inventory = { { durability = 20 } } }
		expect(repository:save("player_1", profile)).toBe(true)

		profile.coins = 500
		profile.inventory[1].durability = 0
		expect(store:get("player_1").data.coins).toBe(10)
		expect(store:get("player_1").data.inventory[1].durability).toBe(20)
	end)
end)
