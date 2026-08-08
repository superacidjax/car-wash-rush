--!strict

local InteractionRules = {}

function InteractionRules.hasCompletedHold(
	startedAt: number?,
	now: number,
	requiredSeconds: number,
	tolerance: number?
): boolean
	if startedAt == nil or now < startedAt then
		return false
	end
	return now - startedAt >= math.max(0, requiredSeconds - (tolerance or 0.1))
end

return InteractionRules
