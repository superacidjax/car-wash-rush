--!strict

local CleaningRules = {}

function CleaningRules.canClean(toolTier: number?, requiredTier: number?): boolean
	return (toolTier or 0) >= (requiredTier or 1)
end

return CleaningRules
