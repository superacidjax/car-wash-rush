--!strict

local CooperativeEventRules = {}

function CooperativeEventRules.phaseGoal(baseGoal: number, nearbyParticipants: number): number
	return math.max(1, math.floor(baseGoal)) * math.clamp(math.floor(nearbyParticipants), 1, 4)
end

function CooperativeEventRules.phaseToken(contribution: number): number
	return if contribution >= 2 then 1 else 0
end

function CooperativeEventRules.isMeaningful(totalContribution: number, minimum: number): boolean
	return totalContribution >= minimum
end

function CooperativeEventRules.completionTokens(
	playerContribution: number,
	totalContribution: number,
	meaningfulParticipants: number,
	comboAlternations: number
): (number, number)
	if playerContribution <= 0 or totalContribution <= 0 then
		return 0, 0
	end
	local share = playerContribution / totalContribution
	local participationTokens = math.clamp(
		4 + math.floor(share * 12) + math.min(3, math.floor(playerContribution / 20)),
		4,
		19
	)
	local comboTokens = 0
	if meaningfulParticipants >= 2 then
		comboTokens = math.clamp(math.floor(comboAlternations / 5), 1, 5)
	end
	return participationTokens, comboTokens
end

return CooperativeEventRules
