local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CleaningRules =
	require(ReplicatedStorage.Shared:WaitForChild("Domain"):WaitForChild("CleaningRules"))
local ChaosRules = require(ReplicatedStorage.Shared.Domain:WaitForChild("ChaosRules"))
local AssistanceRules = require(ReplicatedStorage.Shared.Domain:WaitForChild("AssistanceRules"))
local LootRules = require(ReplicatedStorage.Shared:WaitForChild("Domain"):WaitForChild("LootRules"))
local OnboardingRules = require(ReplicatedStorage.Shared.Domain:WaitForChild("OnboardingRules"))
local PlotRules = require(ReplicatedStorage.Shared.Domain:WaitForChild("PlotRules"))
local VehicleRules = require(ReplicatedStorage.Shared.Domain:WaitForChild("VehicleRules"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local DemandSystem = require(script.Parent:WaitForChild("DemandSystem"))
local CooperativeEventSystem = require(script.Parent:WaitForChild("CooperativeEventSystem"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local SecurePrompt =
	require(script.Parent.Parent:WaitForChild("Infrastructure"):WaitForChild("SecurePrompt"))

local PrototypeGameplay = {}

local SHARED_DUMP_CENTER = Vector3.new(-350, 0, 0)
local LEVEL_TWO_DUMP_CENTER = Vector3.new(-700, 0, 0)
local LADDER_PLACEMENT_POSITION = Vector3.new(-475, 0.55, 0)
local VEHICLE_COLORS = {
	Color3.fromRGB(232, 64, 64),
	Color3.fromRGB(244, 135, 45),
	Color3.fromRGB(239, 205, 55),
	Color3.fromRGB(70, 188, 91),
	Color3.fromRGB(44, 190, 210),
	Color3.fromRGB(63, 112, 224),
	Color3.fromRGB(155, 75, 210),
}

local greyboxReference = nil
local carsFolder: Folder? = nil
local zoneOwners = {}
local playerZoneSlots = {}
local playerZones = {}
local activeCars = {}
local activeCleaning = {}
local activeSpotCleaners = {}
local vehicleHelpers = {}
local sharedTrashState = nil
local sharedDumpsterState = nil
local sharedDumpReference = nil
local levelTwoTrashState = nil
local levelTwoDumpsterState = nil
local levelTwoDumpReference = nil
local aircraftByPlayer = {}
local sharedAccessLadder: Model? = nil
local vehicleSchedules = {}
local lastVehicleColorIndexes = {}
local lastVehicleHadChaos = {}
local teleportCooldowns = {}

local function createPart(
	name: string,
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = if canCollide == nil then true else canCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createWedge(
	name: string,
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Anchored = true
	wedge.Color = color
	wedge.Material = material or Enum.Material.SmoothPlastic
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Parent = parent
	return wedge
end

local function addPrompt(
	parent: BasePart,
	actionText: string,
	objectText: string,
	holdDuration: number
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = parent
	return prompt
end

local function addBillboard(parent: BasePart, text: string, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ZoneLabel"
	gui.Size = UDim2.fromOffset(260, 55)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 75
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 28, 34)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function notify(player: Player, message: string)
	Remotes.get("Notify"):FireClient(player, message)
end

local function getRootPart(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isNear(player: Player, part: BasePart, maxDistance: number): boolean
	local root = getRootPart(player)
	return root ~= nil and (root.Position - part.Position).Magnitude <= maxDistance
end

local function countRemainingDirt(car: Model): number
	local remaining = 0
	for _, descendant in ipairs(car:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("IsDirtPatch") == true then
			remaining += 1
		end
	end
	return remaining
end

local function cancelCleaning(player: Player, reason: string?)
	local session = activeCleaning[player]
	if not session then
		return
	end
	if activeSpotCleaners[session.spot] == player then
		activeSpotCleaners[session.spot] = nil
	end
	activeCleaning[player] = nil
	Remotes.get("CleaningEnded"):FireClient(player, false, reason or "Cleaning cancelled.")
end

local function beginCleaning(player: Player, dirt: BasePart, car: Model)
	local ownerUserId = car:GetAttribute("OwnerUserId")
	local owner = if type(ownerUserId) == "number"
		then Players:GetPlayerByUserId(ownerUserId)
		else nil
	local isOwner = owner == player
	if not isOwner then
		if not owner or car:GetAttribute("RequiredCleaningTier") ~= 1 then
			notify(player, "This vehicle belongs to another player.")
			return
		end
		local isFriend = false
		local friendSuccess, friendResult = pcall(function()
			return owner:IsFriendsWith(player.UserId)
		end)
		if friendSuccess then
			isFriend = friendResult
		end
		if not AssistanceRules.canAssist(PlayerData.getAssistanceMode(owner), isFriend) then
			notify(player, "This wash is not accepting your help right now.")
			return
		end
	end
	local claimedBy = activeSpotCleaners[dirt]
	if claimedBy and claimedBy ~= player then
		notify(player, "Another player is already cleaning that spot.")
		return
	end
	if not PlayerData.hasFoundRag(player) then
		notify(
			player,
			"Search the 12 trashcans in the shared salvage dump for something you can clean with."
		)
		return
	end
	if not isNear(player, dirt, Config.Cleaning.MaxDistance) then
		return
	end

	local item, definition = PlayerData.getEquippedToolItem(player)
	if not item or not definition then
		notify(player, "Equip a cleaning tool from your hotbar first.")
		return
	end
	if item.durability <= 0 then
		notify(player, "That tool is broken. Equip another one.")
		return
	end
	local requiredTierAttribute = car:GetAttribute("RequiredCleaningTier")
	local requiredTier = if type(requiredTierAttribute) == "number"
		then requiredTierAttribute
		else 1
	if not CleaningRules.canClean(definition.CleaningTier, requiredTier) then
		notify(
			player,
			"This tool is not powerful enough for aircraft grime. Find a Level 2 cleaning tool."
		)
		return
	end

	cancelCleaning(player)
	local requiredClicks = math.random(definition.ClicksMin, definition.ClicksMax)
	activeCleaning[player] = {
		spot = dirt,
		car = car,
		itemId = item.id,
		toolId = item.toolId,
		toolName = definition.DisplayName,
		requiredClicks = requiredClicks,
		progress = 0,
		lastUpdate = os.clock(),
		lastClickAt = 0,
		owner = owner,
		isHelper = not isOwner,
	}
	activeSpotCleaners[dirt] = player
	if not isOwner then
		vehicleHelpers[car] = vehicleHelpers[car] or {}
		vehicleHelpers[car][player] = true
	end

	Remotes.get("CleaningStarted"):FireClient(player, {
		requiredClicks = requiredClicks,
		decayClicksPerSecond = Config.Cleaning.DecayClicksPerSecond,
		toolName = definition.DisplayName,
	})
end

local spawnDirtyCar
local redirtyAircraft

local function announceLevelUp(player: Player, levelsGained: number, newLevel: number)
	if levelsGained > 0 then
		notify(player, string.format("Level up! You are now level %d.", newLevel))
	end
end

local function completeDirtSpot(player: Player, session)
	activeCleaning[player] = nil
	local dirt = session.spot
	if activeSpotCleaners[dirt] == player then
		activeSpotCleaners[dirt] = nil
	end
	local car = session.car
	if dirt and dirt.Parent then
		dirt:Destroy()
	end

	local remainingDirt = if car and car.Parent then countRemainingDirt(car) else 0
	if
		car
		and car.Parent
		and remainingDirt > 0
		and car:GetAttribute("ChaosType") == "customer_roll"
		and car:GetAttribute("ChaosTriggered") ~= true
	then
		car:SetAttribute("ChaosTriggered", true)
		car:PivotTo(car:GetPivot() * CFrame.new(0, 0, -4))
		local owner = session.owner
		if owner and owner.Parent then
			notify(owner, "The customer rolled forward! The wash bay shifted under you.")
		end
	end
	local completedVehicle = car and car.Parent and remainingDirt == 0
	local completionCoins = if completedVehicle
		then car:GetAttribute("CompletionCoins") or 25
		else 0
	if completedVehicle and completionCoins > 0 then
		completionCoins =
			math.floor(completionCoins * DemandSystem.getCoinMultiplier(session.toolId) + 0.5)
	end
	local completionExperience = if completedVehicle
		then car:GetAttribute("CompletionExperience") or 50
		else 0
	local spotCoins = if session.toolId == "tool_sponge"
		then Config.Cleaning.SpongeSpotCoinReward
		else 0
	local cleanerCompletionCoins = if session.isHelper then 0 else completionCoins
	local cleanerCompletionExperience = if session.isHelper then 0 else completionExperience
	local success, remainingDurability, levelsGained, newLevel = PlayerData.completeCleaningSpot(
		player,
		session.itemId,
		spotCoins + cleanerCompletionCoins,
		Config.Experience.DirtSpotReward + cleanerCompletionExperience,
		if session.toolId == "tool_quality_sponge" then 1 else 0
	)
	if not success then
		Remotes.get("CleaningEnded")
			:FireClient(player, false, "That tool could not clean the spot.")
		return
	end
	announceLevelUp(player, levelsGained, newLevel)

	Remotes.get("CleaningEnded"):FireClient(
		player,
		true,
		string.format("Spot cleaned! +%d XP", Config.Experience.DirtSpotReward)
	)
	if remainingDurability == 0 then
		notify(player, session.toolName .. " wore out and is now broken.")
	end

	if completedVehicle then
		if car:GetAttribute("RequiredCleaningTier") == 2 then
			notify(player, "Aircraft cleaned. The old metal will collect grime again later.")
			task.delay(Config.LevelTwoDump.AircraftRedirtySeconds, function()
				if player.Parent and car.Parent then
					redirtyAircraft(player, car)
				end
			end)
			return
		end
		local vehicleName = car:GetAttribute("VehicleDisplayName") or "Vehicle"
		local owner = session.owner
		if not owner or not owner.Parent then
			car:Destroy()
			return
		end
		local helpers = vehicleHelpers[car]
		local hasHelpers = helpers ~= nil and next(helpers) ~= nil
		local ownerBonus = if hasHelpers
			then AssistanceRules.ownerBonus(
				completionCoins,
				Config.Assistance.OwnerCooperationBonusMultiplier
			)
			else 0
		if session.isHelper then
			local ownerLevels, ownerLevel = PlayerData.completeVehicle(
				owner,
				completionCoins + ownerBonus,
				completionExperience
			)
			announceLevelUp(owner, ownerLevels, ownerLevel)
			local wage =
				AssistanceRules.helperWage(completionCoins, Config.Assistance.HelperWageMultiplier)
			PlayerData.addCoins(player, wage)
			notify(player, string.format("Helper wage: +%d coins", wage))
		elseif ownerBonus > 0 then
			PlayerData.addCoins(owner, ownerBonus)
		end
		PlayerData.incrementLevelOneCarsCompleted(owner)
		notify(
			owner,
			string.format(
				"%s complete! +%d coins%s and +%d XP",
				vehicleName,
				completionCoins,
				if ownerBonus > 0 then string.format(" + %d teamwork", ownerBonus) else "",
				completionExperience
			)
		)
		activeCars[owner] = nil
		vehicleHelpers[car] = nil
		task.delay(2, function()
			if car.Parent then
				car:Destroy()
			end
			if owner.Parent and playerZones[owner] then
				spawnDirtyCar(owner)
			end
		end)
	end
end

local function handleCleaningClick(player: Player)
	local session = activeCleaning[player]
	if not session then
		return
	end

	local now = os.clock()
	if now - session.lastClickAt < Config.Cleaning.MinimumClickInterval then
		return
	end
	if not session.spot.Parent or not session.car.Parent then
		cancelCleaning(player, "That dirt spot is no longer available.")
		return
	end
	if not isNear(player, session.spot, Config.Cleaning.MaxDistance) then
		cancelCleaning(player, "You moved too far away. This spot became dirty again.")
		return
	end

	local equippedItem = PlayerData.getEquippedToolItem(player)
	if not equippedItem or equippedItem.id ~= session.itemId or equippedItem.durability <= 0 then
		cancelCleaning(player, "Keep the same working tool equipped while cleaning.")
		return
	end

	local elapsed = now - session.lastUpdate
	session.progress =
		math.max(0, session.progress - elapsed * Config.Cleaning.DecayClicksPerSecond)
	session.progress = math.min(session.requiredClicks, session.progress + 1)
	session.lastUpdate = now
	session.lastClickAt = now

	Remotes.get("CleaningProgress"):FireClient(player, session.progress, session.requiredClicks)
	if session.progress >= session.requiredClicks then
		completeDirtSpot(player, session)
	end
end

local SMALL_CAR_DIRT_CANDIDATES = {
	{ Size = Vector3.new(3.2, 0.22, 2.5), Offset = CFrame.new(-2.4, 1.42, -6.1) },
	{ Size = Vector3.new(3.2, 0.22, 2.5), Offset = CFrame.new(2.4, 1.42, -6.1) },
	{ Size = Vector3.new(3.2, 0.22, 2.7), Offset = CFrame.new(-2.4, 1.42, 5.7) },
	{ Size = Vector3.new(3.2, 0.22, 2.7), Offset = CFrame.new(2.4, 1.42, 5.7) },
	{ Size = Vector3.new(2.7, 0.22, 2.8), Offset = CFrame.new(-1.8, 4.18, -1) },
	{ Size = Vector3.new(2.7, 0.22, 2.8), Offset = CFrame.new(1.8, 4.18, -1) },
	{
		Size = Vector3.new(3, 0.22, 2.6),
		Offset = CFrame.new(-5.12, 0.15, -5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.6),
		Offset = CFrame.new(-5.12, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.6),
		Offset = CFrame.new(-5.12, 0.15, 5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.6),
		Offset = CFrame.new(5.12, 0.15, -5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.6),
		Offset = CFrame.new(5.12, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.6),
		Offset = CFrame.new(5.12, 0.15, 5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.8),
		Offset = CFrame.new(-2.5, 0.15, -8.08) * CFrame.Angles(math.rad(90), 0, 0),
	},
	{
		Size = Vector3.new(3, 0.22, 2.8),
		Offset = CFrame.new(2.5, 0.15, -8.08) * CFrame.Angles(math.rad(90), 0, 0),
	},
	{
		Size = Vector3.new(3, 0.22, 2.8),
		Offset = CFrame.new(-2.5, 0.15, 8.08) * CFrame.Angles(math.rad(90), 0, 0),
	},
	{
		Size = Vector3.new(3, 0.22, 2.8),
		Offset = CFrame.new(2.5, 0.15, 8.08) * CFrame.Angles(math.rad(90), 0, 0),
	},
}

local PICKUP_DIRT_CANDIDATES = {
	{ Size = Vector3.new(4.8, 0.25, 3.6), Offset = CFrame.new(0, 5.83, -4.4), Guaranteed = true },
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(-6.17, -0.45, -9) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(-6.17, -0.45, -4.5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(-6.17, -0.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(-6.17, -0.45, 4.5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(-6.17, -0.45, 9) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(6.17, -0.45, -9) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(6.17, -0.45, -4.5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(6.17, -0.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(6.17, -0.45, 4.5) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 2.8),
		Offset = CFrame.new(6.17, -0.45, 9) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.2, 0.22, 2.8),
		Offset = CFrame.new(-6.17, 0.9, -7) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.2, 0.22, 2.8),
		Offset = CFrame.new(-6.17, 0.9, 6.8) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.2, 0.22, 2.8),
		Offset = CFrame.new(6.17, 0.9, -7) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.2, 0.22, 2.8),
		Offset = CFrame.new(6.17, 0.9, 6.8) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3.4, 0.22, 3.2),
		Offset = CFrame.new(-3.2, -0.35, -12.18) * CFrame.Angles(math.rad(90), 0, 0),
	},
	{
		Size = Vector3.new(3.4, 0.22, 3.2),
		Offset = CFrame.new(3.2, -0.35, -12.18) * CFrame.Angles(math.rad(90), 0, 0),
	},
	{
		Size = Vector3.new(3.4, 0.22, 3.2),
		Offset = CFrame.new(-3.2, -0.35, 12.18) * CFrame.Angles(math.rad(90), 0, 0),
	},
	{
		Size = Vector3.new(3.4, 0.22, 3.2),
		Offset = CFrame.new(3.2, -0.35, 12.18) * CFrame.Angles(math.rad(90), 0, 0),
	},
}

local RV_DIRT_CANDIDATES = {}
for _, xOffset in ipairs({ -7.58, 7.58 }) do
	for _, yOffset in ipairs({ -2.7, 0.3 }) do
		for _, zOffset in ipairs({ -11, -6, -1, 4, 9 }) do
			table.insert(RV_DIRT_CANDIDATES, {
				Size = Vector3.new(3.4, 0.22, 3),
				Offset = CFrame.new(xOffset, yOffset, zOffset) * CFrame.Angles(0, 0, math.rad(90)),
			})
		end
	end
end
for _, candidate in ipairs({
	{
		Size = Vector3.new(3.8, 0.22, 3.2),
		Offset = CFrame.new(-3.2, 4.38, -10.5),
	},
	{
		Size = Vector3.new(3.8, 0.22, 3.2),
		Offset = CFrame.new(3.2, 4.38, -10.5),
	},
	{
		Size = Vector3.new(3.8, 0.22, 3.2),
		Offset = CFrame.new(-3.2, -2.2, 16.08) * CFrame.Angles(math.rad(90), 0, 0),
	},
	{
		Size = Vector3.new(3.8, 0.22, 3.2),
		Offset = CFrame.new(3.2, -2.2, 16.08) * CFrame.Angles(math.rad(90), 0, 0),
	},
}) do
	table.insert(RV_DIRT_CANDIDATES, candidate)
end

local function chooseWeightedCount(weights, fallback: number): number
	local selected = VehicleRules.chooseWeighted(weights, math.random())
	return if selected then selected.Count else fallback
end

local function shuffledCandidateIndexes(candidates)
	local indexes = {}
	for index = 1, #candidates do
		table.insert(indexes, index)
	end
	for index = #indexes, 2, -1 do
		local other = math.random(1, index)
		indexes[index], indexes[other] = indexes[other], indexes[index]
	end
	return indexes
end

local function addWheels(car: Model, baseCFrame: CFrame, offsets, diameter: number?)
	local wheelDiameter = diameter or 2.2
	for index, offset in ipairs(offsets) do
		local wheel = createPart(
			"Wheel_" .. index,
			car,
			Vector3.new(wheelDiameter, wheelDiameter, wheelDiameter),
			baseCFrame * CFrame.new(offset),
			Color3.fromRGB(20, 20, 20),
			Enum.Material.SmoothPlastic
		)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Orientation = Vector3.new(0, 0, 90)
	end
end

local function addDirtPatches(
	player: Player,
	car: Model,
	baseCFrame: CFrame,
	candidates,
	dirtCount: number
)
	local candidateIndexes = {}
	for index, candidate in ipairs(candidates) do
		if candidate.Guaranteed == true then
			table.insert(candidateIndexes, index)
		end
	end
	for _, index in ipairs(shuffledCandidateIndexes(candidates)) do
		if candidates[index].Guaranteed ~= true then
			table.insert(candidateIndexes, index)
		end
	end
	for dirtIndex = 1, math.min(dirtCount, #candidateIndexes) do
		local candidate = candidates[candidateIndexes[dirtIndex]]
		local unusualDirt = car:GetAttribute("ChaosType") == "unusual_dirt"
		local dirtColor = if unusualDirt
			then if dirtIndex % 2 == 0
				then Color3.fromRGB(82, 125, 54)
				else Color3.fromRGB(120, 65, 126)
			else Color3.fromRGB(104, 67, 31)
		local dirt = createPart(
			"DirtPatch_" .. dirtIndex,
			car,
			candidate.Size,
			baseCFrame * candidate.Offset,
			dirtColor,
			Enum.Material.Mud,
			0,
			false
		)
		dirt:SetAttribute("IsDirtPatch", true)
		dirt:SetAttribute("OwnerUserId", player.UserId)
		dirt:SetAttribute("RequiredCleaningTier", car:GetAttribute("RequiredCleaningTier") or 1)

		local highlight = Instance.new("Highlight")
		highlight.Name = "DirtHighlight"
		highlight.Enabled = false
		highlight.FillTransparency = 0.72
		highlight.OutlineColor = Color3.fromRGB(255, 218, 88)
		highlight.OutlineTransparency = 0.1
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = dirt
		highlight.Parent = dirt
	end
end

local function createVehicle(
	player: Player,
	spawnCFrame: CFrame,
	definition,
	vehicleColor: Color3,
	chaosType: string?
): Model
	local car = Instance.new("Model")
	car.Name = string.format("%s_%s", player.Name, definition.Id)
	car:SetAttribute("OwnerUserId", player.UserId)
	car:SetAttribute("VehicleType", definition.Id)
	car:SetAttribute("VehicleDisplayName", definition.DisplayName)
	car:SetAttribute("CompletionCoins", definition.CompletionCoins)
	car:SetAttribute("CompletionExperience", definition.CompletionExperience)
	car:SetAttribute("VehicleColor", vehicleColor)
	car:SetAttribute("RequiredCleaningTier", 1)
	car:SetAttribute("ChaosType", chaosType or "")
	car.Parent = carsFolder

	if definition.Id == "pickup_truck" then
		local baseCFrame = spawnCFrame + Vector3.new(0, 2.65, 0)
		local body = createPart(
			"Body",
			car,
			Vector3.new(12.1, 2.75, 24.2),
			baseCFrame,
			vehicleColor,
			Enum.Material.SmoothPlastic
		)
		car.PrimaryPart = body
		createPart(
			"Cabin",
			car,
			Vector3.new(9.9, 4.95, 8.8),
			baseCFrame * CFrame.new(0, 3.3, -4.4),
			Color3.fromRGB(48, 76, 92),
			Enum.Material.Glass
		)
		createPart(
			"BedFloor",
			car,
			Vector3.new(10.45, 0.77, 9.9),
			baseCFrame * CFrame.new(0, 1.54, 6.38),
			vehicleColor:Lerp(Color3.new(0, 0, 0), 0.25),
			Enum.Material.Metal
		)
		createPart(
			"FrontBumper",
			car,
			Vector3.new(11, 1.1, 1.1),
			baseCFrame * CFrame.new(0, -0.22, -12.65),
			Color3.fromRGB(35, 35, 35),
			Enum.Material.Metal
		)
		createPart(
			"RearBumper",
			car,
			Vector3.new(11, 1.1, 1.1),
			baseCFrame * CFrame.new(0, -0.22, 12.65),
			Color3.fromRGB(35, 35, 35),
			Enum.Material.Metal
		)
		addWheels(car, baseCFrame, {
			Vector3.new(-6.6, -1.1, -7.7),
			Vector3.new(6.6, -1.1, -7.7),
			Vector3.new(-6.6, -1.1, 7.7),
			Vector3.new(6.6, -1.1, 7.7),
		}, 2.42)
		addDirtPatches(
			player,
			car,
			baseCFrame,
			PICKUP_DIRT_CANDIDATES,
			chooseWeightedCount(definition.DirtCountWeights, 10)
				+ if chaosType == "unusual_dirt" then 2 else 0
		)
	elseif definition.Id == "rv" then
		local baseCFrame = spawnCFrame + Vector3.new(0, 5, 0)
		local body = createPart(
			"Body",
			car,
			Vector3.new(14.5, 8.5, 30),
			baseCFrame * CFrame.new(0, 0, 1),
			vehicleColor,
			Enum.Material.SmoothPlastic
		)
		car.PrimaryPart = body
		createPart(
			"LowerChassis",
			car,
			Vector3.new(15, 1.2, 34),
			baseCFrame * CFrame.new(0, -4.25, 0),
			Color3.fromRGB(45, 48, 50),
			Enum.Material.Metal
		)
		createWedge(
			"SlopedFront",
			car,
			Vector3.new(14.5, 8.2, 3.5),
			baseCFrame * CFrame.new(0, -0.15, -15.75) * CFrame.Angles(0, math.rad(180), 0),
			vehicleColor,
			Enum.Material.SmoothPlastic
		)
		createPart(
			"Windshield",
			car,
			Vector3.new(10.5, 4.2, 0.35),
			baseCFrame * CFrame.new(0, 1.1, -17.2),
			Color3.fromRGB(42, 83, 105),
			Enum.Material.Glass,
			0.08,
			false
		)
		local stripeColor = vehicleColor:Lerp(Color3.new(1, 1, 1), 0.55)
		createPart(
			"StripeLeft",
			car,
			Vector3.new(0.25, 1.2, 27),
			baseCFrame * CFrame.new(-7.38, -0.2, 1.5),
			stripeColor,
			Enum.Material.SmoothPlastic,
			0,
			false
		)
		createPart(
			"StripeRight",
			car,
			Vector3.new(0.25, 1.2, 27),
			baseCFrame * CFrame.new(7.38, -0.2, 1.5),
			stripeColor,
			Enum.Material.SmoothPlastic,
			0,
			false
		)
		for sideIndex, xOffset in ipairs({ -7.39, 7.39 }) do
			for windowIndex, zOffset in ipairs({ -8, -2, 4, 10 }) do
				createPart(
					string.format("SideWindow_%d_%d", sideIndex, windowIndex),
					car,
					Vector3.new(0.28, 2.8, 4.2),
					baseCFrame * CFrame.new(xOffset, 1.55, zOffset),
					Color3.fromRGB(48, 92, 112),
					Enum.Material.Glass,
					0.1,
					false
				)
			end
		end
		createPart(
			"PassengerDoor",
			car,
			Vector3.new(0.3, 5.4, 4),
			baseCFrame * CFrame.new(7.4, -1, -7.8),
			vehicleColor:Lerp(Color3.new(0, 0, 0), 0.08),
			Enum.Material.Metal,
			0,
			false
		)
		createPart(
			"Awning",
			car,
			Vector3.new(0.7, 0.7, 17),
			baseCFrame * CFrame.new(7.65, 4.45, 3),
			stripeColor,
			Enum.Material.Metal
		)
		createPart(
			"RoofAC",
			car,
			Vector3.new(5, 1.4, 4),
			baseCFrame * CFrame.new(0, 5, 4),
			Color3.fromRGB(220, 224, 218),
			Enum.Material.Metal
		)
		createPart(
			"FrontBumper",
			car,
			Vector3.new(13.5, 0.8, 1),
			baseCFrame * CFrame.new(0, -3.7, -17.4),
			Color3.fromRGB(45, 48, 50),
			Enum.Material.Metal
		)
		createPart(
			"RearBumper",
			car,
			Vector3.new(13.5, 0.8, 1),
			baseCFrame * CFrame.new(0, -3.7, 16.5),
			Color3.fromRGB(45, 48, 50),
			Enum.Material.Metal
		)
		for lightIndex, xOffset in ipairs({ -4.8, 4.8 }) do
			createPart(
				"Headlight_" .. lightIndex,
				car,
				Vector3.new(2.2, 1.1, 0.35),
				baseCFrame * CFrame.new(xOffset, -2.4, -17.65),
				Color3.fromRGB(255, 240, 170),
				Enum.Material.Neon,
				0,
				false
			)
			createPart(
				"TailLight_" .. lightIndex,
				car,
				Vector3.new(1.4, 1.6, 0.3),
				baseCFrame * CFrame.new(xOffset, -2.2, 16.15),
				Color3.fromRGB(224, 56, 50),
				Enum.Material.Neon,
				0,
				false
			)
		end
		addWheels(car, baseCFrame, {
			Vector3.new(-7.7, -4, -10),
			Vector3.new(7.7, -4, -10),
			Vector3.new(-7.7, -4, 9),
			Vector3.new(7.7, -4, 9),
		}, 3)
		addDirtPatches(
			player,
			car,
			baseCFrame,
			RV_DIRT_CANDIDATES,
			math.random(definition.DirtCountMin, definition.DirtCountMax)
				+ if chaosType == "unusual_dirt" then 2 else 0
		)
	else
		local baseCFrame = spawnCFrame + Vector3.new(0, 2.5, 0)
		local body = createPart(
			"Body",
			car,
			Vector3.new(10, 2.5, 16),
			baseCFrame,
			vehicleColor,
			Enum.Material.SmoothPlastic
		)
		car.PrimaryPart = body
		createPart(
			"Cabin",
			car,
			Vector3.new(7, 3, 7),
			baseCFrame * CFrame.new(0, 2.6, -1),
			Color3.fromRGB(55, 100, 142),
			Enum.Material.Glass
		)
		createPart(
			"FrontBumper",
			car,
			Vector3.new(9, 1, 1),
			baseCFrame * CFrame.new(0, -0.2, -8.5),
			Color3.fromRGB(35, 35, 35),
			Enum.Material.Metal
		)
		createPart(
			"RearBumper",
			car,
			Vector3.new(9, 1, 1),
			baseCFrame * CFrame.new(0, -0.2, 8.5),
			Color3.fromRGB(35, 35, 35),
			Enum.Material.Metal
		)
		addWheels(car, baseCFrame, {
			Vector3.new(-5.5, -1, -5.5),
			Vector3.new(5.5, -1, -5.5),
			Vector3.new(-5.5, -1, 5.5),
			Vector3.new(5.5, -1, 5.5),
		})
		addDirtPatches(
			player,
			car,
			baseCFrame,
			SMALL_CAR_DIRT_CANDIDATES,
			chooseWeightedCount(definition.DirtCountWeights, 6)
				+ if chaosType == "unusual_dirt" then 2 else 0
		)
	end

	return car
end

local function getVehicleDefinition(vehicleId: string)
	for _, definition in ipairs(Config.LevelOneVehicles) do
		if definition.Id == vehicleId then
			return definition
		end
	end
	return Config.LevelOneVehicles[1]
end

local function chooseVehicleDefinition(player: Player)
	local schedule = vehicleSchedules[player]
	if not schedule then
		schedule = {
			normalCarsUntilRv = VehicleRules.nextRvInterval(
				Config.LevelOneRvIntervalMin,
				Config.LevelOneRvIntervalMax,
				math.random()
			),
		}
		vehicleSchedules[player] = schedule
	end
	if schedule.normalCarsUntilRv <= 0 then
		schedule.normalCarsUntilRv = VehicleRules.nextRvInterval(
			Config.LevelOneRvIntervalMin,
			Config.LevelOneRvIntervalMax,
			math.random()
		)
		return getVehicleDefinition("rv")
	end
	schedule.normalCarsUntilRv -= 1

	local normalEntries = {}
	for _, definition in ipairs(Config.LevelOneVehicles) do
		if definition.NormalSpawnWeight then
			table.insert(normalEntries, {
				Definition = definition,
				Weight = definition.NormalSpawnWeight,
			})
		end
	end
	local selected = VehicleRules.chooseWeighted(normalEntries, math.random())
	return if selected then selected.Definition else Config.LevelOneVehicles[1]
end

local function chooseVehicleColor(player: Player): Color3
	local previousIndex = lastVehicleColorIndexes[player]
	local colorIndex = VehicleRules.nonRepeatingColorIndex(
		#VEHICLE_COLORS,
		previousIndex,
		math.random()
	) or 1
	lastVehicleColorIndexes[player] = colorIndex
	return VEHICLE_COLORS[colorIndex]
end

spawnDirtyCar = function(player: Player)
	local zone = playerZones[player]
	if not zone or not carsFolder then
		return
	end
	local oldCar = activeCars[player]
	if oldCar and oldCar.Parent then
		oldCar:Destroy()
	end
	local spawnMarker = zone:FindFirstChild("CarSpawn")
	if spawnMarker and spawnMarker:IsA("BasePart") then
		local chaosType = ChaosRules.choose(
			PlayerData.getLevelOneCarsCompleted(player),
			Config.Chaos.ProtectedCompletedCars,
			lastVehicleHadChaos[player] == true,
			Config.Chaos.Chance,
			math.random(),
			math.random(),
			Config.Chaos.Types
		)
		lastVehicleHadChaos[player] = chaosType ~= nil
		activeCars[player] = createVehicle(
			player,
			spawnMarker.CFrame,
			chooseVehicleDefinition(player),
			chooseVehicleColor(player),
			chaosType
		)
		if chaosType == "unusual_dirt" then
			notify(player, "Rare arrival: this customer brought a very unusual dirt pattern.")
		end
	end
end

local function createTrashcan(zone: Model, position: Vector3, index: number)
	local trashcan = Instance.new("Model")
	trashcan.Name = "Trashcan_" .. index
	trashcan.Parent = zone

	local body = createPart(
		"Body",
		trashcan,
		Vector3.new(5.5, 4.5, 4.5),
		CFrame.new(position + Vector3.new(0, 2.25, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(62, 72, 76),
		Enum.Material.Metal
	)
	body.Shape = Enum.PartType.Cylinder
	local lid = createPart(
		"Lid",
		trashcan,
		Vector3.new(0.6, 5, 5),
		CFrame.new(position + Vector3.new(0, 4.65, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(40, 49, 53),
		Enum.Material.Metal
	)
	lid.Shape = Enum.PartType.Cylinder
	trashcan.PrimaryPart = body

	local debris = {}
	for debrisIndex, debrisInfo in ipairs({
		{
			Offset = Vector3.new(-1.3, 4.9, 0.7),
			Size = Vector3.new(1.4, 0.8, 1.1),
			Color = Color3.fromRGB(116, 82, 47),
		},
		{
			Offset = Vector3.new(0.8, 5.1, -0.6),
			Size = Vector3.new(1, 1, 1),
			Color = Color3.fromRGB(75, 108, 62),
		},
		{
			Offset = Vector3.new(1.5, 4.85, 0.9),
			Size = Vector3.new(1.2, 0.7, 1.5),
			Color = Color3.fromRGB(132, 124, 103),
		},
	}) do
		local scrap = createPart(
			"SearchedDebris_" .. debrisIndex,
			trashcan,
			debrisInfo.Size,
			CFrame.new(position + debrisInfo.Offset)
				* CFrame.Angles(math.rad(debrisIndex * 17), math.rad(debrisIndex * 31), 0),
			debrisInfo.Color,
			Enum.Material.Ground,
			1,
			false
		)
		table.insert(debris, scrap)
	end

	local prompt = addPrompt(lid, "Search", "Trashcan", Config.Trash.SearchSeconds)
	return {
		model = trashcan,
		body = body,
		lid = lid,
		debris = debris,
		prompt = prompt,
	}
end

local function setTrashcanSearched(can, searched: boolean)
	-- Missing-rag players may still check a shared emptied can once per refill.
	can.prompt.Enabled = true
	can.body.Color = if searched then Color3.fromRGB(91, 73, 55) else Color3.fromRGB(62, 72, 76)
	can.lid.Color = if searched then Color3.fromRGB(121, 76, 42) else Color3.fromRGB(40, 49, 53)
	for _, debris in ipairs(can.debris) do
		debris.Transparency = if searched then 0 else 1
	end
end

local function setTrashcanRefilling(can, refilling: boolean)
	can.prompt.Enabled = not refilling
	can.body.Material = if refilling then Enum.Material.Neon else Enum.Material.Metal
	can.lid.Material = if refilling then Enum.Material.Neon else Enum.Material.Metal
	can.body.Color = if refilling then Color3.fromRGB(70, 220, 255) else Color3.fromRGB(62, 72, 76)
	can.lid.Color = if refilling then Color3.fromRGB(255, 226, 86) else Color3.fromRGB(40, 49, 53)

	local oldIndicator = can.lid:FindFirstChild("RefillIndicator")
	if oldIndicator then
		oldIndicator:Destroy()
	end
	if refilling then
		local gui = Instance.new("BillboardGui")
		gui.Name = "RefillIndicator"
		gui.Size = UDim2.fromOffset(170, 42)
		gui.StudsOffset = Vector3.new(0, 2.2, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 35
		gui.Parent = can.lid
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(20, 30, 38)
		label.BackgroundTransparency = 0.08
		label.BorderSizePixel = 0
		label.Text = "REFILLING..."
		label.TextColor3 = Color3.fromRGB(255, 236, 142)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = gui
	end
end

local function randomizeTrashcanPositions(state)
	local positionIndexes = {}
	for index = 1, #state.positions do
		table.insert(positionIndexes, index)
	end
	for index = #positionIndexes, 2, -1 do
		local other = math.random(1, index)
		positionIndexes[index], positionIndexes[other] =
			positionIndexes[other], positionIndexes[index]
	end
	for canIndex, can in ipairs(state.cans) do
		local position = state.positions[positionIndexes[canIndex]]
		can.model:PivotTo(
			CFrame.new(position + Vector3.new(0, 2.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
		)
	end
end

local function refillTrashcans(state)
	if state.refilling then
		return
	end
	state.refilling = true
	for _, can in ipairs(state.cans) do
		setTrashcanSearched(can, false)
		setTrashcanRefilling(can, true)
	end
	task.delay(Config.Trash.RefillSeconds, function()
		if sharedTrashState ~= state then
			return
		end
		state.searched = {}
		state.onboardingAttempts = {}
		state.searchCount = 0
		state.refilling = false
		randomizeTrashcanPositions(state)
		for _, can in ipairs(state.cans) do
			setTrashcanRefilling(can, false)
		end
	end)
end

local function searchTrashcan(searchingPlayer: Player, canIndex: number)
	local state = sharedTrashState
	if not state or state.refilling then
		return
	end
	local wasSharedLooted = state.searched[canIndex] == true
	local playerAttempts = state.onboardingAttempts[searchingPlayer.UserId]
	local alreadyTriedForRag = playerAttempts and playerAttempts[canIndex] == true or false
	local allowed, reason = OnboardingRules.canSearchSharedCan(
		PlayerData.hasFoundRag(searchingPlayer),
		wasSharedLooted,
		alreadyTriedForRag
	)
	if not allowed then
		notify(searchingPlayer, reason or "You cannot search that can right now.")
		return
	end

	if not wasSharedLooted then
		state.searched[canIndex] = true
		state.searchCount += 1
		setTrashcanSearched(state.cans[canIndex], true)
	end
	if not PlayerData.hasFoundRag(searchingPlayer) then
		playerAttempts = playerAttempts or {}
		state.onboardingAttempts[searchingPlayer.UserId] = playerAttempts
		playerAttempts[canIndex] = true
	end

	local outcome =
		LootRules.rollTrashCan(PlayerData.hasFoundRag(searchingPlayer), math.random(1, 100))
	if wasSharedLooted and outcome.kind ~= "rag" then
		notify(searchingPlayer, "No onboarding rag here. Try another can.")
		return
	end
	if outcome.kind == "rag" then
		if PlayerData.grantFoundRag(searchingPlayer) then
			notify(
				searchingPlayer,
				"You found an old rag. It has 20 durability and is now equipped."
			)
		end
	elseif outcome.kind == "coins" then
		PlayerData.addCoins(searchingPlayer, outcome.coins)
		if not PlayerData.hasFoundRag(searchingPlayer) then
			notify(searchingPlayer, string.format("You found %d coins, but no rag.", outcome.coins))
		elseif outcome.coins == Config.Trash.JackpotCoinReward then
			notify(
				searchingPlayer,
				string.format("Jackpot! This trashcan had %d coins.", outcome.coins)
			)
		elseif outcome.coins == Config.Trash.MediumCoinReward then
			notify(
				searchingPlayer,
				string.format("Good find! This trashcan had %d coins.", outcome.coins)
			)
		else
			notify(
				searchingPlayer,
				string.format("You found %d coins in the trashcan.", outcome.coins)
			)
		end
	else
		notify(searchingPlayer, "This trashcan is empty.")
	end
	if state.searchCount >= Config.Trash.CanCount then
		refillTrashcans(state)
	end
end

local function createDumpster(parent: Model, position: Vector3, index: number)
	local dumpster = Instance.new("Model")
	dumpster.Name = "Dumpster_" .. index
	dumpster.Parent = parent

	local body = createPart(
		"Body",
		dumpster,
		Vector3.new(16, 7, 9),
		CFrame.new(position + Vector3.new(0, 3.5, 0)),
		Color3.fromRGB(48, 93, 61),
		Enum.Material.CorrodedMetal
	)
	dumpster.PrimaryPart = body
	createPart(
		"FrontLip",
		dumpster,
		Vector3.new(14, 1.2, 0.6),
		CFrame.new(position + Vector3.new(0, 5.2, -4.75)),
		Color3.fromRGB(36, 70, 46),
		Enum.Material.Metal
	)
	local lidLeft = createPart(
		"LidLeft",
		dumpster,
		Vector3.new(7.7, 0.55, 9.6),
		CFrame.new(position + Vector3.new(-4.05, 7.2, 0)),
		Color3.fromRGB(35, 70, 45),
		Enum.Material.Metal
	)
	local lidRight = createPart(
		"LidRight",
		dumpster,
		Vector3.new(7.7, 0.55, 9.6),
		CFrame.new(position + Vector3.new(4.05, 7.2, 0)),
		Color3.fromRGB(35, 70, 45),
		Enum.Material.Metal
	)

	local debris = {}
	for debrisIndex, info in ipairs({
		{
			Offset = Vector3.new(-3, 7.75, 0.5),
			Size = Vector3.new(2.4, 1.1, 2),
			Color = Color3.fromRGB(94, 72, 46),
		},
		{
			Offset = Vector3.new(0, 8, -1.2),
			Size = Vector3.new(2, 1.4, 2.4),
			Color = Color3.fromRGB(62, 83, 117),
		},
		{
			Offset = Vector3.new(3.2, 7.7, 1),
			Size = Vector3.new(2.8, 1, 1.8),
			Color = Color3.fromRGB(124, 116, 96),
		},
	}) do
		local scrap = createPart(
			"LootedDebris_" .. debrisIndex,
			dumpster,
			info.Size,
			CFrame.new(position + info.Offset)
				* CFrame.Angles(math.rad(debrisIndex * 13), math.rad(debrisIndex * 27), 0),
			info.Color,
			Enum.Material.Ground,
			1,
			false
		)
		table.insert(debris, scrap)
	end

	local prompt = addPrompt(body, "Search", "Dumpster", Config.Trash.DumpsterSearchSeconds)
	return {
		model = dumpster,
		body = body,
		lids = { lidLeft, lidRight },
		debris = debris,
		prompt = prompt,
	}
end

local function setDumpsterSearched(dumpster, searched: boolean)
	dumpster.prompt.Enabled = not searched
	dumpster.body.Color = if searched
		then Color3.fromRGB(75, 76, 61)
		else Color3.fromRGB(48, 93, 61)
	for _, lid in ipairs(dumpster.lids) do
		lid.Color = if searched then Color3.fromRGB(91, 73, 51) else Color3.fromRGB(35, 70, 45)
	end
	for _, debris in ipairs(dumpster.debris) do
		debris.Transparency = if searched then 0 else 1
	end
end

local function setDumpsterRefilling(dumpster, refilling: boolean)
	dumpster.prompt.Enabled = not refilling
	dumpster.body.Material = if refilling then Enum.Material.Neon else Enum.Material.CorrodedMetal
	dumpster.body.Color = if refilling
		then Color3.fromRGB(70, 220, 255)
		else Color3.fromRGB(48, 93, 61)
	for _, lid in ipairs(dumpster.lids) do
		lid.Material = if refilling then Enum.Material.Neon else Enum.Material.Metal
		lid.Color = if refilling then Color3.fromRGB(255, 226, 86) else Color3.fromRGB(35, 70, 45)
	end
end

local function refillDumpsters(state)
	if state.refilling then
		return
	end
	state.refilling = true
	for _, dumpster in ipairs(state.dumpsters) do
		setDumpsterSearched(dumpster, false)
		setDumpsterRefilling(dumpster, true)
	end
	task.delay(Config.Trash.RefillSeconds, function()
		if sharedDumpsterState ~= state then
			return
		end
		state.searched = {}
		state.searchCount = 0
		state.refilling = false
		for _, dumpster in ipairs(state.dumpsters) do
			setDumpsterRefilling(dumpster, false)
		end
	end)
end

local function searchDumpster(searchingPlayer: Player, dumpsterIndex: number)
	if PlayerData.getLevel(searchingPlayer) < Config.Trash.DumpsterMinimumLevel then
		notify(
			searchingPlayer,
			string.format("Reach Level %d to search dumpsters.", Config.Trash.DumpsterMinimumLevel)
		)
		return
	end
	local state = sharedDumpsterState
	if not state or state.refilling then
		return
	end
	if state.searched[dumpsterIndex] then
		notify(searchingPlayer, "That dumpster has already been looted.")
		return
	end

	state.searched[dumpsterIndex] = true
	state.searchCount += 1
	setDumpsterSearched(state.dumpsters[dumpsterIndex], true)

	local multiplier = Config.Trash.DumpsterRewardMultiplier
	local roll = math.random(1, 100)
	local reward
	if roll <= Config.Trash.PostRagSmallCoinChance then
		reward = Config.Trash.SmallCoinReward * multiplier
	elseif roll <= Config.Trash.PostRagSmallCoinChance + Config.Trash.PostRagMediumCoinChance then
		reward = Config.Trash.MediumCoinReward * multiplier
	else
		reward = Config.Trash.JackpotCoinReward * multiplier
	end
	PlayerData.addCoins(searchingPlayer, reward)
	notify(searchingPlayer, string.format("Dumpster haul! +%d coins", reward))

	if state.searchCount >= Config.Trash.DumpsterCount then
		refillDumpsters(state)
	end
end

local function teleportPlayer(player: Player, destination: BasePart)
	local now = os.clock()
	if teleportCooldowns[player] and now - teleportCooldowns[player] < 1.5 then
		return
	end
	teleportCooldowns[player] = now
	local character = player.Character
	if character then
		character:PivotTo(destination.CFrame + Vector3.new(0, 3, 0))
	end
end

local function createSharedDump()
	local oldDump = greyboxReference.root:FindFirstChild("SharedSalvageDump")
	if oldDump then
		oldDump:Destroy()
	end

	local dump = Instance.new("Model")
	dump.Name = "SharedSalvageDump"
	dump.Parent = greyboxReference.root
	local dumpCenter = SHARED_DUMP_CENTER
	local dumpWidth = 270
	local dumpDepth = 202
	local fenceColor = Color3.fromRGB(91, 99, 97)

	createPart(
		"DumpFloor",
		dump,
		Vector3.new(dumpWidth, 0.35, dumpDepth),
		CFrame.new(dumpCenter + Vector3.new(0, 0.25, 0)),
		Color3.fromRGB(73, 68, 55),
		Enum.Material.Ground
	)

	local function createFenceSection(name: string, size: Vector3, cframe: CFrame)
		createPart(name .. "Mesh", dump, size, cframe, fenceColor, Enum.Material.Metal, 0.58, true)
		createPart(
			name .. "TopRail",
			dump,
			Vector3.new(size.X + 0.2, 0.28, size.Z + 0.2),
			cframe * CFrame.new(0, size.Y / 2, 0),
			Color3.fromRGB(65, 69, 68),
			Enum.Material.Metal
		)
	end

	createFenceSection(
		"NorthFence",
		Vector3.new(dumpWidth, 7, 0.45),
		CFrame.new(dumpCenter + Vector3.new(0, 3.5, -dumpDepth / 2))
	)
	createFenceSection(
		"SouthFence",
		Vector3.new(dumpWidth, 7, 0.45),
		CFrame.new(dumpCenter + Vector3.new(0, 3.5, dumpDepth / 2))
	)
	createFenceSection(
		"WestFenceNorth",
		Vector3.new(0.45, 7, 84),
		CFrame.new(dumpCenter + Vector3.new(-dumpWidth / 2, 3.5, -59))
	)
	createFenceSection(
		"WestFenceSouth",
		Vector3.new(0.45, 7, 84),
		CFrame.new(dumpCenter + Vector3.new(-dumpWidth / 2, 3.5, 59))
	)
	createFenceSection(
		"EastFenceNorth",
		Vector3.new(0.45, 7, 80),
		CFrame.new(dumpCenter + Vector3.new(dumpWidth / 2, 3.5, -61))
	)
	createFenceSection(
		"EastFenceSouth",
		Vector3.new(0.45, 7, 80),
		CFrame.new(dumpCenter + Vector3.new(dumpWidth / 2, 3.5, 61))
	)
	for _, zOffset in ipairs({ -20, 20 }) do
		createPart(
			"GatePost_" .. tostring(zOffset),
			dump,
			Vector3.new(1.1, 8, 1.1),
			CFrame.new(dumpCenter + Vector3.new(dumpWidth / 2, 4, zOffset)),
			Color3.fromRGB(62, 65, 64),
			Enum.Material.Metal
		)
	end
	createPart(
		"GateDoorNorth",
		dump,
		Vector3.new(0.45, 7, 19),
		CFrame.new(dumpCenter + Vector3.new(dumpWidth / 2 + 7, 3.5, -13))
			* CFrame.Angles(0, math.rad(-48), 0),
		fenceColor,
		Enum.Material.Metal,
		0.5,
		true
	)
	createPart(
		"GateDoorSouth",
		dump,
		Vector3.new(0.45, 7, 19),
		CFrame.new(dumpCenter + Vector3.new(dumpWidth / 2 + 7, 3.5, 13))
			* CFrame.Angles(0, math.rad(48), 0),
		fenceColor,
		Enum.Material.Metal,
		0.5,
		true
	)

	local dumpSign = createPart(
		"DumpSign",
		dump,
		Vector3.new(26, 6, 1),
		CFrame.new(dumpCenter + Vector3.new(dumpWidth / 2 - 8, 7.5, -31)),
		Color3.fromRGB(92, 57, 37),
		Enum.Material.Wood
	)
	addBillboard(dumpSign, "SHARED SALVAGE DUMP", Color3.fromRGB(255, 221, 135))

	for pileIndex, pileOffset in ipairs({
		Vector3.new(-120, 0, -84),
		Vector3.new(-35, 0, -89),
		Vector3.new(35, 0, -89),
		Vector3.new(120, 0, -84),
		Vector3.new(-126, 0, -28),
		Vector3.new(-126, 0, 31),
		Vector3.new(126, 0, -31),
		Vector3.new(126, 0, 34),
		Vector3.new(-120, 0, 85),
		Vector3.new(-35, 0, 89),
		Vector3.new(35, 0, 89),
		Vector3.new(120, 0, 85),
	}) do
		for scrapIndex = 1, 3 do
			local size = Vector3.new(
				5 + scrapIndex,
				2 + (pileIndex + scrapIndex) % 3,
				5 + (pileIndex * scrapIndex) % 4
			)
			local offset = Vector3.new((scrapIndex - 2) * 3.2, size.Y / 2, (scrapIndex % 2) * 2.4)
			local scrap = createPart(
				string.format("TrashPile_%d_%d", pileIndex, scrapIndex),
				dump,
				size,
				CFrame.new(dumpCenter + pileOffset + offset)
					* CFrame.Angles(
						math.rad(scrapIndex * 8),
						math.rad(pileIndex * 21 + scrapIndex * 17),
						0
					),
				if scrapIndex == 1
					then Color3.fromRGB(54, 63, 55)
					elseif scrapIndex == 2 then Color3.fromRGB(108, 82, 55)
					else Color3.fromRGB(91, 88, 79),
				if scrapIndex == 2 then Enum.Material.CorrodedMetal else Enum.Material.Ground
			)
			scrap.Shape = if scrapIndex == 1 then Enum.PartType.Ball else Enum.PartType.Block
		end
	end

	local arrival = createPart(
		"DumpArrival",
		dump,
		Vector3.new(7, 0.2, 7),
		CFrame.new(dumpCenter + Vector3.new(112, 0.55, 0)),
		Color3.fromRGB(120, 255, 150),
		Enum.Material.Neon,
		1,
		false
	)
	local ladderPlacement = createPart(
		"LadderPlacement",
		dump,
		Vector3.new(12, 0.3, 12),
		CFrame.new(LADDER_PLACEMENT_POSITION),
		Color3.fromRGB(226, 168, 62),
		Enum.Material.Neon,
		0.35,
		false
	)
	local ladderPrompt = addPrompt(ladderPlacement, "Place Ladder", "Aircraft Yard Access", 0.5)

	local state = {
		cans = {},
		searched = {},
		onboardingAttempts = {},
		searchCount = 0,
		refilling = false,
		positions = {},
	}
	sharedTrashState = state
	for _, xOffset in ipairs({ -105, -63, -21, 21, 63, 105 }) do
		for _, zOffset in ipairs({ -45, -15, 15, 45 }) do
			table.insert(state.positions, dumpCenter + Vector3.new(xOffset, 0.5, zOffset))
		end
	end
	for index = 1, Config.Trash.CanCount do
		local can = createTrashcan(dump, dumpCenter, index)
		table.insert(state.cans, can)
		SecurePrompt.bind(can.prompt, Config.Trash.SearchSeconds, function(searchingPlayer)
			searchTrashcan(searchingPlayer, index)
		end)
	end
	randomizeTrashcanPositions(state)

	local dumpsterState = {
		dumpsters = {},
		searched = {},
		searchCount = 0,
		refilling = false,
	}
	sharedDumpsterState = dumpsterState
	for index, offset in ipairs({
		Vector3.new(-80, 0.5, -76),
		Vector3.new(80, 0.5, -76),
		Vector3.new(-80, 0.5, 76),
		Vector3.new(80, 0.5, 76),
	}) do
		local dumpster = createDumpster(dump, dumpCenter + offset, index)
		table.insert(dumpsterState.dumpsters, dumpster)
		SecurePrompt.bind(
			dumpster.prompt,
			Config.Trash.DumpsterSearchSeconds,
			function(searchingPlayer)
				searchDumpster(searchingPlayer, index)
			end,
			function(searchingPlayer)
				return PlayerData.getLevel(searchingPlayer) >= Config.Trash.DumpsterMinimumLevel
			end,
			function(searchingPlayer)
				notify(
					searchingPlayer,
					string.format(
						"Level %d required to search dumpsters.",
						Config.Trash.DumpsterMinimumLevel
					)
				)
			end
		)
	end

	return {
		model = dump,
		arrival = arrival,
		ladderPrompt = ladderPrompt,
	}
end

local PLANE_DIRT_CANDIDATES = {
	{ Size = Vector3.new(4, 0.22, 3), Offset = CFrame.new(-7, 1.7, -1) },
	{ Size = Vector3.new(4, 0.22, 3), Offset = CFrame.new(7, 1.7, -1) },
	{ Size = Vector3.new(3, 0.22, 3), Offset = CFrame.new(0, 2.7, -7) },
	{ Size = Vector3.new(3, 0.22, 3), Offset = CFrame.new(0, 2.7, 1) },
	{ Size = Vector3.new(3, 0.22, 2.5), Offset = CFrame.new(-13, 1.1, 1) },
	{ Size = Vector3.new(3, 0.22, 2.5), Offset = CFrame.new(13, 1.1, 1) },
	{
		Size = Vector3.new(3, 0.22, 2.5),
		Offset = CFrame.new(-1.85, 0.2, 7) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.5),
		Offset = CFrame.new(1.85, 0.2, 7) * CFrame.Angles(0, 0, math.rad(90)),
	},
}

local HELICOPTER_DIRT_CANDIDATES = {
	{ Size = Vector3.new(3, 0.22, 2.5), Offset = CFrame.new(-2.5, 2.6, -2) },
	{ Size = Vector3.new(3, 0.22, 2.5), Offset = CFrame.new(2.5, 2.6, -2) },
	{ Size = Vector3.new(3, 0.22, 2.5), Offset = CFrame.new(-2.5, 2.4, 3) },
	{ Size = Vector3.new(3, 0.22, 2.5), Offset = CFrame.new(2.5, 2.4, 3) },
	{
		Size = Vector3.new(3, 0.22, 2.5),
		Offset = CFrame.new(-4.15, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{
		Size = Vector3.new(3, 0.22, 2.5),
		Offset = CFrame.new(4.15, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	},
	{ Size = Vector3.new(3, 0.22, 3), Offset = CFrame.new(0, 1.1, 9) },
	{ Size = Vector3.new(2.5, 0.22, 2.5), Offset = CFrame.new(0, 4.2, 0) },
}

local function aircraftBayCenter(slotIndex: number): Vector3
	local zeroIndex = math.max(0, slotIndex - 1)
	local column = zeroIndex % 2
	local row = math.floor(zeroIndex / 2)
	return LEVEL_TWO_DUMP_CENTER
		+ Vector3.new(if column == 0 then -95 else 95, 0, -225 + (row % 4) * 150)
end

local function createPlane(player: Player, baseCFrame: CFrame): Model
	local plane = Instance.new("Model")
	plane.Name = string.format("%s_OldPlane", player.Name)
	plane:SetAttribute("OwnerUserId", player.UserId)
	plane:SetAttribute("VehicleDisplayName", "Old Plane")
	plane:SetAttribute("AircraftType", "plane")
	plane:SetAttribute("RequiredCleaningTier", 2)
	plane:SetAttribute("CompletionCoins", 0)
	plane:SetAttribute("CompletionExperience", 0)
	plane.Parent = carsFolder

	local body = createPart(
		"Fuselage",
		plane,
		Vector3.new(4, 4, 20),
		baseCFrame,
		Color3.fromRGB(120, 126, 118),
		Enum.Material.CorrodedMetal
	)
	plane.PrimaryPart = body
	createPart(
		"Wing",
		plane,
		Vector3.new(32, 0.8, 7),
		baseCFrame * CFrame.new(0, 0, 1),
		Color3.fromRGB(103, 111, 105),
		Enum.Material.CorrodedMetal
	)
	createPart(
		"TailWing",
		plane,
		Vector3.new(13, 0.65, 4),
		baseCFrame * CFrame.new(0, 1.1, 8),
		Color3.fromRGB(96, 103, 98),
		Enum.Material.CorrodedMetal
	)
	createPart(
		"TailFin",
		plane,
		Vector3.new(0.8, 5, 4),
		baseCFrame * CFrame.new(0, 2.7, 8),
		Color3.fromRGB(88, 96, 91),
		Enum.Material.CorrodedMetal
	)
	createPart(
		"Cockpit",
		plane,
		Vector3.new(3.5, 2.2, 5),
		baseCFrame * CFrame.new(0, 2.2, -4),
		Color3.fromRGB(55, 77, 82),
		Enum.Material.Glass,
		0.18,
		false
	)
	addDirtPatches(player, plane, baseCFrame, PLANE_DIRT_CANDIDATES, #PLANE_DIRT_CANDIDATES)
	return plane
end

local function createHelicopter(player: Player, baseCFrame: CFrame): Model
	local helicopter = Instance.new("Model")
	helicopter.Name = string.format("%s_OldHelicopter", player.Name)
	helicopter:SetAttribute("OwnerUserId", player.UserId)
	helicopter:SetAttribute("VehicleDisplayName", "Old Helicopter")
	helicopter:SetAttribute("AircraftType", "helicopter")
	helicopter:SetAttribute("RequiredCleaningTier", 2)
	helicopter:SetAttribute("CompletionCoins", 0)
	helicopter:SetAttribute("CompletionExperience", 0)
	helicopter.Parent = carsFolder

	local body = createPart(
		"Cabin",
		helicopter,
		Vector3.new(8, 5, 10),
		baseCFrame,
		Color3.fromRGB(101, 112, 91),
		Enum.Material.CorrodedMetal
	)
	helicopter.PrimaryPart = body
	createWedge(
		"Nose",
		helicopter,
		Vector3.new(8, 5, 4),
		baseCFrame * CFrame.new(0, 0, -7),
		Color3.fromRGB(101, 112, 91),
		Enum.Material.CorrodedMetal
	)
	createPart(
		"TailBoom",
		helicopter,
		Vector3.new(2.2, 2.2, 15),
		baseCFrame * CFrame.new(0, 0.5, 11),
		Color3.fromRGB(88, 98, 81),
		Enum.Material.CorrodedMetal
	)
	createPart(
		"RotorMast",
		helicopter,
		Vector3.new(0.8, 3, 0.8),
		baseCFrame * CFrame.new(0, 4, 0),
		Color3.fromRGB(58, 61, 58),
		Enum.Material.Metal
	)
	createPart(
		"MainRotor",
		helicopter,
		Vector3.new(30, 0.35, 1),
		baseCFrame * CFrame.new(0, 5.5, 0),
		Color3.fromRGB(45, 48, 47),
		Enum.Material.Metal
	)
	createPart(
		"CrossRotor",
		helicopter,
		Vector3.new(1, 0.35, 30),
		baseCFrame * CFrame.new(0, 5.5, 0),
		Color3.fromRGB(45, 48, 47),
		Enum.Material.Metal
	)
	for _, xOffset in ipairs({ -3, 3 }) do
		createPart(
			"LandingSkid",
			helicopter,
			Vector3.new(0.55, 0.55, 13),
			baseCFrame * CFrame.new(xOffset, -3.1, 1),
			Color3.fromRGB(49, 52, 50),
			Enum.Material.Metal
		)
	end
	addDirtPatches(
		player,
		helicopter,
		baseCFrame,
		HELICOPTER_DIRT_CANDIDATES,
		#HELICOPTER_DIRT_CANDIDATES
	)
	return helicopter
end

redirtyAircraft = function(player: Player, aircraft: Model)
	if countRemainingDirt(aircraft) > 0 or not aircraft.PrimaryPart then
		return
	end
	local aircraftType = aircraft:GetAttribute("AircraftType")
	local candidates = if aircraftType == "plane"
		then PLANE_DIRT_CANDIDATES
		else HELICOPTER_DIRT_CANDIDATES
	addDirtPatches(player, aircraft, aircraft.PrimaryPart.CFrame, candidates, #candidates)
end

local function createPlayerAircraft(player: Player, slotIndex: number)
	local oldAircraft = aircraftByPlayer[player]
	if oldAircraft then
		for _, aircraft in oldAircraft do
			aircraft:Destroy()
		end
	end
	local center = aircraftBayCenter(slotIndex)
	local aircraft = {
		createPlane(player, CFrame.new(center + Vector3.new(-28, 3, -42))),
		createHelicopter(player, CFrame.new(center + Vector3.new(28, 4, -42))),
		createPlane(
			player,
			CFrame.new(center + Vector3.new(28, 3, 42)) * CFrame.Angles(0, math.rad(180), 0)
		),
		createHelicopter(
			player,
			CFrame.new(center + Vector3.new(-28, 4, 42)) * CFrame.Angles(0, math.rad(180), 0)
		),
	}
	for index, model in aircraft do
		model.Name = string.format("%s_Aircraft_%d", player.Name, index)
	end
	aircraftByPlayer[player] = aircraft
end

local function refillFixedSalvage(state, isDumpster: boolean)
	if state.refilling then
		return
	end
	state.refilling = true
	for _, container in state.containers do
		if isDumpster then
			setDumpsterSearched(container, false)
			setDumpsterRefilling(container, true)
		else
			setTrashcanSearched(container, false)
			setTrashcanRefilling(container, true)
		end
	end
	task.delay(Config.Trash.RefillSeconds, function()
		if state ~= levelTwoTrashState and state ~= levelTwoDumpsterState then
			return
		end
		state.searched = {}
		state.searchCount = 0
		state.refilling = false
		for _, container in state.containers do
			if isDumpster then
				setDumpsterRefilling(container, false)
			else
				setTrashcanRefilling(container, false)
			end
		end
	end)
end

local function searchLevelTwoContainer(player: Player, state, index: number, isDumpster: boolean)
	if state.refilling or state.searched[index] then
		notify(player, "That container has already been looted. Find another one.")
		return
	end
	state.searched[index] = true
	state.searchCount += 1
	if isDumpster then
		setDumpsterSearched(state.containers[index], true)
	else
		setTrashcanSearched(state.containers[index], true)
	end

	local outcome = LootRules.rollTrashCan(true, math.random(1, 100))
	local baseReward = outcome.coins
		* (if isDumpster then Config.Trash.DumpsterRewardMultiplier else 1)
	local reward = LootRules.scaleAndRoundReward(baseReward, Config.Trash.LevelTwoRewardMultiplier)
	PlayerData.addCoins(player, reward)
	notify(player, string.format("Aircraft-yard salvage! +%d coins", reward))
	if state.searchCount >= state.total then
		refillFixedSalvage(state, isDumpster)
	end
end

local function createLevelTwoDump()
	local dump = Instance.new("Model")
	dump.Name = "AircraftSalvageYard"
	dump.Parent = greyboxReference.root
	local center = LEVEL_TWO_DUMP_CENTER
	local width = 400
	local depth = 620
	local fenceHeight = 13
	createPart(
		"AircraftYardFloor",
		dump,
		Vector3.new(width, 0.4, depth),
		CFrame.new(center + Vector3.new(0, 0.25, 0)),
		Color3.fromRGB(67, 62, 53),
		Enum.Material.Ground
	)

	local perimeter = Instance.new("Model")
	perimeter.Name = "PerimeterFence"
	perimeter.Parent = dump
	local function fenceRun(name: string, startPosition: Vector3, endPosition: Vector3)
		local run = Instance.new("Model")
		run.Name = name
		run.Parent = perimeter
		local delta = endPosition - startPosition
		local length = delta.Magnitude
		local direction = delta.Unit
		local segmentCount = math.ceil(length / 24)
		for index = 1, segmentCount do
			local fromDistance = length * (index - 1) / segmentCount
			local toDistance = length * index / segmentCount
			local segmentLength = toDistance - fromDistance
			local midpoint = startPosition + direction * ((fromDistance + toDistance) / 2)
			local alongX = math.abs(delta.X) >= math.abs(delta.Z)
			local size = if alongX
				then Vector3.new(segmentLength, fenceHeight, 0.35)
				else Vector3.new(0.35, fenceHeight, segmentLength)
			createPart(
				string.format("Mesh_%02d", index),
				run,
				size,
				CFrame.new(midpoint + Vector3.new(0, fenceHeight / 2, 0)),
				Color3.fromRGB(91, 101, 99),
				Enum.Material.Metal,
				0.68,
				true
			)
			for _, height in ipairs({ 0.8, fenceHeight - 0.4 }) do
				local railSize = if alongX
					then Vector3.new(segmentLength, 0.25, 0.5)
					else Vector3.new(0.5, 0.25, segmentLength)
				createPart(
					string.format("Rail_%02d_%d", index, height),
					run,
					railSize,
					CFrame.new(midpoint + Vector3.new(0, height, 0)),
					Color3.fromRGB(57, 63, 62),
					Enum.Material.Metal
				)
			end
			createPart(
				string.format("Post_%02d", index),
				run,
				Vector3.new(0.7, fenceHeight + 1, 0.7),
				CFrame.new(
					startPosition
						+ direction * fromDistance
						+ Vector3.new(0, (fenceHeight + 1) / 2, 0)
				),
				Color3.fromRGB(49, 55, 54),
				Enum.Material.Metal
			)
		end
		createPart(
			"EndPost",
			run,
			Vector3.new(0.7, fenceHeight + 1, 0.7),
			CFrame.new(endPosition + Vector3.new(0, (fenceHeight + 1) / 2, 0)),
			Color3.fromRGB(49, 55, 54),
			Enum.Material.Metal
		)
	end
	fenceRun(
		"NorthFence",
		center + Vector3.new(-width / 2, 0, -depth / 2),
		center + Vector3.new(width / 2, 0, -depth / 2)
	)
	fenceRun(
		"SouthFence",
		center + Vector3.new(-width / 2, 0, depth / 2),
		center + Vector3.new(width / 2, 0, depth / 2)
	)
	fenceRun(
		"WestFence",
		center + Vector3.new(-width / 2, 0, -depth / 2),
		center + Vector3.new(-width / 2, 0, depth / 2)
	)
	fenceRun(
		"EastFenceNorth",
		center + Vector3.new(width / 2, 0, -depth / 2),
		center + Vector3.new(width / 2, 0, -22)
	)
	fenceRun(
		"EastFenceSouth",
		center + Vector3.new(width / 2, 0, 22),
		center + Vector3.new(width / 2, 0, depth / 2)
	)

	local accessGate = Instance.new("Model")
	accessGate.Name = "AccessGate"
	accessGate.Parent = dump
	for _, zOffset in ipairs({ -22, 22 }) do
		createPart(
			"GatePost",
			accessGate,
			Vector3.new(1.2, fenceHeight + 1, 1.2),
			CFrame.new(center + Vector3.new(width / 2, (fenceHeight + 1) / 2, zOffset)),
			Color3.fromRGB(48, 54, 53),
			Enum.Material.Metal
		)
	end
	for _, zOffset in ipairs({ -11, 11 }) do
		local door = createPart(
			"GateDoor",
			accessGate,
			Vector3.new(0.45, fenceHeight - 1, 21),
			CFrame.new(center + Vector3.new(width / 2, (fenceHeight - 1) / 2, zOffset)),
			Color3.fromRGB(87, 97, 95),
			Enum.Material.Metal,
			0.64,
			true
		)
		createPart(
			"GateFrame",
			accessGate,
			Vector3.new(0.7, 0.4, 21),
			door.CFrame * CFrame.new(0, (fenceHeight - 1) / 2, 0),
			Color3.fromRGB(48, 54, 53),
			Enum.Material.Metal
		)
	end
	createPart(
		"DumpConnector",
		dump,
		Vector3.new(15, 0.4, 44),
		CFrame.new(Vector3.new(-492.5, 0.25, 0)),
		Color3.fromRGB(72, 66, 54),
		Enum.Material.Ground
	)

	local sign = createPart(
		"AircraftYardSign",
		dump,
		Vector3.new(34, 8, 1),
		CFrame.new(center + Vector3.new(width / 2 - 4, 13, -42)),
		Color3.fromRGB(105, 67, 37),
		Enum.Material.Wood
	)
	addBillboard(sign, "LEVEL 2 AIRCRAFT YARD", Color3.fromRGB(255, 209, 112))

	for pileIndex = 1, 34 do
		local side = if pileIndex % 2 == 0 then -1 else 1
		local zOffset = -285 + ((pileIndex * 43) % 570)
		local xOffset = side * (150 + (pileIndex % 3) * 12)
		for scrapIndex = 1, 5 do
			local size = Vector3.new(
				4 + scrapIndex * 2,
				2 + (pileIndex + scrapIndex) % 5,
				5 + (pileIndex * scrapIndex) % 6
			)
			createPart(
				string.format("AircraftScrap_%d_%d", pileIndex, scrapIndex),
				dump,
				size,
				CFrame.new(
					center
						+ Vector3.new(
							xOffset + scrapIndex * 2,
							size.Y / 2,
							zOffset + scrapIndex * 3
						)
				) * CFrame.Angles(math.rad(scrapIndex * 9), math.rad(pileIndex * 17), 0),
				if scrapIndex == 1 then Color3.fromRGB(93, 75, 52) else Color3.fromRGB(74, 82, 79),
				Enum.Material.CorrodedMetal
			)
		end
	end
	for moundIndex = 1, 14 do
		local xOffset = (if moundIndex % 2 == 0 then -1 else 1) * (10 + (moundIndex % 3) * 7)
		local zOffset = -275 + ((moundIndex * 109) % 550)
		for pieceIndex = 1, 8 do
			local size = Vector3.new(
				7 + (pieceIndex % 4) * 3,
				4 + (pieceIndex % 5) * 2,
				7 + ((moundIndex + pieceIndex) % 4) * 3
			)
			local radius = 4 + pieceIndex * 1.1
			createPart(
				string.format("TallTrashPile_%02d_%02d", moundIndex, pieceIndex),
				dump,
				size,
				CFrame.new(
					center
						+ Vector3.new(
							xOffset + math.sin(pieceIndex) * radius,
							size.Y / 2,
							zOffset + math.cos(pieceIndex) * radius
						)
				)
					* CFrame.Angles(
						math.rad(pieceIndex * 4),
						math.rad(moundIndex * 19 + pieceIndex * 23),
						math.rad(pieceIndex * 3)
					),
				if pieceIndex % 3 == 0
					then Color3.fromRGB(105, 76, 49)
					else Color3.fromRGB(68, 76, 70),
				Enum.Material.CorrodedMetal
			)
		end
	end
	for litterIndex = 1, 72 do
		local xOffset = -175 + ((litterIndex * 83) % 350)
		local zOffset = -285 + ((litterIndex * 137) % 570)
		createPart(
			string.format("ScatteredScrap_%03d", litterIndex),
			dump,
			Vector3.new(
				1 + litterIndex % 4,
				0.35 + (litterIndex % 3) * 0.25,
				1 + (litterIndex * 2) % 5
			),
			CFrame.new(center + Vector3.new(xOffset, 0.7, zOffset))
				* CFrame.Angles(0, math.rad(litterIndex * 29), math.rad(litterIndex % 4 * 8)),
			if litterIndex % 4 == 0 then Color3.fromRGB(128, 81, 48) else Color3.fromRGB(76, 83, 78),
			Enum.Material.CorrodedMetal,
			0,
			false
		)
	end

	levelTwoTrashState = {
		containers = {},
		searched = {},
		searchCount = 0,
		refilling = false,
		total = Config.Trash.LevelTwoCanCount,
	}
	for index = 1, Config.Trash.LevelTwoCanCount do
		local side = if index <= Config.Trash.LevelTwoCanCount / 2 then -1 else 1
		local row = (index - 1) % (Config.Trash.LevelTwoCanCount / 2)
		local position = center + Vector3.new(side * 174, 0.5, -260 + row * 58)
		local can = createTrashcan(dump, position, 100 + index)
		table.insert(levelTwoTrashState.containers, can)
		SecurePrompt.bind(can.prompt, Config.Trash.SearchSeconds, function(searchingPlayer)
			searchLevelTwoContainer(searchingPlayer, levelTwoTrashState, index, false)
		end)
	end

	levelTwoDumpsterState = {
		containers = {},
		searched = {},
		searchCount = 0,
		refilling = false,
		total = Config.Trash.LevelTwoDumpsterCount,
	}
	local dumpsterOffsets = {
		Vector3.new(-145, 0.5, -280),
		Vector3.new(145, 0.5, -280),
		Vector3.new(-145, 0.5, -185),
		Vector3.new(145, 0.5, -185),
		Vector3.new(-145, 0.5, 185),
		Vector3.new(145, 0.5, 185),
		Vector3.new(-145, 0.5, 280),
		Vector3.new(145, 0.5, 280),
	}
	for index, offset in ipairs(dumpsterOffsets) do
		local dumpster = createDumpster(dump, center + offset, 100 + index)
		table.insert(levelTwoDumpsterState.containers, dumpster)
		SecurePrompt.bind(
			dumpster.prompt,
			Config.Trash.DumpsterSearchSeconds,
			function(searchingPlayer)
				searchLevelTwoContainer(searchingPlayer, levelTwoDumpsterState, index, true)
			end,
			function(searchingPlayer)
				return PlayerData.getLevel(searchingPlayer)
					>= Config.Trash.LevelTwoDumpsterMinimumLevel
			end,
			function(searchingPlayer)
				notify(
					searchingPlayer,
					string.format(
						"Level %d required to search aircraft-yard dumpsters.",
						Config.Trash.LevelTwoDumpsterMinimumLevel
					)
				)
			end
		)
	end

	local arrival = createPart(
		"AircraftArrival",
		dump,
		Vector3.new(7, 0.2, 7),
		CFrame.new(center + Vector3.new(155, 0.55, 45)),
		Color3.fromRGB(120, 255, 150),
		Enum.Material.Neon,
		1,
		false
	)
	return { model = dump, arrival = arrival }
end

local function ensureAccessLadder()
	if sharedAccessLadder and sharedAccessLadder.Parent then
		return
	end
	local ladder = Instance.new("Model")
	ladder.Name = "AircraftYardAccessLadder"
	ladder.Parent = levelTwoDumpReference.model
	local base = LADDER_PLACEMENT_POSITION + Vector3.new(0, 0.15, 0)
	for sideIndex, zRailOffset in ipairs({ -2.2, 2.2 }) do
		createPart(
			"Rail_" .. sideIndex,
			ladder,
			Vector3.new(1, 24, 0.8),
			CFrame.new(base + Vector3.new(-8.2, 9, zRailOffset)) * CFrame.Angles(0, 0, math.rad(42)),
			Color3.fromRGB(194, 132, 49),
			Enum.Material.Wood,
			0,
			false
		)
	end
	for rungIndex = 1, 11 do
		createPart(
			"Rung_" .. rungIndex,
			ladder,
			Vector3.new(0.8, 0.7, 5.2),
			CFrame.new(base + Vector3.new((rungIndex - 1) * -1.5, 1.2 + rungIndex * 1.65, 0)),
			Color3.fromRGB(218, 158, 66),
			Enum.Material.Wood,
			0,
			false
		)
	end
	local function addAccessPrompt(name: string, position: Vector3)
		local promptPart = createPart(
			name,
			ladder,
			Vector3.new(5, 7, 7),
			CFrame.new(position),
			Color3.fromRGB(255, 255, 255),
			Enum.Material.SmoothPlastic,
			1,
			false
		)
		local prompt = addPrompt(promptPart, "Climb", "Aircraft Yard Ladder", 0.2)
		SecurePrompt.bind(prompt, 0.2, function(climbingPlayer)
			local root = getRootPart(climbingPlayer)
			if root and climbingPlayer.Character then
				local destinationX = if root.Position.X > -492.5 then -516 else -470
				climbingPlayer.Character:PivotTo(CFrame.new(destinationX, 4, 0))
			end
		end, function(climbingPlayer)
			return PlayerData.hasPlacedLadder(climbingPlayer)
		end, function(climbingPlayer)
			notify(climbingPlayer, "Place your own Salvage Ladder on the yellow marker first.")
		end)
	end
	addAccessPrompt("LevelOneAccessPrompt", Vector3.new(-475, 4, 0))
	addAccessPrompt("AircraftAccessPrompt", Vector3.new(-512, 4, 0))
	sharedAccessLadder = ladder
end

local function createSafeZone(player: Player, slotIndex: number): Model
	local center = PlotRules.positionForSlot(slotIndex)
	local zone = Instance.new("Model")
	zone.Name = string.format("SafeZone_%d_%s", player.UserId, player.Name)
	zone:SetAttribute("OwnerUserId", player.UserId)
	zone.Parent = greyboxReference.safeZones

	createPart(
		"SafeZonePad",
		zone,
		Vector3.new(120, 0.35, 90),
		CFrame.new(center + Vector3.new(0, 0.25, 0)),
		Color3.fromRGB(91, 165, 202),
		Enum.Material.Concrete
	)
	createPart(
		"BoundaryNorth",
		zone,
		Vector3.new(120, 0.3, 0.5),
		CFrame.new(center + Vector3.new(0, 0.55, -45)),
		Color3.fromRGB(70, 225, 255),
		Enum.Material.Neon,
		0.25,
		false
	)
	createPart(
		"BoundarySouth",
		zone,
		Vector3.new(120, 0.3, 0.5),
		CFrame.new(center + Vector3.new(0, 0.55, 45)),
		Color3.fromRGB(70, 225, 255),
		Enum.Material.Neon,
		0.25,
		false
	)
	createPart(
		"BoundaryEast",
		zone,
		Vector3.new(0.5, 0.3, 90),
		CFrame.new(center + Vector3.new(60, 0.55, 0)),
		Color3.fromRGB(70, 225, 255),
		Enum.Material.Neon,
		0.25,
		false
	)
	createPart(
		"BoundaryWest",
		zone,
		Vector3.new(0.5, 0.3, 90),
		CFrame.new(center + Vector3.new(-60, 0.55, 0)),
		Color3.fromRGB(70, 225, 255),
		Enum.Material.Neon,
		0.25,
		false
	)

	createPart(
		"CarSpawn",
		zone,
		Vector3.new(20, 0.15, 38),
		CFrame.new(center + Vector3.new(-10, 0.52, -3)),
		Color3.fromRGB(255, 226, 86),
		Enum.Material.Neon,
		0.75,
		false
	)
	local playerSpawn = createPart(
		"PlayerSpawn",
		zone,
		Vector3.new(6, 0.15, 6),
		CFrame.new(center + Vector3.new(-10, 0.55, 34)),
		Color3.fromRGB(90, 255, 128),
		Enum.Material.Neon,
		0.55,
		false
	)
	createPart(
		"BaseArrival",
		zone,
		Vector3.new(6, 0.15, 6),
		CFrame.new(center + Vector3.new(-24, 0.55, 34)),
		Color3.fromRGB(90, 255, 128),
		Enum.Material.Neon,
		1,
		false
	)
	local sign = createPart(
		"OwnerSign",
		zone,
		Vector3.new(15, 5, 1),
		CFrame.new(center + Vector3.new(-42, 3, 43)),
		Color3.fromRGB(28, 36, 42),
		Enum.Material.SmoothPlastic
	)
	addBillboard(sign, player.DisplayName .. "'s Safe Zone", Color3.fromRGB(125, 235, 255))

	zone.PrimaryPart = playerSpawn
	return zone
end

local function claimZoneSlot(player: Player): number?
	local slotIndex = 1
	while true do
		if not zoneOwners[slotIndex] then
			zoneOwners[slotIndex] = player
			playerZoneSlots[player] = slotIndex
			return slotIndex
		end
		slotIndex += 1
	end
end

local function moveCharacterToZone(player: Player, character: Model)
	local zone = playerZones[player]
	local marker = zone and zone:FindFirstChild("PlayerSpawn")
	if marker and marker:IsA("BasePart") then
		character:PivotTo(marker.CFrame + Vector3.new(0, 3, 0))
	end
end

local function setupPlayer(player: Player)
	if not PlayerData.waitUntilLoaded(player) then
		return
	end
	local slotIndex = claimZoneSlot(player)
	if not slotIndex then
		notify(player, "All prototype safe zones are currently occupied.")
		return
	end

	local zone = createSafeZone(player, slotIndex)
	playerZones[player] = zone
	spawnDirtyCar(player)
	createPlayerAircraft(player, slotIndex)
	if PlayerData.hasPlacedLadder(player) then
		ensureAccessLadder()
	end
	player.CharacterAdded:Connect(function(character)
		task.wait(0.15)
		moveCharacterToZone(player, character)
	end)
	if player.Character then
		moveCharacterToZone(player, player.Character)
	end
end

local function cleanupPlayer(player: Player)
	cancelCleaning(player)
	local car = activeCars[player]
	if car then
		vehicleHelpers[car] = nil
		car:Destroy()
	end
	local zone = playerZones[player]
	if zone then
		zone:Destroy()
	end
	local aircraft = aircraftByPlayer[player]
	if aircraft then
		for _, model in aircraft do
			model:Destroy()
		end
	end
	local slotIndex = playerZoneSlots[player]
	if slotIndex then
		zoneOwners[slotIndex] = nil
	end
	activeCars[player] = nil
	playerZones[player] = nil
	playerZoneSlots[player] = nil
	vehicleSchedules[player] = nil
	lastVehicleColorIndexes[player] = nil
	lastVehicleHadChaos[player] = nil
	teleportCooldowns[player] = nil
	aircraftByPlayer[player] = nil
end

function PrototypeGameplay.start(greybox)
	greyboxReference = greybox
	local oldCarsFolder = Workspace:FindFirstChild(Config.World.PrototypeCarsFolderName)
	if oldCarsFolder then
		oldCarsFolder:Destroy()
	end
	local newCarsFolder = Instance.new("Folder")
	newCarsFolder.Name = Config.World.PrototypeCarsFolderName
	newCarsFolder.Parent = Workspace
	carsFolder = newCarsFolder
	sharedDumpReference = createSharedDump()
	levelTwoDumpReference = createLevelTwoDump()
	SecurePrompt.bind(sharedDumpReference.ladderPrompt, 0.5, function(player)
		local equippedItem = PlayerData.getEquippedToolItem(player)
		if not equippedItem or equippedItem.toolId ~= "item_salvage_ladder" then
			notify(player, "Equip the Salvage Ladder from your inventory before placing it here.")
			return
		end
		local success, message = PlayerData.placeLadder(player)
		notify(player, message)
		if success then
			ensureAccessLadder()
		end
	end, function(player)
		return PlayerData.getLevel(player) >= Config.LevelTwoDump.AccessLevel
	end, function(player)
		notify(
			player,
			string.format(
				"Level %d required before you can place an aircraft-yard ladder.",
				Config.LevelTwoDump.AccessLevel
			)
		)
	end)

	local shopPrompt = addPrompt(greybox.shopClerk, "Talk", "Milo - Shop Clerk", 0.2)
	shopPrompt.Triggered:Connect(function(player)
		Remotes.get("OpenShopDialogue")
			:FireClient(player, Catalog.getShopTools(), greybox.shopClerk)
	end)

	Remotes.connect("CleaningClick", handleCleaningClick)
	Remotes.connect("ClaimQualitySpongeAbility", function(player)
		local item = PlayerData.getEquippedToolItem(player)
		if not item or item.toolId ~= "tool_quality_sponge" or item.durability <= 0 then
			return
		end
		if
			PlayerData.claimQualitySpongeAbility(player, Config.Cleaning.QualitySpongeAbilityReward)
		then
			notify(
				player,
				string.format(
					"Quality Sponge ability claimed! +%d coins",
					Config.Cleaning.QualitySpongeAbilityReward
				)
			)
		end
	end)
	Remotes.connect("RequestCleanSpot", function(player, dirt)
		if
			typeof(dirt) ~= "Instance"
			or not dirt:IsA("BasePart")
			or dirt:GetAttribute("IsDirtPatch") ~= true
		then
			return
		end
		if not carsFolder or not dirt:IsDescendantOf(carsFolder) then
			return
		end
		local car = dirt:FindFirstAncestorOfClass("Model")
		if car then
			beginCleaning(player, dirt, car)
		end
	end)
	Remotes.connect("PurchaseTool", function(player, toolId)
		if type(toolId) ~= "string" or not isNear(player, greybox.shopClerk, 22) then
			notify(player, "Move closer to the shop counter to buy that.")
			return
		end
		local success, message = PlayerData.purchaseTool(player, toolId)
		notify(player, message)
		if success then
			local definition = Catalog.getTool(toolId)
			notify(player, string.format("%s equipped automatically.", definition.DisplayName))
		end
	end)
	Remotes.connect("SellInventoryItem", function(player, itemId)
		if type(itemId) ~= "string" or not isNear(player, greybox.shopClerk, 22) then
			notify(player, "Milo only buys tools while you are at his counter.")
			return
		end
		local _, message = PlayerData.sellInventoryItem(player, itemId)
		notify(player, message)
	end)
	Remotes.connect("SetAssistanceMode", function(player, mode)
		if not AssistanceRules.isValidMode(mode) then
			return
		end
		if PlayerData.setAssistanceMode(player, mode) then
			notify(player, "Wash assistance is now " .. string.upper(mode) .. ".")
		end
	end)
	Remotes.connect("RequestTeleport", function(player, locationId)
		if type(locationId) ~= "string" then
			return
		end
		if activeCleaning[player] then
			notify(player, "Finish cleaning this spot before travelling.")
			return
		end
		if locationId == "event" then
			local eventArrival = CooperativeEventSystem.getArrival()
			if not CooperativeEventSystem.isActive() or not eventArrival then
				notify(player, "That city event has ended.")
				return
			end
			teleportPlayer(player, eventArrival)
			return
		end
		if not Config.Teleports.Locations[locationId] then
			return
		end
		local unlocked, message = PlayerData.unlockTeleport(player, locationId)
		if not unlocked then
			notify(player, message)
			return
		end
		if message ~= "" then
			notify(player, message)
		end

		local destination
		if locationId == "home" then
			local zone = playerZones[player]
			destination = zone and zone:FindFirstChild("BaseArrival")
		elseif locationId == "shop" then
			destination = greybox.shopArrival
		elseif locationId == "dump" then
			destination = sharedDumpReference and sharedDumpReference.arrival
		elseif locationId == "aircraft" then
			destination = levelTwoDumpReference and levelTwoDumpReference.arrival
		end
		if destination and destination:IsA("BasePart") then
			teleportPlayer(player, destination)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(setupPlayer, player)
	end)
	Players.PlayerRemoving:Connect(cleanupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(setupPlayer, player)
	end

	task.spawn(function()
		while true do
			task.wait(0.25)
			for player, session in pairs(activeCleaning) do
				if
					not player.Parent
					or not session.spot.Parent
					or not isNear(player, session.spot, Config.Cleaning.MaxDistance)
				then
					cancelCleaning(player, "You moved too far away. This spot became dirty again.")
				else
					local equippedItem = PlayerData.getEquippedToolItem(player)
					if not equippedItem or equippedItem.id ~= session.itemId then
						cancelCleaning(player, "Cleaning stopped because you changed tools.")
					end
				end
			end
		end
	end)
end

return PrototypeGameplay
