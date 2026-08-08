--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local ExperienceRules = require(Shared:WaitForChild("Domain"):WaitForChild("ExperienceRules"))
local InventoryRules = require(Shared.Domain:WaitForChild("InventoryRules"))
local ProfileSchema = require(Shared.Domain:WaitForChild("ProfileSchema"))
local ProfileStore =
	require(script.Parent.Parent:WaitForChild("Infrastructure"):WaitForChild("ProfileStore"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local PlayerData = {}

type RuntimeState = {
	profile: any,
	key: string,
	revision: number,
	dirty: boolean,
	canSave: boolean,
	saving: boolean,
	saveScheduled: boolean,
}

local dataStore = DataStoreService:GetDataStore(Config.DataStoreName)
local sessionId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
local repository = ProfileStore.new({
	store = dataStore,
	sessionId = sessionId,
	normalize = function(raw)
		return ProfileSchema.normalize(raw, function()
			return HttpService:GenerateGUID(false)
		end)
	end,
	leaseSeconds = Config.Persistence.SessionLeaseSeconds,
	retryCount = Config.Persistence.RetryCount,
})

local states: { [Player]: RuntimeState } = {}
local toolInstances: { [Player]: { [string]: Tool } } = {}

local function getItem(profile: any, itemId: string): any?
	for _, item in profile.inventory do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

local function getEquippedItem(profile: any): any?
	return if profile.equippedItemId then getItem(profile, profile.equippedItemId) else nil
end

local function getExperienceRequired(level: number): number
	return ExperienceRules.requirementForLevel(
		level,
		Config.Experience.FirstLevelRequirement,
		Config.Experience.RequirementMultiplier
	)
end

local function currentQualityCharge(profile: any): number
	local equippedItem = getEquippedItem(profile)
	if equippedItem and equippedItem.toolId == "tool_quality_sponge" then
		return equippedItem.qualityCharge or 0
	end
	return 0
end

local function makeSnapshot(profile: any): any
	local hotbarLookup: { [string]: boolean } = {}
	for _, itemId in profile.hotbarItemIds do
		hotbarLookup[itemId] = true
	end

	local inventory = {}
	for _, item in profile.inventory do
		local definition = Catalog.getTool(item.toolId)
		if definition then
			table.insert(inventory, {
				id = item.id,
				toolId = item.toolId,
				displayName = definition.DisplayName,
				durability = item.durability,
				maxDurability = definition.MaxDurability,
				resaleValue = InventoryRules.resaleValue(
					definition.BaseResaleValue,
					item.durability,
					definition.MaxDurability
				),
				qualityCharge = item.qualityCharge or 0,
				inHotbar = hotbarLookup[item.id] == true,
			})
		end
	end

	return {
		coins = profile.coins,
		level = profile.level,
		experience = profile.experience,
		experienceRequired = getExperienceRequired(profile.level),
		qualitySpongeCharge = currentQualityCharge(profile),
		ragFound = profile.ragFound,
		equippedItemId = profile.equippedItemId,
		hotbarItemIds = table.clone(profile.hotbarItemIds),
		inventory = inventory,
	}
end

local function updateReplicatedValues(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local profile = state.profile

	local leaderstats = player:FindFirstChild("leaderstats")
	local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
	if coinsValue and coinsValue:IsA("IntValue") then
		coinsValue.Value = profile.coins
	end

	local profileFolder = player:FindFirstChild("CarWashRushProfile")
	if profileFolder then
		local ragFoundValue = profileFolder:FindFirstChild("RagFound")
		local equippedValue = profileFolder:FindFirstChild("EquippedItemId")
		local levelValue = profileFolder:FindFirstChild("Level")
		local experienceValue = profileFolder:FindFirstChild("Experience")
		local experienceRequiredValue = profileFolder:FindFirstChild("ExperienceRequired")
		local qualityChargeValue = profileFolder:FindFirstChild("QualitySpongeCharge")
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
		if qualityChargeValue and qualityChargeValue:IsA("IntValue") then
			qualityChargeValue.Value = currentQualityCharge(profile)
		end
	end

	Remotes.get("InventoryUpdated"):FireClient(player, makeSnapshot(profile))
end

local function savePlayer(player: Player): boolean
	local state = states[player]
	if not state or not state.dirty or not state.canSave then
		return true
	end
	if state.saving then
		return false
	end

	state.saving = true
	local revision = state.revision
	local snapshot = ProfileStore.clone(state.profile)
	local success, saveError = repository:save(state.key, snapshot)
	state.saving = false

	if success then
		if state.revision == revision then
			state.dirty = false
		end
	else
		warn(
			string.format("[Car Wash Rush] Could not save %s: %s", player.Name, tostring(saveError))
		)
		if saveError == "profile session ownership was lost" then
			state.canSave = false
		end
	end
	return success
end

local function scheduleSave(player: Player)
	local state = states[player]
	if not state or state.saveScheduled then
		return
	end
	state.saveScheduled = true
	task.delay(Config.Persistence.SaveDebounceSeconds, function()
		if states[player] ~= state then
			return
		end
		state.saveScheduled = false
		savePlayer(player)
		if state.dirty and state.canSave then
			scheduleSave(player)
		end
	end)
end

local function markChanged(player: Player, replicate: boolean?)
	local state = states[player]
	if not state then
		return
	end
	state.revision += 1
	state.dirty = true
	if replicate ~= false then
		updateReplicatedValues(player)
	end
	scheduleSave(player)
end

local function updateToolInstance(player: Player, item: any)
	local playerTools = toolInstances[player]
	local tool = playerTools and playerTools[item.id]
	if not tool or not tool.Parent then
		return
	end
	local definition = Catalog.getTool(item.toolId)
	if not definition then
		return
	end

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
	tool:SetAttribute("QualityCharge", item.qualityCharge or 0)
end

local function createToolInstance(player: Player, item: any): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	local definition = Catalog.getTool(item.toolId)
	if not backpack or not definition then
		return nil
	end

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
		local state = states[player]
		if
			state
			and getItem(state.profile, item.id)
			and state.profile.equippedItemId ~= item.id
		then
			state.profile.equippedItemId = item.id
			markChanged(player)
		end
	end)
	tool.Unequipped:Connect(function()
		task.defer(function()
			local state = states[player]
			if not state or state.profile.equippedItemId ~= item.id then
				return
			end
			local character = player.Character
			local children: { Instance } = if character then character:GetChildren() else {}
			for _, child in children do
				if child:IsA("Tool") and child:GetAttribute("CarWashRushTool") == true then
					return
				end
			end
			state.profile.equippedItemId = nil
			markChanged(player)
		end)
	end)

	tool.Parent = backpack
	toolInstances[player][item.id] = tool
	updateToolInstance(player, item)
	return tool
end

local function isInHotbar(profile: any, itemId: string): boolean
	return table.find(profile.hotbarItemIds, itemId) ~= nil
end

local function moveToHotbar(profile: any, itemId: string)
	local existingIndex = table.find(profile.hotbarItemIds, itemId)
	if existingIndex then
		table.remove(profile.hotbarItemIds, existingIndex)
	end
	table.insert(profile.hotbarItemIds, 1, itemId)
	while #profile.hotbarItemIds > Config.Inventory.HotbarCapacity do
		table.remove(profile.hotbarItemIds)
	end
end

local function rebuildBackpack(player: Player)
	local state = states[player]
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not state or not backpack then
		return
	end

	local containers: { Instance? } = { backpack, player.Character }
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("CarWashRushTool") == true then
					child:Destroy()
				end
			end
		end
	end

	toolInstances[player] = {}
	for _, itemId in state.profile.hotbarItemIds do
		local item = getItem(state.profile, itemId)
		if item then
			createToolInstance(player, item)
		end
	end

	local equippedItem = getEquippedItem(state.profile)
	if
		equippedItem
		and equippedItem.durability > 0
		and isInHotbar(state.profile, equippedItem.id)
	then
		task.delay(0.25, function()
			if states[player] ~= state then
				return
			end
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			local tool = toolInstances[player] and toolInstances[player][equippedItem.id]
			if humanoid and tool and tool.Parent then
				humanoid:EquipTool(tool)
			end
		end)
	end
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

	for _, definition in
		{
			{ className = "BoolValue", name = "RagFound" },
			{ className = "StringValue", name = "EquippedItemId" },
			{ className = "IntValue", name = "Level" },
			{ className = "IntValue", name = "Experience" },
			{ className = "IntValue", name = "ExperienceRequired" },
			{ className = "IntValue", name = "QualitySpongeCharge" },
		}
	do
		local value = Instance.new(definition.className)
		value.Name = definition.name
		value.Parent = profileFolder
	end
end

local function flushAndRelease(player: Player, state: RuntimeState)
	local deadline = os.clock() + Config.Persistence.ShutdownTimeoutSeconds
	while state.saving and os.clock() < deadline do
		task.wait(0.05)
	end
	if state.dirty and state.canSave then
		savePlayer(player)
	end
	if state.canSave then
		local released, releaseError = repository:release(state.key)
		if not released then
			warn(
				string.format(
					"[Car Wash Rush] Could not release %s: %s",
					player.Name,
					tostring(releaseError)
				)
			)
		end
	end
end

local function loadPlayer(player: Player)
	createPlayerValues(player)
	local key = "player_" .. player.UserId
	local profile, loadError = repository:acquire(key)

	if player.Parent ~= Players then
		if profile then
			repository:release(key)
		end
		return
	end

	local canSave = profile ~= nil
	if not profile then
		if RunService:IsStudio() then
			profile = ProfileSchema.default()
			player:SetAttribute("CarWashRushSessionOnly", true)
			warn(
				string.format(
					"[Car Wash Rush] DataStore unavailable for %s; Studio session will not save: %s",
					player.Name,
					tostring(loadError)
				)
			)
		else
			player:Kick("Your saved game is already open or could not be loaded. Please try again.")
			return
		end
	end

	states[player] = {
		profile = profile,
		key = key,
		revision = 0,
		dirty = false,
		canSave = canSave,
		saving = false,
		saveScheduled = false,
	}
	toolInstances[player] = {}
	player:SetAttribute("CarWashRushProfileLoaded", true)
	updateReplicatedValues(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		if states[player] then
			rebuildBackpack(player)
		end
	end)
	if player.Character then
		task.defer(rebuildBackpack, player)
	end
end

local function applyExperience(profile: any, amount: number): (number, number)
	local level, experience, levelsGained = ExperienceRules.applyExperience(
		profile.level,
		profile.experience,
		math.max(0, math.floor(amount)),
		Config.Experience.FirstLevelRequirement,
		Config.Experience.RequirementMultiplier
	)
	profile.level = level
	profile.experience = experience
	return levelsGained, level
end

local function newItem(toolId: string): any?
	local definition = Catalog.getTool(toolId)
	if not definition then
		return nil
	end
	return {
		id = HttpService:GenerateGUID(false),
		toolId = toolId,
		durability = definition.MaxDurability,
		qualityCharge = if toolId == "tool_quality_sponge" then 0 else nil,
	}
end

function PlayerData.start()
	Remotes.connect("RequestInventory", function(player)
		updateReplicatedValues(player)
	end)
	Remotes.connect("EquipInventoryItem", function(player, itemId)
		if type(itemId) == "string" then
			local _, message = PlayerData.equipInventoryItem(player, itemId)
			Remotes.get("Notify"):FireClient(player, message)
		end
	end)
	Remotes.connect("SellInventoryItem", function(player, itemId)
		if type(itemId) == "string" then
			local _, message = PlayerData.sellInventoryItem(player, itemId)
			Remotes.get("Notify"):FireClient(player, message)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadPlayer, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local state = states[player]
		if state then
			flushAndRelease(player, state)
		end
		if states[player] == state then
			states[player] = nil
			toolInstances[player] = nil
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.Persistence.AutosaveSeconds)
			for player in states do
				task.spawn(savePlayer, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, state in states do
			pending += 1
			task.spawn(function()
				flushAndRelease(player, state)
				pending -= 1
			end)
		end
		local deadline = os.clock() + Config.Persistence.ShutdownTimeoutSeconds
		while pending > 0 and os.clock() < deadline do
			task.wait(0.05)
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
	local state = states[player]
	return if state then state.profile.coins else 0
end

function PlayerData.getLevel(player: Player): number
	local state = states[player]
	return if state then state.profile.level else 0
end

function PlayerData.addCoins(player: Player, amount: number)
	local state = states[player]
	if not state then
		return
	end
	state.profile.coins = math.max(0, state.profile.coins + math.floor(amount))
	markChanged(player)
end

function PlayerData.addExperience(player: Player, amount: number): (number, number)
	local state = states[player]
	if not state then
		return 0, 0
	end
	local levelsGained, level = applyExperience(state.profile, amount)
	markChanged(player)
	return levelsGained, level
end

function PlayerData.hasFoundRag(player: Player): boolean
	local state = states[player]
	return state ~= nil and state.profile.ragFound == true
end

function PlayerData.setRagFound(player: Player)
	local state = states[player]
	if state and not state.profile.ragFound then
		state.profile.ragFound = true
		markChanged(player)
	end
end

function PlayerData.grantTool(player: Player, toolId: string, autoEquip: boolean?): string?
	local state = states[player]
	local item = newItem(toolId)
	if not state or not item then
		return nil
	end

	table.insert(state.profile.inventory, item)
	moveToHotbar(state.profile, item.id)
	rebuildBackpack(player)
	if autoEquip then
		state.profile.equippedItemId = item.id
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local tool = toolInstances[player] and toolInstances[player][item.id]
		if humanoid and tool then
			humanoid:EquipTool(tool)
		end
	end
	markChanged(player)
	return item.id
end

function PlayerData.grantFoundRag(player: Player): boolean
	local state = states[player]
	local item = newItem("tool_old_rag")
	if not state or not item or state.profile.ragFound then
		return false
	end
	state.profile.ragFound = true
	table.insert(state.profile.inventory, item)
	moveToHotbar(state.profile, item.id)
	state.profile.equippedItemId = item.id
	rebuildBackpack(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local tool = toolInstances[player] and toolInstances[player][item.id]
	if humanoid and tool then
		humanoid:EquipTool(tool)
	end
	markChanged(player)
	return true
end

function PlayerData.purchaseTool(player: Player, toolId: string): (boolean, string)
	local state = states[player]
	local definition = Catalog.getTool(toolId)
	local item = newItem(toolId)
	if not state or not definition or not definition.Price or not item then
		return false, "That item is not available."
	end
	if state.profile.coins < definition.Price then
		return false,
			string.format("You need %d more coins.", definition.Price - state.profile.coins)
	end

	state.profile.coins -= definition.Price
	table.insert(state.profile.inventory, item)
	moveToHotbar(state.profile, item.id)
	state.profile.equippedItemId = item.id
	rebuildBackpack(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local tool = toolInstances[player] and toolInstances[player][item.id]
	if humanoid and tool then
		humanoid:EquipTool(tool)
	end
	markChanged(player)
	return true, string.format("Purchased %s.", definition.DisplayName)
end

function PlayerData.equipInventoryItem(player: Player, itemId: string): (boolean, string)
	local state = states[player]
	local item = state and getItem(state.profile, itemId)
	if not state or not item or item.durability <= 0 then
		return false, "That tool cannot be equipped."
	end
	moveToHotbar(state.profile, itemId)
	state.profile.equippedItemId = itemId
	rebuildBackpack(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local tool = toolInstances[player] and toolInstances[player][itemId]
	if humanoid and tool then
		humanoid:EquipTool(tool)
	end
	markChanged(player)
	return true, "Tool equipped."
end

function PlayerData.sellInventoryItem(player: Player, itemId: string): (boolean, string)
	local state = states[player]
	local item = state and getItem(state.profile, itemId)
	local definition = item and Catalog.getTool(item.toolId)
	if not state or not item or not definition then
		return false, "That tool is not available."
	end
	local value = InventoryRules.resaleValue(
		definition.BaseResaleValue,
		item.durability,
		definition.MaxDurability
	)
	local inventoryIndex = table.find(state.profile.inventory, item)
	if inventoryIndex then
		table.remove(state.profile.inventory, inventoryIndex)
	end
	local hotbarIndex = table.find(state.profile.hotbarItemIds, itemId)
	if hotbarIndex then
		table.remove(state.profile.hotbarItemIds, hotbarIndex)
	end
	if state.profile.equippedItemId == itemId then
		state.profile.equippedItemId = nil
	end
	state.profile.coins += value
	rebuildBackpack(player)
	markChanged(player)
	return true, string.format("Sold %s for %d coins.", definition.DisplayName, value)
end

function PlayerData.getEquippedToolItem(player: Player): (any?, any?)
	local state = states[player]
	local character = player.Character
	if not state or not character then
		return nil, nil
	end

	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("CarWashRushTool") == true then
			local itemId = child:GetAttribute("InventoryItemId")
			if type(itemId) == "string" then
				local item = getItem(state.profile, itemId)
				if item then
					return item, Catalog.getTool(item.toolId)
				end
			end
		end
	end
	return nil, nil
end

function PlayerData.useDurability(player: Player, itemId: string, amount: number): (boolean, number)
	local state = states[player]
	local item = state and getItem(state.profile, itemId)
	if not state or not item or item.durability <= 0 then
		return false, 0
	end
	item.durability = InventoryRules.durabilityAfterUse(item.durability, amount)
	updateToolInstance(player, item)
	if item.durability == 0 then
		state.profile.equippedItemId = nil
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end
	markChanged(player)
	return true, item.durability
end

function PlayerData.completeCleaningSpot(
	player: Player,
	itemId: string,
	coinReward: number,
	experienceReward: number,
	qualityCharge: number
): (boolean, number, number, number, number)
	local state = states[player]
	local item = state and getItem(state.profile, itemId)
	if not state or not item or item.durability <= 0 then
		return false, 0, 0, 0, 0
	end

	item.durability = InventoryRules.durabilityAfterUse(item.durability, 1)
	state.profile.coins += math.max(0, math.floor(coinReward))
	local levelsGained, level = applyExperience(state.profile, experienceReward)
	if item.toolId == "tool_quality_sponge" then
		item.qualityCharge = InventoryRules.addQualityCharge(
			item.qualityCharge or 0,
			qualityCharge,
			Config.Cleaning.QualitySpongeChargeRequired
		)
	end
	updateToolInstance(player, item)
	if item.durability == 0 then
		state.profile.equippedItemId = nil
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end
	markChanged(player)
	return true, item.durability, levelsGained, level, item.qualityCharge or 0
end

function PlayerData.completeVehicle(
	player: Player,
	coinReward: number,
	experienceReward: number
): (number, number)
	local state = states[player]
	if not state then
		return 0, 0
	end
	state.profile.coins += math.max(0, math.floor(coinReward))
	local levelsGained, level = applyExperience(state.profile, experienceReward)
	markChanged(player)
	return levelsGained, level
end

function PlayerData.addQualitySpongeCharge(player: Player, amount: number): number
	local state = states[player]
	local item = state and getEquippedItem(state.profile)
	if not state or not item or item.toolId ~= "tool_quality_sponge" then
		return 0
	end
	item.qualityCharge = InventoryRules.addQualityCharge(
		item.qualityCharge or 0,
		amount,
		Config.Cleaning.QualitySpongeChargeRequired
	)
	updateToolInstance(player, item)
	markChanged(player)
	return item.qualityCharge
end

function PlayerData.claimQualitySpongeAbility(player: Player, reward: number): boolean
	local state = states[player]
	local item = state and getEquippedItem(state.profile)
	if
		not state
		or not item
		or item.toolId ~= "tool_quality_sponge"
		or not InventoryRules.canClaimQualityCharge(
			item.qualityCharge or 0,
			Config.Cleaning.QualitySpongeChargeRequired
		)
	then
		return false
	end
	item.qualityCharge = 0
	state.profile.coins += math.max(0, math.floor(reward))
	updateToolInstance(player, item)
	markChanged(player)
	return true
end

function PlayerData.claimQualitySpongeCharge(player: Player): boolean
	return PlayerData.claimQualitySpongeAbility(player, 0)
end

function PlayerData.getSnapshot(player: Player): any?
	local state = states[player]
	return if state then makeSnapshot(state.profile) else nil
end

return PlayerData
