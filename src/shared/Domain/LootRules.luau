--!strict

local LootRules = {}

export type LootOutcome = {
	kind: "rag" | "coins" | "nothing",
	coins: number,
}

local function boundedRoll(roll: number): number
	return math.clamp(math.floor(roll), 1, 100)
end

function LootRules.rollTrashCan(hasFoundRag: boolean, roll: number): LootOutcome
	local value = boundedRoll(roll)
	if not hasFoundRag then
		if value <= 40 then
			return { kind = "rag", coins = 0 }
		elseif value <= 60 then
			return { kind = "coins", coins = 10 }
		end
		return { kind = "nothing", coins = 0 }
	end

	if value <= 60 then
		return { kind = "coins", coins = 10 }
	elseif value <= 90 then
		return { kind = "coins", coins = 30 }
	end
	return { kind = "coins", coins = 75 }
end

function LootRules.rollDumpster(
	hasFoundRag: boolean,
	roll: number,
	multiplier: number?
): LootOutcome
	local outcome = LootRules.rollTrashCan(hasFoundRag, roll)
	if outcome.kind ~= "coins" then
		return outcome
	end
	return {
		kind = "coins",
		coins = outcome.coins * (multiplier or 2),
	}
end

return LootRules
