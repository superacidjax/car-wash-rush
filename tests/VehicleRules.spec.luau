local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local VehicleRules = require(ReplicatedStorage.Shared.Domain.VehicleRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("VehicleRules", function()
	it("selects weighted vehicle boundaries", function()
		local entries = {
			{ Id = "small_car", Weight = 65 },
			{ Id = "pickup_truck", Weight = 35 },
		}
		expect(VehicleRules.chooseWeighted(entries, 0.649).Id).toBe("small_car")
		expect(VehicleRules.chooseWeighted(entries, 0.65).Id).toBe("pickup_truck")
	end)

	it("forces an RV when the interval is reached", function()
		local id, wasRv = VehicleRules.chooseNextVehicleId(8, 8, {}, 0)
		expect(id).toBe("rv")
		expect(wasRv).toBe(true)
	end)

	it("never repeats the previous color", function()
		for step = 0, 20 do
			expect(VehicleRules.nonRepeatingColorIndex(7, 4, step / 21)).never.toBe(4)
		end
	end)
end)
