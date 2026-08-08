--!strict

local Catalog = require(script.Parent.Parent.Catalog)

local ProfileSchema = {}

ProfileSchema.VERSION = 5

export type InventoryItem = {
	id: string,
	toolId: string,
	durability: number,
	qualityCharge: number?,
}

export type Profile = {
	version: number,
	coins: number,
	level: number,
	experience: number,
	ragFound: boolean,
	ladderPlaced: boolean,
	equippedItemId: string?,
	hotbarItemIds: { string },
	inventory: { InventoryItem },
}

local function nonNegativeInteger(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value then
		return fallback
	end
	return math.max(0, math.floor(value))
end

local function validItem(rawItem: any, idFactory: () -> string): InventoryItem?
	if type(rawItem) ~= "table" or type(rawItem.toolId) ~= "string" then
		return nil
	end
	local definition = Catalog.getTool(rawItem.toolId)
	if not definition then
		return nil
	end
	local id = if type(rawItem.id) == "string" and rawItem.id ~= "" then rawItem.id else idFactory()
	local durability = math.clamp(
		nonNegativeInteger(rawItem.durability, definition.MaxDurability),
		0,
		definition.MaxDurability
	)
	if durability <= 0 then
		return nil
	end

	local item: InventoryItem = {
		id = id,
		toolId = rawItem.toolId,
		durability = durability,
	}
	if rawItem.toolId == "tool_quality_sponge" then
		item.qualityCharge = math.clamp(nonNegativeInteger(rawItem.qualityCharge, 0), 0, 10)
	end
	return item
end

function ProfileSchema.default(): Profile
	return {
		version = ProfileSchema.VERSION,
		coins = 0,
		level = 0,
		experience = 0,
		ragFound = false,
		ladderPlaced = false,
		equippedItemId = nil,
		hotbarItemIds = {},
		inventory = {},
	}
end

function ProfileSchema.normalize(raw: any, idFactory: (() -> string)?): Profile
	local makeId = idFactory
		or function(): string
			return string.format("migrated-%d", math.random(1, 1_000_000_000))
		end
	local profile = ProfileSchema.default()
	if type(raw) ~= "table" then
		return profile
	end

	profile.coins = nonNegativeInteger(raw.coins, 0)
	profile.level = nonNegativeInteger(raw.level, 0)
	profile.experience = nonNegativeInteger(raw.experience, 0)
	profile.ragFound = raw.ragFound == true
	profile.ladderPlaced = raw.ladderPlaced == true

	local seenIds: { [string]: boolean } = {}
	if type(raw.inventory) == "table" then
		for _, rawItem in raw.inventory do
			local item = validItem(rawItem, makeId)
			if item then
				while seenIds[item.id] do
					item.id = makeId()
				end
				seenIds[item.id] = true
				table.insert(profile.inventory, item)
			end
		end
	end

	local legacyCharge = nonNegativeInteger(raw.qualitySpongeCharge, 0)
	if legacyCharge > 0 then
		local migrationTarget: InventoryItem? = nil
		if type(raw.equippedItemId) == "string" then
			for _, item in profile.inventory do
				if item.id == raw.equippedItemId and item.toolId == "tool_quality_sponge" then
					migrationTarget = item
					break
				end
			end
		end
		if not migrationTarget then
			for _, item in profile.inventory do
				if item.toolId == "tool_quality_sponge" then
					migrationTarget = item
					break
				end
			end
		end
		if migrationTarget then
			migrationTarget.qualityCharge = math.clamp(legacyCharge, 0, 10)
		end
	end

	if type(raw.equippedItemId) == "string" and seenIds[raw.equippedItemId] then
		profile.equippedItemId = raw.equippedItemId
	end

	local hotbarSeen: { [string]: boolean } = {}
	if type(raw.hotbarItemIds) == "table" then
		for _, itemId in raw.hotbarItemIds do
			if type(itemId) == "string" and seenIds[itemId] and not hotbarSeen[itemId] then
				hotbarSeen[itemId] = true
				table.insert(profile.hotbarItemIds, itemId)
				if #profile.hotbarItemIds >= 8 then
					break
				end
			end
		end
	end

	if #profile.hotbarItemIds == 0 then
		for index, item in profile.inventory do
			if index > 8 then
				break
			end
			hotbarSeen[item.id] = true
			table.insert(profile.hotbarItemIds, item.id)
		end
	end
	if profile.equippedItemId and not hotbarSeen[profile.equippedItemId] then
		table.insert(profile.hotbarItemIds, 1, profile.equippedItemId)
		if #profile.hotbarItemIds > 8 then
			table.remove(profile.hotbarItemIds)
		end
	end

	return profile
end

return ProfileSchema
