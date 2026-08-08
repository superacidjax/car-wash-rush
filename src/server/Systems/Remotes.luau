local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local REMOTE_NAMES = {
	"CleaningClick",
	"CleaningEnded",
	"CleaningProgress",
	"CleaningStarted",
	"ClaimQualitySpongeAbility",
	"InventoryUpdated",
	"Notify",
	"OpenShopDialogue",
	"PurchaseTool",
	"RequestCleanSpot",
	"RequestInventory",
	"RequestTeleport",
	"SprintChanged",
}

local folder: Folder? = nil

function Remotes.start(folderName: string)
	local existing = ReplicatedStorage:FindFirstChild(folderName)
	if existing then
		existing:Destroy()
	end

	folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = ReplicatedStorage

	for _, remoteName in ipairs(REMOTE_NAMES) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
	end
end

function Remotes.get(remoteName: string): RemoteEvent
	assert(folder, "Remotes.start() must run before Remotes.get().")
	return folder:WaitForChild(remoteName) :: RemoteEvent
end

return Remotes
