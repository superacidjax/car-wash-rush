--!strict

local TravelRules = {}

function TravelRules.checkProgression(
	level: number,
	ladderPlaced: boolean,
	minimumLevel: number?,
	requiresLadder: boolean?,
	displayName: string
): (boolean, string)
	if minimumLevel and level < minimumLevel then
		return false, string.format("Level %d required for %s.", minimumLevel, displayName)
	end
	if requiresLadder and not ladderPlaced then
		return false, "Place your Salvage Ladder before unlocking the Aircraft Yard."
	end
	return true, ""
end

return TravelRules
