--!strict

local ServerCapacityRules = {}

function ServerCapacityRules.firstAvailableSlot(
	occupiedSlots: { [number]: boolean },
	maximumPlayers: number
): number?
	for slotIndex = 1, math.max(0, math.floor(maximumPlayers)) do
		if not occupiedSlots[slotIndex] then
			return slotIndex
		end
	end
	return nil
end

return ServerCapacityRules
