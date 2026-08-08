--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DemandRules = require(ReplicatedStorage.Shared.Domain:WaitForChild("DemandRules"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local DemandSystem = {}

local currentState: any = nil

local function refresh(): any
	local nextState = DemandRules.stateAt(os.time(), Config.Demand)
	local changed = not currentState
		or currentState.id ~= nextState.id
		or currentState.active ~= nextState.active
	currentState = nextState
	if changed then
		Remotes.get("DemandStateUpdated"):FireAllClients(currentState)
	end
	return currentState
end

function DemandSystem.getState(): any
	return refresh()
end

function DemandSystem.getCoinMultiplier(toolId: string?): number
	return DemandRules.coinMultiplier(refresh(), toolId)
end

function DemandSystem.start()
	refresh()
	Remotes.connect("RequestDemandState", function(player)
		Remotes.get("DemandStateUpdated"):FireClient(player, refresh())
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			refresh()
		end
	end)
end

return DemandSystem
