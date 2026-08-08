--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage.Shared.Domain:WaitForChild("CooperativeEventRules"))
local SecurePrompt =
	require(script.Parent.Parent:WaitForChild("Infrastructure"):WaitForChild("SecurePrompt"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local CooperativeEventSystem = {}

local arrival: BasePart? = nil
local busParts: { BasePart } = {}
local stations: { { part: Part, prompt: ProximityPrompt } } = {}
local activeSessions: { [Player]: { phaseIndex: number, lastActionAt: number } } = {}
local contributions: { [Player]: number } = {}
local phaseContributions: { [Player]: number } = {}
local phaseTokensEarned: { [Player]: number } = {}
local current = {
	active = false,
	phaseIndex = 0,
	progress = 0,
	goal = 0,
	endsAt = 0,
	nextStartsAt = 0,
	comboAlternations = 0,
}
local nextStartClock = 0
local transitioning = false
local lastContributor: Player? = nil
local lastContributionAt = 0
local broadcastQueued = false

local function createPart(
	name: string,
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.Parent = parent
	return part
end

local function addBillboard(parent: BasePart, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(300, 52)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 39, 47)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 231, 132)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function getSnapshot(): any
	local phase = Config.CooperativeEvent.Phases[current.phaseIndex]
	return {
		active = current.active,
		eventId = "muddy_city_bus",
		displayName = "Mud-Covered City Bus",
		phaseIndex = current.phaseIndex,
		phaseId = phase and phase.Id or nil,
		phaseName = phase and phase.DisplayName or nil,
		toolName = phase and phase.ToolName or nil,
		progress = current.progress,
		goal = current.goal,
		endsAt = current.endsAt,
		nextStartsAt = current.nextStartsAt,
		combo = math.min(25, current.comboAlternations),
	}
end

local function broadcastNow()
	broadcastQueued = false
	Remotes.get("CooperativeEventState"):FireAllClients(getSnapshot())
end

local function queueBroadcast()
	if broadcastQueued then
		return
	end
	broadcastQueued = true
	task.delay(0.1, broadcastNow)
end

local function setActiveVisuals(active: boolean)
	for _, part in busParts do
		part.Transparency = if active then 0 else 0.72
	end
	for index, station in stations do
		station.prompt.Enabled = active and index == current.phaseIndex
		station.part.Material = if active and index == current.phaseIndex
			then Enum.Material.Neon
			else Enum.Material.Metal
	end
end

local function countNearbyPlayers(): number
	if not arrival then
		return 1
	end
	local count = 0
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if
			root
			and root:IsA("BasePart")
			and (root.Position - arrival.Position).Magnitude <= 150
		then
			count += 1
		end
	end
	return math.max(1, count)
end

local function beginPhase(index: number)
	current.phaseIndex = index
	current.progress = 0
	current.goal = Rules.phaseGoal(Config.CooperativeEvent.BasePhaseGoal, countNearbyPlayers())
	phaseContributions = {}
	activeSessions = {}
	transitioning = false
	setActiveVisuals(true)
	broadcastNow()
end

local function scheduleNextEvent()
	local delaySeconds = math.random(
		Config.CooperativeEvent.MinimumRepeatDelaySeconds,
		Config.CooperativeEvent.MaximumRepeatDelaySeconds
	)
	nextStartClock = os.clock() + delaySeconds
	current.nextStartsAt = os.time() + delaySeconds
	queueBroadcast()
end

local function endEvent(completed: boolean)
	if not current.active then
		return
	end
	if completed then
		local meaningfulPlayers = {}
		local totalContribution = 0
		for player, contribution in contributions do
			if
				player.Parent
				and Rules.isMeaningful(
					contribution,
					Config.CooperativeEvent.MinimumMeaningfulContribution
				)
			then
				table.insert(meaningfulPlayers, player)
				totalContribution += contribution
			end
		end
		for _, player in meaningfulPlayers do
			local participation, combo = Rules.completionTokens(
				contributions[player],
				totalContribution,
				#meaningfulPlayers,
				current.comboAlternations
			)
			local award = participation + combo
			PlayerData.addEventTokens(player, award)
			Remotes.get("Notify")
				:FireClient(player, string.format("Bus event complete! +%d event tokens", award))
		end
	else
		for player, tokenCount in phaseTokensEarned do
			if player.Parent and tokenCount > 0 then
				Remotes.get("Notify"):FireClient(
					player,
					"The bus departed. Tokens from completed phases are yours to keep."
				)
			end
		end
	end
	current.active = false
	current.phaseIndex = 0
	current.progress = 0
	current.goal = 0
	current.endsAt = 0
	activeSessions = {}
	setActiveVisuals(false)
	scheduleNextEvent()
	broadcastNow()
end

local function completePhase()
	if transitioning then
		return
	end
	transitioning = true
	for player, contribution in phaseContributions do
		if player.Parent then
			local award = Rules.phaseToken(contribution)
			if award > 0 then
				phaseTokensEarned[player] = (phaseTokensEarned[player] or 0) + award
				PlayerData.addEventTokens(player, award)
			end
		end
	end
	if current.phaseIndex >= #Config.CooperativeEvent.Phases then
		endEvent(true)
	else
		task.delay(0.65, function()
			if current.active then
				beginPhase(current.phaseIndex + 1)
			end
		end)
	end
end

local function startEvent()
	if current.active then
		return
	end
	current.active = true
	current.endsAt = os.time() + Config.CooperativeEvent.DurationSeconds
	current.nextStartsAt = 0
	current.comboAlternations = 0
	contributions = {}
	phaseContributions = {}
	phaseTokensEarned = {}
	lastContributor = nil
	lastContributionAt = 0
	for _, player in Players:GetPlayers() do
		Remotes.get("Notify")
			:FireClient(player, "CITY EVENT: A mud-covered bus needs a crew. Travel is free!")
	end
	beginPhase(1)
end

local function beginMinigame(player: Player, stationIndex: number)
	if not current.active or transitioning or current.phaseIndex ~= stationIndex then
		return
	end
	activeSessions[player] = { phaseIndex = stationIndex, lastActionAt = 0 }
	local phase = Config.CooperativeEvent.Phases[stationIndex]
	Remotes.get("CooperativeEventMinigame"):FireClient(player, {
		active = true,
		phaseIndex = stationIndex,
		phaseId = phase.Id,
		phaseName = phase.DisplayName,
		toolName = phase.ToolName,
	})
end

local function handleAction(player: Player, phaseId: any)
	local session = activeSessions[player]
	local phase = Config.CooperativeEvent.Phases[current.phaseIndex]
	if
		not current.active
		or transitioning
		or not session
		or session.phaseIndex ~= current.phaseIndex
		or type(phaseId) ~= "string"
		or not phase
		or phase.Id ~= phaseId
	then
		return
	end
	local station = stations[current.phaseIndex]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if
		not root
		or not root:IsA("BasePart")
		or (root.Position - station.part.Position).Magnitude > 32
	then
		activeSessions[player] = nil
		return
	end
	local now = os.clock()
	if now - session.lastActionAt < 0.075 then
		return
	end
	session.lastActionAt = now
	if lastContributor and lastContributor ~= player and now - lastContributionAt <= 2 then
		current.comboAlternations += 1
	end
	lastContributor = player
	lastContributionAt = now
	contributions[player] = (contributions[player] or 0) + 1
	phaseContributions[player] = (phaseContributions[player] or 0) + 1
	current.progress = math.min(current.goal, current.progress + 1)
	queueBroadcast()
	if current.progress >= current.goal then
		completePhase()
	end
end

local function buildLot(root: Instance)
	local previous = root:FindFirstChild("CityCooperativeEventLot")
	if previous then
		previous:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "CityCooperativeEventLot"
	model.Parent = root
	local center = Config.CooperativeEvent.EventCenter
	createPart(
		"EventLot",
		model,
		Vector3.new(180, 0.5, 130),
		CFrame.new(center + Vector3.new(0, 0.25, 0)),
		Color3.fromRGB(83, 88, 89),
		Enum.Material.Concrete
	)
	local sign = createPart(
		"EventSign",
		model,
		Vector3.new(28, 7, 1),
		CFrame.new(center + Vector3.new(0, 8, -57)),
		Color3.fromRGB(35, 77, 92),
		Enum.Material.Metal
	)
	addBillboard(sign, "CITY COOPERATIVE EVENT LOT")
	arrival = createPart(
		"EventArrival",
		model,
		Vector3.new(8, 0.2, 8),
		CFrame.new(center + Vector3.new(0, 0.6, 48)),
		Color3.fromRGB(89, 239, 158),
		Enum.Material.Neon,
		1
	)

	local bus = Instance.new("Model")
	bus.Name = "MudCoveredCityBus"
	bus.Parent = model
	local busColor = Color3.fromRGB(226, 188, 48)
	local body = createPart(
		"Body",
		bus,
		Vector3.new(18, 11, 48),
		CFrame.new(center + Vector3.new(0, 7, 0)),
		busColor,
		Enum.Material.Metal
	)
	bus.PrimaryPart = body
	table.insert(busParts, body)
	local roof = createPart(
		"Roof",
		bus,
		Vector3.new(18.5, 1, 48.5),
		CFrame.new(center + Vector3.new(0, 13, 0)),
		Color3.fromRGB(230, 224, 195),
		Enum.Material.Metal
	)
	table.insert(busParts, roof)
	for sideIndex, x in ipairs({ -9.1, 9.1 }) do
		for windowIndex = 1, 7 do
			local window = createPart(
				string.format("Window_%d_%d", sideIndex, windowIndex),
				bus,
				Vector3.new(0.3, 4, 5),
				CFrame.new(center + Vector3.new(x, 9, -18 + (windowIndex - 1) * 6)),
				Color3.fromRGB(44, 88, 109),
				Enum.Material.Glass
			)
			table.insert(busParts, window)
		end
	end
	for wheelIndex, offset in ipairs({
		Vector3.new(-9.5, 3, -16),
		Vector3.new(9.5, 3, -16),
		Vector3.new(-9.5, 3, 16),
		Vector3.new(9.5, 3, 16),
	}) do
		local wheel = createPart(
			"Wheel_" .. wheelIndex,
			bus,
			Vector3.new(2.5, 7, 7),
			CFrame.new(center + offset),
			Color3.fromRGB(29, 31, 32),
			Enum.Material.Rubber
		)
		table.insert(busParts, wheel)
	end
	for dirtIndex = 1, 18 do
		local side = if dirtIndex % 2 == 0 then -1 else 1
		local dirt = createPart(
			"MudPatch_" .. dirtIndex,
			bus,
			Vector3.new(0.35, 1.4 + dirtIndex % 3, 2.5 + dirtIndex % 4),
			CFrame.new(
				center + Vector3.new(side * 9.3, 5 + dirtIndex % 6, -20 + (dirtIndex * 7) % 40)
			),
			Color3.fromRGB(91, 67, 43),
			Enum.Material.Ground
		)
		table.insert(busParts, dirt)
	end

	local stationOffsets = {
		Vector3.new(-34, 1.5, -26),
		Vector3.new(-34, 1.5, 0),
		Vector3.new(-34, 1.5, 26),
		Vector3.new(34, 1.5, -26),
		Vector3.new(34, 1.5, 0),
		Vector3.new(34, 1.5, 26),
	}
	for index, phase in Config.CooperativeEvent.Phases do
		local stationPart = createPart(
			"Station_" .. phase.Id,
			model,
			Vector3.new(12, 3, 12),
			CFrame.new(center + stationOffsets[index]),
			Color3.fromRGB(61, 115, 132),
			Enum.Material.Metal
		)
		addBillboard(stationPart, string.upper(phase.DisplayName))
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Use " .. phase.ToolName
		prompt.ObjectText = phase.DisplayName
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = stationPart
		table.insert(stations, { part = stationPart, prompt = prompt })
		SecurePrompt.bind(prompt, 0.2, function(player)
			beginMinigame(player, index)
		end, function()
			return current.active and current.phaseIndex == index and not transitioning
		end)
	end
	setActiveVisuals(false)
end

function CooperativeEventSystem.isActive(): boolean
	return current.active
end

function CooperativeEventSystem.getArrival(): BasePart?
	return arrival
end

function CooperativeEventSystem.start(root: Instance)
	buildLot(root)
	nextStartClock = os.clock() + Config.CooperativeEvent.FirstDelaySeconds
	current.nextStartsAt = os.time() + Config.CooperativeEvent.FirstDelaySeconds
	Remotes.connect("CooperativeEventAction", handleAction)
	Remotes.connect("RequestCooperativeEventState", function(player)
		Remotes.get("CooperativeEventState"):FireClient(player, getSnapshot())
	end)
	Remotes.connect("ForceCooperativeEvent", function()
		if RunService:IsStudio() then
			startEvent()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		activeSessions[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if current.active and os.time() >= current.endsAt then
				endEvent(false)
			elseif not current.active and os.clock() >= nextStartClock then
				startEvent()
			end
		end
	end)
end

return CooperativeEventSystem
