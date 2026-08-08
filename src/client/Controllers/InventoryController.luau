--!strict

local InventoryController = {}
InventoryController.__index = InventoryController

type Remotes = {
	equip: RemoteEvent,
}

export type InventoryController = any

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function textButton(parent: Instance, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(250, 248, 235)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	addCorner(button, 5)
	return button
end

function InventoryController.new(parent: ScreenGui, remotes: Remotes): InventoryController
	local openButton = textButton(parent, "INVENTORY", Color3.fromRGB(48, 85, 106))
	openButton.Name = "InventoryButton"
	openButton.Position = UDim2.fromOffset(18, 414)
	openButton.Size = UDim2.fromOffset(260, 42)
	openButton.ZIndex = 6

	local panel = Instance.new("Frame") :: Frame
	panel.Name = "InventoryPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.52)
	panel.Size = UDim2.fromScale(0.86, 0.76)
	panel.BackgroundColor3 = Color3.fromRGB(24, 41, 50)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 40
	panel.Parent = parent
	addCorner(panel, 6)

	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(320, 360)
	constraint.MaxSize = Vector2.new(720, 620)
	constraint.Parent = panel

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(18, 12)
	title.Size = UDim2.new(1, -76, 0, 38)
	title.BackgroundTransparency = 1
	title.Text = "TOOL INVENTORY"
	title.TextColor3 = Color3.fromRGB(249, 244, 220)
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 41
	title.Parent = panel

	local closeButton = textButton(panel, "X", Color3.fromRGB(147, 61, 57))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -12, 0, 12)
	closeButton.Size = UDim2.fromOffset(42, 38)
	closeButton.ZIndex = 42

	local list = Instance.new("ScrollingFrame") :: ScrollingFrame
	list.Position = UDim2.fromOffset(14, 62)
	list.Size = UDim2.new(1, -28, 1, -76)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ZIndex = 41
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = list

	local self: InventoryController = setmetatable({
		panel = panel,
		list = list,
		remotes = remotes,
		snapshot = nil :: any,
	}, InventoryController)
	openButton.MouseButton1Click:Connect(function()
		self:setVisible(not panel.Visible)
	end)
	closeButton.MouseButton1Click:Connect(function()
		self:setVisible(false)
	end)
	return self
end

function InventoryController:_render()
	for _, child in self.list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local snapshot = self.snapshot
	if not snapshot then
		return
	end

	for _, item in snapshot.inventory do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 76)
		row.BackgroundColor3 = if item.id == snapshot.equippedItemId
			then Color3.fromRGB(42, 91, 72)
			else Color3.fromRGB(42, 63, 72)
		row.BorderSizePixel = 0
		row.ZIndex = 42
		row.Parent = self.list
		addCorner(row, 5)

		local details = Instance.new("TextLabel")
		details.Position = UDim2.fromOffset(12, 8)
		details.Size = UDim2.new(1, -112, 1, -16)
		details.BackgroundTransparency = 1
		details.Text = string.format(
			"%s%s\nDurability %d/%d  |  Resale %d",
			item.displayName,
			if item.inHotbar then "  [HOTBAR]" else "",
			item.durability,
			item.maxDurability,
			item.resaleValue
		)
		details.TextColor3 = Color3.fromRGB(244, 242, 225)
		details.TextSize = 14
		details.TextWrapped = true
		details.Font = Enum.Font.GothamMedium
		details.TextXAlignment = Enum.TextXAlignment.Left
		details.TextYAlignment = Enum.TextYAlignment.Center
		details.ZIndex = 43
		details.Parent = row

		local equip = textButton(row, "EQUIP", Color3.fromRGB(43, 116, 153))
		equip.AnchorPoint = Vector2.new(1, 0.5)
		equip.Position = UDim2.new(1, -10, 0.5, 0)
		equip.Size = UDim2.fromOffset(82, 40)
		equip.ZIndex = 43
		equip.MouseButton1Click:Connect(function()
			self.remotes.equip:FireServer(item.id)
		end)
	end
end

function InventoryController:setSnapshot(snapshot: any)
	self.snapshot = snapshot
	if self.panel.Visible then
		self:_render()
	end
end

function InventoryController:setVisible(visible: boolean)
	self.panel.Visible = visible
	if visible then
		self:_render()
	end
end

function InventoryController:isVisible(): boolean
	return self.panel.Visible
end

return InventoryController
