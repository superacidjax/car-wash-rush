local Config = {}

Config.GenerateGreyboxOnStart = true

Config.Currency = {
	StartingCoins = 0,
}

Config.Player = {
	WalkSpeed = 16,
	SprintMultiplier = 1.55,
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
	LevelTwoCanCount = 12,
	LevelTwoDumpsterCount = 4,
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

Config.RemoteLimits = {
	CleaningClick = { Rate = 15, Burst = 20 },
	ClaimQualitySpongeAbility = { Rate = 2, Burst = 3 },
	EquipInventoryItem = { Rate = 3, Burst = 5 },
	PurchaseTool = { Rate = 2, Burst = 4 },
	RequestCleanSpot = { Rate = 4, Burst = 6 },
	RequestInventory = { Rate = 0.5, Burst = 2 },
	RequestTeleport = { Rate = 1, Burst = 2 },
	SellInventoryItem = { Rate = 3, Burst = 5 },
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
