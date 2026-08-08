local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local PlayerData = {}

local DATA_VERSION = 3
local AUTOSAVE_SECONDS = 30
local SAVE_DEBOUNCE_SECONDS = 5

local dataStore = DataStoreService:GetDataStore(Config.DataStoreName)
local profiles = {}
local dirtyProfiles = {}
local canSaveProfiles = {}
local toolInstances = {}
local saveScheduled = {}

local function createDefaultProfile()
	return {
		version = DATA_VERSION,
		coins = Config.Currency.StartingCoins,
		level = 0,
		experience = 0,
		qualitySpongeCharge = 0,
		ragFound = false,
		equippedItemId = nil,
		inventory = {},
	}
end

local function normalizeProfile(rawData)
	local profile = createDefaultProfile()
	if type(rawData) ~= "table" then
		return profile
	end

	if type(rawData.coins) == "number" then
		profile.coins = math.max(0, math.floor(rawData.coins))
	end
	if type(rawData.level) == "number" then
		profile.level = math.max(0, math.floor(rawData.level))
	end
	if type(rawData.experience) == "number" then
		profile.experience = math.max(0, math.floor(rawData.experience))
	end
	if type(rawData.qualitySpongeCharge) == "number" then
		profile.qualitySpongeCharge = math.clamp(
			math.floor(rawData.qualitySpongeCharge),
			0,
			Config.Cleaning.QualitySpongeChargeRequired
		)
	end
	profile.ragFound = rawData.ragFound == true
	if type(rawData.equippedItemId) == "string" then
		profile.equippedItemId = rawData.equippedItemId
	end

	if type(rawData.inventory) == "table" then
		for _, rawItem in ipairs(rawData.inventory) do
			if
				type(rawItem) == "table"
				and type(rawItem.id) == "string"
				and type(rawItem.toolId) == "string"
			then
				local definition = Catalog.getTool(rawItem.toolId)
				if definition then
					table.insert(profile.inventory, {
						id = rawItem.id,
						toolId = rawItem.toolId,
						durability = math.clamp(
							math.floor(tonumber(rawItem.durability) or 0),
							0,
							definition.MaxDurability
						),
					})
				end
			end
		end
	end

	return profile
end

local function getItem(profile, itemId: string)
	for _, item in ipairs(profile.inventory) do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

local function roundUpToTen(value: number): number
	return math.ceil(value / 10) * 10
end

local function getExperienceRequired(level: number): number
	local required = Config.Experience.FirstLevelRequirement
	for _ = 1, level do
		required = roundUpToTen(required * Config.Experience.RequirementMultiplier)
	end
	return required
end

local function makeSnapshot(profile)
	local inventory = {}
	for _, item in ipairs(profile.inventory) do
		local definition = Catalog.getTool(item.toolId)
		table.insert(inventory, {
			id = item.id,
			toolId = item.toolId,
			displayName = definition.DisplayName,
			durability = item.durability,
			maxDurability = definition.MaxDurability,
			resaleValue = math.floor(
				definition.BaseResaleValue * item.durability / definition.MaxDurability
			),
		})
	end

	return {
		coins = profile.coins,
		level = profile.level,
		experience = profile.experience,
		experienceRequired = getExperienceRequired(profile.level),
		qualitySpongeCharge = profile.qualitySpongeCharge,
		ragFound = profile.ragFound,
		equippedItemId = profile.equippedItemId,
		inventory = inventory,
	}
end

local function updateReplicatedValues(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
	if coinsValue and coinsValue:IsA("IntValue") then
		coinsValue.Value = profile.coins
	end

	local profileFolder = player:FindFirstChild("CarWashRushProfile")
	local ragFoundValue = profileFolder and profileFolder:FindFirstChild("RagFound")
	local equippedValue = profileFolder and profileFolder:FindFirstChild("EquippedItemId")
	local levelValue = profileFolder and profileFolder:FindFirstChild("Level")
	local experienceValue = profileFolder and profileFolder:FindFirstChild("Experience")
	local experienceRequiredValue = profileFolder
		and profileFolder:FindFirstChild("ExperienceRequired")
	local qualitySpongeChargeValue = profileFolder
		and profileFolder:FindFirstChild("QualitySpongeCharge")
	if ragFoundValue and ragFoundValue:IsA("BoolValue") then
		ragFoundValue.Value = profile.ragFound
	end
	if equippedValue and equippedValue:IsA("StringValue") then
		equippedValue.Value = profile.equippedItemId or ""
	end
	if levelValue and levelValue:IsA("IntValue") then
		levelValue.Value = profile.level
	end
	if experienceValue and experienceValue:IsA("IntValue") then
		experienceValue.Value = profile.experience
	end
	if experienceRequiredValue and experienceRequiredValue:IsA("IntValue") then
		experienceRequiredValue.Value = getExperienceRequired(profile.level)
	end
	if qualitySpongeChargeValue and qualitySpongeChargeValue:IsA("IntValue") then
		qualitySpongeChargeValue.Value = profile.qualitySpongeCharge
	end

	Remotes.get("InventoryUpdated"):FireClient(player, makeSnapshot(profile))
end

local function updateToolInstance(player: Player, item)
	local playerTools = toolInstances[player]
	local tool = playerTools and playerTools[item.id]
	if not tool or not tool.Parent then
		return
	end

	local definition = Catalog.getTool(item.toolId)
	local prefix = if item.durability <= 0 then "Broken " else ""
	tool.Name = string.format(
		"%s%s [%d/%d]",
		prefix,
		definition.DisplayName,
		item.durability,
		definition.MaxDurability
	)
	tool.ToolTip = string.format(
		"%s - Durability %d/%d",
		definition.DisplayName,
		item.durability,
		definition.MaxDurability
	)
	tool:SetAttribute("Durability", item.durability)
end

local function createToolInstance(player: Player, item): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return nil
	end

	local definition = Catalog.getTool(item.toolId)
	local tool = Instance.new("Tool")
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("CarWashRushTool", true)
	tool:SetAttribute("InventoryItemId", item.id)
	tool:SetAttribute("ToolId", item.toolId)
	tool:SetAttribute("MaxDurability", definition.MaxDurability)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = definition.HandleSize
	handle.Color = definition.HandleColor
	handle.Material = definition.Material
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	tool.Equipped:Connect(function()
		local profile = profiles[player]
		if profile and getItem(profile, item.id) then
			profile.equippedItemId = item.id
			dirtyProfiles[player] = true
			updateReplicatedValues(player)
		end
	end)
	tool.Unequipped:Connect(function()
		task.defer(function()
			local profile = profiles[player]
			if not profile or profile.equippedItemId ~= item.id then
				return
			end
			local character = player.Character
			for _, child in ipairs(if character then character:GetChildren() else {}) do
				if child:IsA("Tool") and child:GetAttribute("CarWashRushTool") == true then
					return
				end
			end
			profile.equippedItemId = nil
			dirtyProfiles[player] = true
			updateReplicatedValues(player)
		end)
	end)

	tool.Parent = backpack
	toolInstances[player][item.id] = tool
	updateToolInstance(player, item)
	return tool
end

local function rebuildBackpack(player: Player)
	local profile = profiles[player]
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not profile or not backpack then
		return
	end

	for _, container in ipairs({ backpack, player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("CarWashRushTool") == true then
					child:Destroy()
				end
			end
		end
	end

	toolInstances[player] = {}
	for _, item in ipairs(profile.inventory) do
		createToolInstance(player, item)
	end

	local equippedItem = profile.equippedItemId and getItem(profile, profile.equippedItemId)
	if equippedItem and equippedItem.durability > 0 then
		task.delay(0.25, function()
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			local tool = toolInstances[player] and toolInstances[player][equippedItem.id]
			if humanoid and tool and tool.Parent then
				humanoid:EquipTool(tool)
			end
		end)
	end
end

local function savePlayer(player: Player)
	local profile = profiles[player]
	if not profile or not dirtyProfiles[player] or canSaveProfiles[player] ~= true then
		return
	end

	local key = "player_" .. player.UserId
	local success, err = pcall(function()
		dataStore:UpdateAsync(key, function()
			return profile
		end)
	end)

	if success then
		dirtyProfiles[player] = false
	else
		warn(string.format("[Car Wash Rush] Could not save %s: %s", player.Name, tostring(err)))
	end
end

local function scheduleSave(player: Player)
	dirtyProfiles[player] = true
	if saveScheduled[player] then
		return
	end

	saveScheduled[player] = true
	task.delay(SAVE_DEBOUNCE_SECONDS, function()
		saveScheduled[player] = nil
		if player.Parent then
			savePlayer(player)
		end
	end)
end

local function createPlayerValues(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local profileFolder = Instance.new("Folder")
	profileFolder.Name = "CarWashRushProfile"
	profileFolder.Parent = player

	local ragFound = Instance.new("BoolValue")
	ragFound.Name = "RagFound"
	ragFound.Parent = profileFolder

	local equippedItemId = Instance.new("StringValue")
	equippedItemId.Name = "EquippedItemId"
	equippedItemId.Parent = profileFolder

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Parent = profileFolder

	local experience = Instance.new("IntValue")
	experience.Name = "Experience"
	experience.Parent = profileFolder

	local experienceRequired = Instance.new("IntValue")
	experienceRequired.Name = "ExperienceRequired"
	experienceRequired.Parent = profileFolder

	local qualitySpongeCharge = Instance.new("IntValue")
	qualitySpongeCharge.Name = "QualitySpongeCharge"
	qualitySpongeCharge.Parent = profileFolder
end

local function loadPlayer(player: Player)
	createPlayerValues(player)
	toolInstances[player] = {}

	local key = "player_" .. player.UserId
	local success, result = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success then
		profiles[player] = normalizeProfile(result)
		canSaveProfiles[player] = true
	else
		profiles[player] = createDefaultProfile()
		canSaveProfiles[player] = false
		warn(
			string.format(
				"[Car Wash Rush] DataStore unavailable for %s; using session data only: %s",
				player.Name,
				tostring(result)
			)
		)
	end

	player:SetAttribute("CarWashRushProfileLoaded", true)
	updateReplicatedValues(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		rebuildBackpack(player)
	end)

	if player.Character then
		task.defer(rebuildBackpack, player)
	end
end

function PlayerData.start()
	Remotes.get("RequestInventory").OnServerEvent:Connect(function(player)
		updateReplicatedValues(player)
	end)

	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(function(player)
		savePlayer(player)
		profiles[player] = nil
		dirtyProfiles[player] = nil
		canSaveProfiles[player] = nil
		toolInstances[player] = nil
		saveScheduled[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadPlayer, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in pairs(profiles) do
				savePlayer(player)
			end
		end
	end)

	game:BindToClose(function()
		for player in pairs(profiles) do
			savePlayer(player)
		end
	end)
end

function PlayerData.waitUntilLoaded(player: Player): boolean
	if player:GetAttribute("CarWashRushProfileLoaded") == true then
		return true
	end
	local started = os.clock()
	while player.Parent and os.clock() - started < 15 do
		task.wait(0.05)
		if player:GetAttribute("CarWashRushProfileLoaded") == true then
			return true
		end
	end
	return false
end

function PlayerData.getCoins(player: Player): number
	local profile = profiles[player]
	return if profile then profile.coins else 0
end

function PlayerData.getLevel(player: Player): number
	local profile = profiles[player]
	return if profile then profile.level else 0
end

function PlayerData.addCoins(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.coins = math.max(0, profile.coins + math.floor(amount))
	updateReplicatedValues(player)
	scheduleSave(player)
end

function PlayerData.addExperience(player: Player, amount: number): (number, number)
	local profile = profiles[player]
	if not profile then
		return 0, 0
	end

	profile.experience += math.max(0, math.floor(amount))
	local levelsGained = 0
	local required = getExperienceRequired(profile.level)
	while profile.experience >= required do
		profile.experience -= required
		profile.level += 1
		levelsGained += 1
		required = getExperienceRequired(profile.level)
	end

	updateReplicatedValues(player)
	scheduleSave(player)
	return levelsGained, profile.level
end

function PlayerData.addQualitySpongeCharge(player: Player, amount: number): number
	local profile = profiles[player]
	if not profile then
		return 0
	end
	profile.qualitySpongeCharge = math.clamp(
		profile.qualitySpongeCharge + math.max(0, math.floor(amount)),
		0,
		Config.Cleaning.QualitySpongeChargeRequired
	)
	updateReplicatedValues(player)
	scheduleSave(player)
	return profile.qualitySpongeCharge
end

function PlayerData.claimQualitySpongeCharge(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.qualitySpongeCharge < Config.Cleaning.QualitySpongeChargeRequired then
		return false
	end
	profile.qualitySpongeCharge = 0
	updateReplicatedValues(player)
	scheduleSave(player)
	return true
end

function PlayerData.hasFoundRag(player: Player): boolean
	local profile = profiles[player]
	return profile ~= nil and profile.ragFound == true
end

function PlayerData.setRagFound(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.ragFound = true
	updateReplicatedValues(player)
	scheduleSave(player)
end

function PlayerData.grantTool(player: Player, toolId: string, autoEquip: boolean?): string?
	local profile = profiles[player]
	local definition = Catalog.getTool(toolId)
	if not profile or not definition then
		return nil
	end

	local item = {
		id = HttpService:GenerateGUID(false),
		toolId = toolId,
		durability = definition.MaxDurability,
	}
	table.insert(profile.inventory, item)
	createToolInstance(player, item)

	if autoEquip then
		profile.equippedItemId = item.id
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local tool = toolInstances[player] and toolInstances[player][item.id]
		if humanoid and tool then
			humanoid:EquipTool(tool)
		end
	end

	updateReplicatedValues(player)
	scheduleSave(player)
	return item.id
end

function PlayerData.purchaseTool(player: Player, toolId: string): (boolean, string)
	local profile = profiles[player]
	local definition = Catalog.getTool(toolId)
	if not profile or not definition or not definition.Price then
		return false, "That item is not available."
	end
	if profile.coins < definition.Price then
		return false, string.format("You need %d more coins.", definition.Price - profile.coins)
	end

	profile.coins -= definition.Price
	PlayerData.grantTool(player, toolId, true)
	updateReplicatedValues(player)
	scheduleSave(player)
	return true, string.format("Purchased %s.", definition.DisplayName)
end

function PlayerData.getEquippedToolItem(player: Player)
	local profile = profiles[player]
	local character = player.Character
	if not profile or not character then
		return nil, nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("CarWashRushTool") == true then
			local itemId = child:GetAttribute("InventoryItemId")
			if type(itemId) == "string" then
				local item = getItem(profile, itemId)
				if item then
					return item, Catalog.getTool(item.toolId)
				end
			end
		end
	end

	return nil, nil
end

function PlayerData.useDurability(player: Player, itemId: string, amount: number): (boolean, number)
	local profile = profiles[player]
	local item = profile and getItem(profile, itemId)
	if not item or item.durability <= 0 then
		return false, 0
	end

	item.durability = math.max(0, item.durability - amount)
	updateToolInstance(player, item)
	if item.durability == 0 then
		profile.equippedItemId = nil
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end
	updateReplicatedValues(player)
	scheduleSave(player)
	return true, item.durability
end

function PlayerData.getSnapshot(player: Player)
	local profile = profiles[player]
	return if profile then makeSnapshot(profile) else nil
end

return PlayerData
