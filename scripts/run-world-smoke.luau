local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local server = ServerScriptService:WaitForChild("CarWashRushServer")
local systems = server:WaitForChild("Systems")
local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local CooperativeEventSystem = require(systems.CooperativeEventSystem)
local GreyboxStarterCorner = require(systems.GreyboxStarterCorner)
local PrototypeGameplay = require(systems.PrototypeGameplay)
local Remotes = require(systems.Remotes)

Remotes.start(Config.RemotesFolderName)
local greybox = GreyboxStarterCorner.build()
CooperativeEventSystem.start(greybox.root)
PrototypeGameplay.start(greybox)

local root = Workspace:FindFirstChild(Config.World.RootFolderName)
assert(root, "generated world root is missing")
local levelOneDump = root:FindFirstChild("SharedSalvageDump")
local aircraftYard = root:FindFirstChild("AircraftSalvageYard")
local eventLot = root:FindFirstChild("CityCooperativeEventLot")
assert(levelOneDump, "level-one salvage dump is missing")
assert(aircraftYard, "aircraft salvage yard is missing")
assert(eventLot, "cooperative event lot is missing")
assert(eventLot:FindFirstChild("MudCoveredCityBus"), "cooperative bus is missing")
assert(eventLot:FindFirstChild("EventArrival"), "event arrival point is missing")
for _, phase in Config.CooperativeEvent.Phases do
	assert(eventLot:FindFirstChild("Station_" .. phase.Id), "event phase station is missing")
end
assert(levelOneDump:FindFirstChild("LadderPlacement"), "ladder placement point is missing")
local perimeter = aircraftYard:FindFirstChild("PerimeterFence")
assert(perimeter, "aircraft-yard perimeter fence is missing")
assert(perimeter:FindFirstChild("NorthFence"), "north aircraft-yard fence is missing")
assert(perimeter:FindFirstChild("SouthFence"), "south aircraft-yard fence is missing")
assert(perimeter:FindFirstChild("EastFenceNorth"), "east aircraft-yard fence is missing")
assert(perimeter:FindFirstChild("EastFenceSouth"), "east aircraft-yard fence is missing")
assert(perimeter:FindFirstChild("WestFence"), "west aircraft-yard fence is missing")
assert(aircraftYard:FindFirstChild("AccessGate"), "aircraft-yard access gate is missing")
assert(aircraftYard:FindFirstChild("DumpConnector"), "connected dump passage is missing")
assert(aircraftYard:FindFirstChild("AircraftArrival"), "aircraft-yard arrival point is missing")

local ladderPlacement = levelOneDump:FindFirstChild("LadderPlacement")
assert(ladderPlacement:IsA("BasePart"), "ladder placement must be a physical marker")
assert(math.abs(ladderPlacement.Position.X - -475) < 0.01, "ladder marker moved off the dump gate")

local trashcanCount = 0
local dumpsterCount = 0
for _, child in aircraftYard:GetChildren() do
	if child:IsA("Model") and string.match(child.Name, "^Trashcan_") then
		trashcanCount += 1
	elseif child:IsA("Model") and string.match(child.Name, "^Dumpster_") then
		dumpsterCount += 1
	end
end
assert(trashcanCount == Config.Trash.LevelTwoCanCount, "wrong aircraft-yard trashcan count")
assert(dumpsterCount == Config.Trash.LevelTwoDumpsterCount, "wrong aircraft-yard dumpster count")

local ladder = Catalog.getTool("item_salvage_ladder")
assert(ladder.Price == 1000, "ladder price changed unexpectedly")
assert(ladder.MinimumLevel == 10, "ladder unlock level changed unexpectedly")
assert(ladder.CanSell == false, "placed access ladder must not be resellable")

print("CAR_WASH_RUSH_WORLD_SMOKE_PASSED")
