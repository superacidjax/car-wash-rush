local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RateLimiter =
	require(script.Parent.Parent:WaitForChild("Infrastructure"):WaitForChild("RateLimiter"))

local Remotes = {}

local REMOTE_NAMES = {
	"CleaningClick",
	"CleaningEnded",
	"CleaningProgress",
	"CleaningStarted",
	"CleaningTrace",
	"CooperativeEventAction",
	"CooperativeEventMinigame",
	"CooperativeEventState",
	"DemandStateUpdated",
	"DevCommand",
	"ClaimQualitySpongeAbility",
	"EquipInventoryItem",
	"ForceCooperativeEvent",
	"InventoryUpdated",
	"Notify",
	"OpenShopDialogue",
	"PurchaseTool",
	"RequestCleanSpot",
	"RequestCooperativeEventState",
	"RequestInventory",
	"RequestDemandState",
	"RequestTeleport",
	"SellInventoryItem",
	"SetAssistanceMode",
	"SprintChanged",
}

local folder: Folder? = nil
local limiter = RateLimiter.new()

function Remotes.start(folderName: string)
	local existing = ReplicatedStorage:FindFirstChild(folderName)
	if existing then
		existing:Destroy()
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = folderName
	newFolder.Parent = ReplicatedStorage
	folder = newFolder

	for _, remoteName in ipairs(REMOTE_NAMES) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = newFolder
	end

	Players.PlayerRemoving:Connect(function(player)
		limiter:forget(player)
	end)
end

function Remotes.get(remoteName: string): RemoteEvent
	assert(folder, "Remotes.start() must run before Remotes.get().")
	return folder:WaitForChild(remoteName) :: RemoteEvent
end

function Remotes.connect(remoteName: string, callback: (Player, ...any) -> ()): RBXScriptConnection
	local limits = Config.RemoteLimits[remoteName]
	assert(limits, string.format("No server rate limit configured for %s", remoteName))
	return Remotes.get(remoteName).OnServerEvent:Connect(function(player, ...)
		if limiter:allow(player, remoteName, limits.Rate, limits.Burst) then
			callback(player, ...)
		end
	end)
end

return Remotes
