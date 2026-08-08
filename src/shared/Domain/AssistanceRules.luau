--!strict

local AssistanceRules = {}

function AssistanceRules.isValidMode(mode: any): boolean
	return type(mode) == "string" and table.find({ "private", "friends", "open" }, mode) ~= nil
end

function AssistanceRules.canAssist(mode: string, isFriend: boolean): boolean
	if mode == "open" then
		return true
	end
	return mode == "friends" and isFriend
end

function AssistanceRules.helperWage(completionCoins: number, multiplier: number): number
	return math.max(0, math.floor(completionCoins * multiplier + 0.5))
end

function AssistanceRules.ownerBonus(completionCoins: number, multiplier: number): number
	return math.max(0, math.floor(completionCoins * multiplier + 0.5))
end

return AssistanceRules
