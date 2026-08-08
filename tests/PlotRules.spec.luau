local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)
local PlotRules = require(ReplicatedStorage.Shared.Domain.PlotRules)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("PlotRules", function()
	it("allocates stable rows without a fixed player cap", function()
		expect(PlotRules.positionForSlot(1)).toEqual(Vector3.new(-350, 0, 180))
		expect(PlotRules.positionForSlot(6)).toEqual(Vector3.new(350, 0, 180))
		expect(PlotRules.positionForSlot(7)).toEqual(Vector3.new(-350, 0, 295))
		expect(PlotRules.positionForSlot(100)).toEqual(Vector3.new(70, 0, 2020))
	end)
end)
