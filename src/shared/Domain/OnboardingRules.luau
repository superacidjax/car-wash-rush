--!strict

local OnboardingRules = {}

function OnboardingRules.canSearchSharedCan(
	hasFoundRag: boolean,
	isSharedLooted: boolean,
	alreadyTriedForRagThisRefill: boolean
): (boolean, string?)
	if not isSharedLooted then
		return true, nil
	end
	if hasFoundRag then
		return false, "That can has already been looted. Find another one."
	end
	if alreadyTriedForRagThisRefill then
		return false, "You already checked this can for a rag. Find another one."
	end
	return true, nil
end

function OnboardingRules.canAwardSharedCoins(isSharedLooted: boolean): boolean
	return not isSharedLooted
end

return OnboardingRules
