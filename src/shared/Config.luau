local Config = {}

Config.GenerateGreyboxOnStart = true

Config.Currency = {
	StartingCoins = 0,
}

Config.Player = {
	WalkSpeed = 16,
	SprintMultiplier = 1.55,
}

Config.Multiplayer = {
	PrototypeMaxPlayers = 8,
}

Config.Assistance = {
	HelperWageMultiplier = 0.3,
	OwnerCooperationBonusMultiplier = 0.1,
}

Config.Chaos = {
	ProtectedCompletedCars = 3,
	Chance = 0.12,
	Types = { "customer_roll", "unusual_dirt" },
}

Config.Demand = {
	IntervalSeconds = 20 * 60,
	MinimumDurationSeconds = 8 * 60,
	MaximumDurationSeconds = 12 * 60,
	Events = {
		{
			Id = "festival_traffic",
			DisplayName = "Festival Traffic",
			Description = "Busy streets are paying 20% more for clean vehicles.",
			CoinMultiplier = 1.2,
		},
		{
			Id = "dust_storm",
			DisplayName = "Dust Storm",
			Description = "Dusty arrivals are paying 25% more citywide.",
			CoinMultiplier = 1.25,
		},
		{
			Id = "farm_rush",
			DisplayName = "Farm Equipment Rush",
			Description = "Heavy-work customers are paying 20% more.",
			CoinMultiplier = 1.2,
		},
		{
			Id = "luxury_convention",
			DisplayName = "Luxury Car Convention",
			Description = "Careful cleaning earns a 30% premium.",
			CoinMultiplier = 1.3,
		},
		{
			Id = "rain_ended",
			DisplayName = "Rain Just Ended",
			Description = "Wash demand is surging: payouts are up 25%.",
			CoinMultiplier = 1.25,
		},
		{
			Id = "power_shortage",
			DisplayName = "Power Shortage",
			Description = "Manual cleaning tools earn a 35% payout bonus.",
			CoinMultiplier = 1,
			ManualToolMultiplier = 1.35,
		},
	},
}

Config.CooperativeEvent = {
	FirstDelaySeconds = 8 * 60,
	MinimumRepeatDelaySeconds = 12 * 60,
	MaximumRepeatDelaySeconds = 18 * 60,
	DurationSeconds = 10 * 60,
	EventCenter = Vector3.new(430, 0, 240),
	BasePhaseGoal = 24,
	MinimumMeaningfulContribution = 6,
	Phases = {
		{ Id = "foam", DisplayName = "Apply Foam", ToolName = "Event Foam Cannon" },
		{ Id = "scrub", DisplayName = "Scrub Dirt", ToolName = "Event Sponge" },
		{ Id = "pressure", DisplayName = "Pressure Wash", ToolName = "Event Pressure Washer" },
		{ Id = "wheels", DisplayName = "Clean Wheels", ToolName = "Event Wheel Brush" },
		{ Id = "vacuum", DisplayName = "Vacuum Interior", ToolName = "Event Vacuum" },
		{ Id = "polish", DisplayName = "Dry and Polish", ToolName = "Event Polisher" },
	},
}

Config.Inventory = {
	HotbarCapacity = 8,
}

Config.Persistence = {
	AutosaveSeconds = 60,
	SaveDebounceSeconds = 15,
	SessionLeaseSeconds = 180,
	RetryCount = 4,
	ShutdownTimeoutSeconds = 25,
}

Config.Experience = {
	DirtSpotReward = 10,
	FirstLevelRequirement = 50,
	RequirementMultiplier = 1.25,
}

Config.Trash = {
	CanCount = 12,
	PositionCount = 24,
	FirstRagChance = 40,
	FirstRagCoinChance = 20,
	PostRagSmallCoinChance = 60,
	PostRagMediumCoinChance = 30,
	PostRagJackpotChance = 10,
	SmallCoinReward = 10,
	MediumCoinReward = 30,
	JackpotCoinReward = 75,
	SearchSeconds = 6,
	DumpsterCount = 4,
	DumpsterSearchSeconds = 10,
	DumpsterMinimumLevel = 5,
	DumpsterRewardMultiplier = 2,
	LevelTwoCanCount = 20,
	LevelTwoDumpsterCount = 8,
	LevelTwoDumpsterMinimumLevel = 10,
	LevelTwoRewardMultiplier = 1.35,
	RefillSeconds = 3,
}

Config.Cleaning = {
	DecayClicksPerSecond = 0.65,
	MaxDistance = 18,
	MinimumClickInterval = 0.025,
	SpongeSpotCoinReward = 1,
	QualitySpongeChargeRequired = 10,
	QualitySpongeAbilityReward = 40,
}

Config.LevelTwoDump = {
	AccessLevel = 10,
	LadderPrice = 1000,
	AircraftRedirtySeconds = 60,
}

Config.Teleports = {
	Order = { "home", "shop", "dump", "aircraft" },
	Locations = {
		home = { DisplayName = "Home", Price = 0 },
		shop = { DisplayName = "Milo's Shop", Price = 100 },
		dump = { DisplayName = "Salvage Dump", Price = 500 },
		aircraft = {
			DisplayName = "Aircraft Yard",
			Price = 1500,
			MinimumLevel = 10,
			RequiresLadder = true,
		},
	},
}

Config.RemoteLimits = {
	CleaningClick = { Rate = 15, Burst = 20 },
	CleaningTrace = { Rate = 12, Burst = 16 },
	CooperativeEventAction = { Rate = 14, Burst = 20 },
	ClaimQualitySpongeAbility = { Rate = 2, Burst = 3 },
	EquipInventoryItem = { Rate = 3, Burst = 5 },
	PurchaseTool = { Rate = 2, Burst = 4 },
	RequestCleanSpot = { Rate = 4, Burst = 6 },
	RequestInventory = { Rate = 0.5, Burst = 2 },
	RequestDemandState = { Rate = 0.5, Burst = 2 },
	RequestCooperativeEventState = { Rate = 0.5, Burst = 2 },
	ForceCooperativeEvent = { Rate = 0.2, Burst = 1 },
	RequestTeleport = { Rate = 1, Burst = 2 },
	SellInventoryItem = { Rate = 3, Burst = 5 },
	SetAssistanceMode = { Rate = 1, Burst = 3 },
	SprintChanged = { Rate = 4, Burst = 6 },
}

Config.LevelOneVehicles = {
	{
		Id = "small_car",
		DisplayName = "Small Car",
		NormalSpawnWeight = 65,
		CompletionCoins = 25,
		CompletionExperience = 50,
		DirtCountWeights = {
			{ Count = 3, Weight = 15 },
			{ Count = 4, Weight = 25 },
			{ Count = 5, Weight = 25 },
			{ Count = 6, Weight = 25 },
			{ Count = 7, Weight = 10 },
		},
	},
	{
		Id = "pickup_truck",
		DisplayName = "Pickup Truck",
		NormalSpawnWeight = 35,
		CompletionCoins = 50,
		CompletionExperience = 60,
		DirtCountWeights = {
			{ Count = 4, Weight = 10 },
			{ Count = 8, Weight = 17 },
			{ Count = 9, Weight = 17 },
			{ Count = 10, Weight = 17 },
			{ Count = 11, Weight = 17 },
			{ Count = 12, Weight = 17 },
			{ Count = 15, Weight = 5 },
		},
	},
	{
		Id = "rv",
		DisplayName = "RV",
		CompletionCoins = 100,
		CompletionExperience = 100,
		DirtCountMin = 15,
		DirtCountMax = 20,
	},
}

Config.LevelOneRvIntervalMin = 7
Config.LevelOneRvIntervalMax = 11

Config.World = {
	RootFolderName = "Greybox_StarterCorner",
	PrototypeCarsFolderName = "PrototypeCars",
	SafeZonesFolderName = "PlayerSafeZones",
}

Config.DataStoreName = "CarWashRush_PlayerData_v1"
Config.RemotesFolderName = "CarWashRushRemotes"

return Config
