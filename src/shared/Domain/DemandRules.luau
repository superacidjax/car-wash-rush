--!strict

local DemandRules = {}

local function deterministicValue(slot: number, salt: number): number
	return math.abs((slot * 1103515245 + salt * 12345) % 2147483647)
end

function DemandRules.stateAt(unixTimestamp: number, demandConfig: any): any
	local now = math.floor(unixTimestamp)
	local interval = demandConfig.IntervalSeconds
	local slot = math.floor(now / interval)
	local startsAt = slot * interval
	local durationRange = demandConfig.MaximumDurationSeconds
		- demandConfig.MinimumDurationSeconds
		+ 1
	local duration = demandConfig.MinimumDurationSeconds
		+ deterministicValue(slot, 17) % durationRange
	local endsAt = startsAt + duration
	local eventIndex = deterministicValue(slot, 41) % #demandConfig.Events + 1
	local definition = demandConfig.Events[eventIndex]
	local active = now < endsAt

	return {
		id = string.format("%s_%d", definition.Id, slot),
		eventId = definition.Id,
		displayName = definition.DisplayName,
		description = definition.Description,
		coinMultiplier = definition.CoinMultiplier,
		manualToolMultiplier = definition.ManualToolMultiplier or 1,
		startsAt = startsAt,
		endsAt = endsAt,
		nextStartsAt = startsAt + interval,
		active = active,
	}
end

function DemandRules.coinMultiplier(state: any, toolId: string?): number
	if not state or not state.active then
		return 1
	end
	if
		state.eventId == "power_shortage"
		and toolId ~= nil
		and table.find({ "tool_old_rag", "tool_rag", "tool_sponge", "tool_quality_sponge" }, toolId)
	then
		return state.manualToolMultiplier
	end
	return state.coinMultiplier
end

return DemandRules
