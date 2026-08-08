--!strict

local PurchaseRules = {}

function PurchaseRules.shortfall(balance: number, price: number): number
	return math.max(0, math.floor(price) - math.max(0, math.floor(balance)))
end

function PurchaseRules.cannotAffordMessage(balance: number, price: number): string
	local missing = PurchaseRules.shortfall(balance, price)
	return string.format("You can't afford that. You need %d more coins.", missing)
end

return PurchaseRules
