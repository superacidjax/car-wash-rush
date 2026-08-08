--!strict

local InventoryRules = {}

function InventoryRules.remainingRatio(durability: number, maxDurability: number): number
	if maxDurability <= 0 then
		return 0
	end
	return math.clamp(durability / maxDurability, 0, 1)
end

function InventoryRules.resaleValue(
	baseResaleValue: number,
	durability: number,
	maxDurability: number,
	marketMultiplier: number?
): number
	local value = baseResaleValue
		* InventoryRules.remainingRatio(durability, maxDurability)
		* (marketMultiplier or 1)
	return math.max(0, math.floor(value + 0.5))
end

function InventoryRules.durabilityAfterUse(durability: number, cost: number?): (number, boolean)
	local remaining = math.max(0, durability - (cost or 1))
	return remaining, remaining <= 0
end

function InventoryRules.addQualityCharge(current: number, amount: number, required: number): number
	return math.clamp(current + math.max(0, amount), 0, required)
end

function InventoryRules.canClaimQualityCharge(current: number, required: number): boolean
	return current >= required
end

return InventoryRules
