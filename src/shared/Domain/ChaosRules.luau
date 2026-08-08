--!strict

local ChaosRules = {}

function ChaosRules.choose(
	completedCars: number,
	protectedCars: number,
	previousVehicleHadChaos: boolean,
	chance: number,
	roll: number,
	typeRoll: number,
	types: { string }
): string?
	if completedCars < protectedCars or previousVehicleHadChaos or roll > chance or #types == 0 then
		return nil
	end
	local index = math.clamp(math.floor(typeRoll * #types) + 1, 1, #types)
	return types[index]
end

return ChaosRules
