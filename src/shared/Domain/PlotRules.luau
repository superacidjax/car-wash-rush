--!strict

local PlotRules = {}

function PlotRules.positionForSlot(
	slotIndex: number,
	columns: number?,
	spacingX: number?,
	spacingZ: number?,
	origin: Vector3?
): Vector3
	local columnCount = math.max(1, math.floor(columns or 6))
	local index = math.max(1, math.floor(slotIndex)) - 1
	local row = math.floor(index / columnCount)
	local column = index % columnCount
	local base = origin or Vector3.new(-350, 0, 180)
	return base + Vector3.new(column * (spacingX or 140), 0, row * (spacingZ or 115))
end

return PlotRules
