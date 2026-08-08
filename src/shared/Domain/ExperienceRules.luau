--!strict

local ExperienceRules = {}

function ExperienceRules.roundUpToTen(value: number): number
	if value <= 0 then
		return 0
	end
	return math.ceil(value / 10) * 10
end

function ExperienceRules.requirementForLevel(
	level: number,
	firstRequirement: number?,
	multiplier: number?
): number
	local first = firstRequirement or 50
	local growth = multiplier or 1.25
	return ExperienceRules.roundUpToTen(first * growth ^ math.max(0, level))
end

function ExperienceRules.applyExperience(
	level: number,
	experience: number,
	amount: number,
	firstRequirement: number?,
	multiplier: number?
): (number, number, number)
	local nextLevel = math.max(0, math.floor(level))
	local nextExperience = math.max(0, experience) + math.max(0, amount)
	local levelsGained = 0

	while
		nextExperience
		>= ExperienceRules.requirementForLevel(nextLevel, firstRequirement, multiplier)
	do
		nextExperience -= ExperienceRules.requirementForLevel(
			nextLevel,
			firstRequirement,
			multiplier
		)
		nextLevel += 1
		levelsGained += 1
	end

	return nextLevel, nextExperience, levelsGained
end

return ExperienceRules
