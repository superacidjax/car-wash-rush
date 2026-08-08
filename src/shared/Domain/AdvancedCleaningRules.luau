--!strict

local AdvancedCleaningRules = {}

function AdvancedCleaningRules.traceUnits(
	distancePixels: number,
	carriedPixels: number,
	pixelsPerUnit: number
): (number, number)
	local total = math.max(0, distancePixels) + math.max(0, carriedPixels)
	local threshold = math.max(1, pixelsPerUnit)
	local units = math.floor(total / threshold)
	return units, total - units * threshold
end

return AdvancedCleaningRules
