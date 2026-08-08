--!strict

local VehicleRules = {}

function VehicleRules.chooseWeighted(entries: { any }, roll: number): any?
	local totalWeight = 0
	for _, entry in entries do
		totalWeight += math.max(0, entry.Weight)
	end
	if totalWeight <= 0 or #entries == 0 then
		return nil
	end

	local target = math.clamp(roll, 0, 0.999999999) * totalWeight
	local cumulative = 0
	for _, entry in entries do
		cumulative += math.max(0, entry.Weight)
		if target < cumulative then
			return entry
		end
	end
	return entries[#entries]
end

function VehicleRules.nextRvInterval(minimum: number, maximum: number, roll: number): number
	local low = math.floor(math.min(minimum, maximum))
	local high = math.floor(math.max(minimum, maximum))
	return low + math.floor(math.clamp(roll, 0, 0.999999999) * (high - low + 1))
end

function VehicleRules.chooseNextVehicleId(
	carsSinceRv: number,
	rvInterval: number,
	normalEntries: { any },
	roll: number
): (string?, boolean)
	if carsSinceRv >= rvInterval then
		return "rv", true
	end
	local selected = VehicleRules.chooseWeighted(normalEntries, roll)
	return if selected then selected.Id else nil, false
end

function VehicleRules.nonRepeatingColorIndex(
	colorCount: number,
	previousIndex: number?,
	roll: number
): number?
	if colorCount <= 0 then
		return nil
	end
	if colorCount == 1 then
		return 1
	end

	local previous = math.clamp(previousIndex or 0, 0, colorCount)
	local index = 1 + math.floor(math.clamp(roll, 0, 0.999999999) * (colorCount - 1))
	if previous > 0 and index >= previous then
		index += 1
	end
	return index
end

return VehicleRules
