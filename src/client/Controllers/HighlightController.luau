--!strict

local Workspace = game:GetService("Workspace")

local HighlightController = {}
HighlightController.__index = HighlightController

export type HighlightController = typeof(setmetatable(
	{} :: {
		player: Player,
		folderName: string,
		held: boolean,
		highlights: { [Highlight]: boolean },
		folderConnections: { RBXScriptConnection },
		workspaceConnection: RBXScriptConnection?,
	},
	HighlightController
))

function HighlightController.new(player: Player, folderName: string): HighlightController
	local self = setmetatable({
		player = player,
		folderName = folderName,
		held = false,
		highlights = {},
		folderConnections = {},
		workspaceConnection = nil,
	}, HighlightController)

	local function attachIfCarsFolder(child: Instance)
		if child.Name == folderName then
			self:_attachFolder(child)
		end
	end
	self.workspaceConnection = Workspace.ChildAdded:Connect(attachIfCarsFolder)
	local existing = Workspace:FindFirstChild(folderName)
	if existing then
		self:_attachFolder(existing)
	end
	return self
end

function HighlightController:_track(instance: Instance)
	if instance:IsA("Highlight") and instance.Name == "DirtHighlight" then
		self.highlights[instance] = true
		self:_updateOne(instance)
	end
end

function HighlightController:_updateOne(highlight: Highlight)
	local dirt = highlight.Parent
	highlight.Enabled = self.held
		and dirt ~= nil
		and dirt:GetAttribute("OwnerUserId") == self.player.UserId
end

function HighlightController:_attachFolder(folder: Instance)
	for _, connection in self.folderConnections do
		connection:Disconnect()
	end
	table.clear(self.folderConnections)
	table.clear(self.highlights)
	for _, descendant in folder:GetDescendants() do
		self:_track(descendant)
	end
	table.insert(
		self.folderConnections,
		folder.DescendantAdded:Connect(function(descendant)
			self:_track(descendant)
		end)
	)
	table.insert(
		self.folderConnections,
		folder.DescendantRemoving:Connect(function(descendant)
			if descendant:IsA("Highlight") then
				self.highlights[descendant] = nil
			end
		end)
	)
end

function HighlightController:setHeld(held: boolean)
	self.held = held
	for highlight in self.highlights do
		if highlight.Parent then
			self:_updateOne(highlight)
		else
			self.highlights[highlight] = nil
		end
	end
end

function HighlightController:destroy()
	if self.workspaceConnection then
		self.workspaceConnection:Disconnect()
	end
	for _, connection in self.folderConnections do
		connection:Disconnect()
	end
	table.clear(self.folderConnections)
	table.clear(self.highlights)
end

return HighlightController
