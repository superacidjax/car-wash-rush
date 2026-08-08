local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Controllers = script.Parent:WaitForChild("Controllers")
local HighlightController = require(Controllers:WaitForChild("HighlightController"))
local InventoryController = require(Controllers:WaitForChild("InventoryController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild(Config.RemotesFolderName)

local function remote(name: string): RemoteEvent
	return remotes:WaitForChild(name) :: RemoteEvent
end

local cleaningClick = remote("CleaningClick")
local cleaningEnded = remote("CleaningEnded")
local cleaningProgress = remote("CleaningProgress")
local cleaningStarted = remote("CleaningStarted")
local claimQualitySpongeAbility = remote("ClaimQualitySpongeAbility")
local equipInventoryItem = remote("EquipInventoryItem")
local inventoryUpdated = remote("InventoryUpdated")
local notifyRemote = remote("Notify")
local openShopDialogue = remote("OpenShopDialogue")
local purchaseTool = remote("PurchaseTool")
local requestCleanSpot = remote("RequestCleanSpot")
local requestInventory = remote("RequestInventory")
local requestTeleport = remote("RequestTeleport")
local sellInventoryItem = remote("SellInventoryItem")
local sprintChanged = remote("SprintChanged")

local COLORS = {
	Ink = Color3.fromRGB(18, 28, 36),
	Panel = Color3.fromRGB(27, 47, 57),
	PanelLight = Color3.fromRGB(42, 69, 78),
	Gold = Color3.fromRGB(244, 198, 71),
	Cream = Color3.fromRGB(249, 244, 220),
	Blue = Color3.fromRGB(50, 186, 224),
	Green = Color3.fromRGB(87, 205, 125),
	Red = Color3.fromRGB(224, 83, 74),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarWashRushUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local highlightController = HighlightController.new(player, Config.World.PrototypeCarsFolderName)
local inventoryController = InventoryController.new(screenGui, {
	equip = equipInventoryItem,
	sell = sellInventoryItem,
})

local function addCorner(parent: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
end

local function addStroke(parent: GuiObject, color: Color3, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.Parent = parent
end

local notification = Instance.new("TextLabel")
notification.Name = "Notification"
notification.AnchorPoint = Vector2.new(0.5, 0)
notification.Position = UDim2.new(0.5, 0, 0, 112)
notification.Size = UDim2.new(0.7, 0, 0, 54)
notification.BackgroundColor3 = COLORS.Ink
notification.BackgroundTransparency = 0.08
notification.BorderSizePixel = 0
notification.Text = ""
notification.TextColor3 = COLORS.Cream
notification.TextSize = 20
notification.TextWrapped = true
notification.Font = Enum.Font.GothamBold
notification.Visible = false
notification.ZIndex = 30
notification.Parent = screenGui
addCorner(notification)
addStroke(notification, COLORS.Gold, 2)

local notificationConstraint = Instance.new("UISizeConstraint")
notificationConstraint.MinSize = Vector2.new(280, 54)
notificationConstraint.MaxSize = Vector2.new(720, 80)
notificationConstraint.Parent = notification

local notificationToken = 0
local function showNotification(message: string, duration: number?)
	notificationToken += 1
	local token = notificationToken
	notification.Text = message
	notification.Visible = true
	task.delay(duration or 3, function()
		if notificationToken == token then
			notification.Visible = false
		end
	end)
end

local navigationBar = Instance.new("Frame")
navigationBar.Name = "LocationNavigation"
navigationBar.AnchorPoint = Vector2.new(0.5, 0)
navigationBar.Position = UDim2.new(0.5, 0, 0, 48)
navigationBar.Size = UDim2.new(0.92, 0, 0, 52)
navigationBar.BackgroundTransparency = 1
navigationBar.ZIndex = 25
navigationBar.Parent = screenGui

local navigationConstraint = Instance.new("UISizeConstraint")
navigationConstraint.MinSize = Vector2.new(300, 52)
navigationConstraint.MaxSize = Vector2.new(560, 52)
navigationConstraint.Parent = navigationBar

local navigationLayout = Instance.new("UIListLayout")
navigationLayout.FillDirection = Enum.FillDirection.Horizontal
navigationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navigationLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navigationLayout.Padding = UDim.new(0, 6)
navigationLayout.Parent = navigationBar

local navigationButtons = {}
local navigationEnabled = true
local function createNavigationButton(
	name: string,
	text: string,
	locationId: string,
	widthScale: number,
	background: Color3,
	strokeColor: Color3
)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromScale(widthScale, 1)
	button.BackgroundColor3 = background
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 250, 226)
	button.TextSize = 15
	button.TextWrapped = true
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 26
	button.Parent = navigationBar
	addCorner(button, 6)
	addStroke(button, strokeColor, 2)
	button.MouseButton1Click:Connect(function()
		if navigationEnabled then
			requestTeleport:FireServer(locationId)
		end
	end)
	table.insert(navigationButtons, button)
	return button
end

createNavigationButton(
	"HomeButton",
	"HOME",
	"home",
	0.2,
	Color3.fromRGB(48, 111, 154),
	Color3.fromRGB(120, 210, 240)
)
createNavigationButton(
	"ShopButton",
	"MILO'S SHOP",
	"shop",
	0.34,
	Color3.fromRGB(164, 116, 35),
	Color3.fromRGB(247, 207, 86)
)
createNavigationButton(
	"DumpButton",
	"SALVAGE DUMP",
	"dump",
	0.42,
	Color3.fromRGB(91, 67, 43),
	Color3.fromRGB(151, 108, 66)
)

local function setNavigationEnabled(enabled: boolean)
	navigationEnabled = enabled
	for _, button in ipairs(navigationButtons) do
		button.Active = enabled
		button.AutoButtonColor = enabled
		button.BackgroundTransparency = if enabled then 0 else 0.45
		button.TextTransparency = if enabled then 0 else 0.35
	end
end

local experiencePanel = Instance.new("Frame")
experiencePanel.Name = "ExperiencePanel"
experiencePanel.Position = UDim2.fromOffset(18, 176)
experiencePanel.Size = UDim2.fromOffset(260, 112)
experiencePanel.BackgroundColor3 = COLORS.Panel
experiencePanel.BackgroundTransparency = 0.08
experiencePanel.BorderSizePixel = 0
experiencePanel.ZIndex = 5
experiencePanel.Parent = screenGui
addCorner(experiencePanel, 6)
addStroke(experiencePanel, COLORS.Gold, 2)

local levelLabel = Instance.new("TextLabel")
levelLabel.Position = UDim2.fromOffset(16, 12)
levelLabel.Size = UDim2.new(1, -32, 0, 28)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "LEVEL 0"
levelLabel.TextColor3 = COLORS.Cream
levelLabel.TextSize = 21
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.ZIndex = 6
levelLabel.Parent = experiencePanel

local experienceText = Instance.new("TextLabel")
experienceText.Position = UDim2.fromOffset(16, 42)
experienceText.Size = UDim2.new(1, -32, 0, 22)
experienceText.BackgroundTransparency = 1
experienceText.Text = "0 / 50 XP"
experienceText.TextColor3 = Color3.fromRGB(205, 222, 225)
experienceText.TextSize = 15
experienceText.Font = Enum.Font.GothamMedium
experienceText.TextXAlignment = Enum.TextXAlignment.Left
experienceText.ZIndex = 6
experienceText.Parent = experiencePanel

local experienceBarBack = Instance.new("Frame")
experienceBarBack.Position = UDim2.fromOffset(16, 74)
experienceBarBack.Size = UDim2.new(1, -32, 0, 22)
experienceBarBack.BackgroundColor3 = Color3.fromRGB(12, 22, 27)
experienceBarBack.BorderSizePixel = 0
experienceBarBack.ZIndex = 6
experienceBarBack.Parent = experiencePanel
addCorner(experienceBarBack, 4)

local experienceBarFill = Instance.new("Frame")
experienceBarFill.Size = UDim2.fromScale(0, 1)
experienceBarFill.BackgroundColor3 = COLORS.Gold
experienceBarFill.BorderSizePixel = 0
experienceBarFill.ZIndex = 7
experienceBarFill.Parent = experienceBarBack
addCorner(experienceBarFill, 4)

local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.Position = UDim2.fromOffset(18, 300)
moneyPanel.Size = UDim2.fromOffset(260, 48)
moneyPanel.BackgroundColor3 = Color3.fromRGB(32, 92, 61)
moneyPanel.BackgroundTransparency = 0.06
moneyPanel.BorderSizePixel = 0
moneyPanel.ZIndex = 5
moneyPanel.Parent = screenGui
addCorner(moneyPanel, 6)
addStroke(moneyPanel, COLORS.Green, 2)

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Position = UDim2.fromOffset(14, 0)
moneyLabel.Size = UDim2.new(1, -28, 1, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "COINS  0"
moneyLabel.TextColor3 = Color3.fromRGB(240, 255, 240)
moneyLabel.TextSize = 20
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.ZIndex = 6
moneyLabel.Parent = moneyPanel

local toolStatus = Instance.new("TextLabel")
toolStatus.Name = "ToolStatus"
toolStatus.Position = UDim2.fromOffset(18, 360)
toolStatus.Size = UDim2.fromOffset(260, 42)
toolStatus.BackgroundColor3 = COLORS.Ink
toolStatus.BackgroundTransparency = 0.12
toolStatus.BorderSizePixel = 0
toolStatus.Text = "No cleaning tool equipped"
toolStatus.TextColor3 = COLORS.Cream
toolStatus.TextSize = 15
toolStatus.Font = Enum.Font.GothamMedium
toolStatus.ZIndex = 5
toolStatus.Parent = screenGui
addCorner(toolStatus, 5)

local qualityPanel = Instance.new("Frame")
qualityPanel.Name = "QualitySpongeAbility"
qualityPanel.AnchorPoint = Vector2.new(1, 0.5)
qualityPanel.Position = UDim2.new(1, -18, 0.5, 0)
qualityPanel.Size = UDim2.fromOffset(270, 104)
qualityPanel.BackgroundColor3 = COLORS.Panel
qualityPanel.BorderSizePixel = 0
qualityPanel.Visible = false
qualityPanel.ZIndex = 8
qualityPanel.Parent = screenGui
addCorner(qualityPanel, 6)
local qualityStroke = Instance.new("UIStroke")
qualityStroke.Color = COLORS.Blue
qualityStroke.Thickness = 2
qualityStroke.Parent = qualityPanel

local qualityTitle = Instance.new("TextLabel")
qualityTitle.Position = UDim2.fromOffset(14, 9)
qualityTitle.Size = UDim2.new(1, -28, 0, 22)
qualityTitle.BackgroundTransparency = 1
qualityTitle.Text = "QUALITY CHARGE"
qualityTitle.TextColor3 = COLORS.Cream
qualityTitle.TextSize = 16
qualityTitle.Font = Enum.Font.GothamBold
qualityTitle.TextXAlignment = Enum.TextXAlignment.Left
qualityTitle.ZIndex = 9
qualityTitle.Parent = qualityPanel

local qualityBarBack = Instance.new("Frame")
qualityBarBack.Position = UDim2.fromOffset(14, 38)
qualityBarBack.Size = UDim2.new(1, -82, 0, 34)
qualityBarBack.BackgroundColor3 = Color3.fromRGB(12, 22, 27)
qualityBarBack.BorderSizePixel = 0
qualityBarBack.ZIndex = 9
qualityBarBack.Parent = qualityPanel
addCorner(qualityBarBack, 4)

local qualityBarFill = Instance.new("Frame")
qualityBarFill.Size = UDim2.fromScale(0, 1)
qualityBarFill.BackgroundColor3 = COLORS.Blue
qualityBarFill.BorderSizePixel = 0
qualityBarFill.ZIndex = 10
qualityBarFill.Parent = qualityBarBack
addCorner(qualityBarFill, 4)

local qualityChargeText = Instance.new("TextLabel")
qualityChargeText.Size = UDim2.fromScale(1, 1)
qualityChargeText.BackgroundTransparency = 1
qualityChargeText.Text = "0/10"
qualityChargeText.TextColor3 = Color3.fromRGB(255, 255, 255)
qualityChargeText.TextSize = 18
qualityChargeText.Font = Enum.Font.GothamBold
qualityChargeText.ZIndex = 11
qualityChargeText.Parent = qualityBarBack

local qualityHint = Instance.new("TextLabel")
qualityHint.Position = UDim2.fromOffset(14, 78)
qualityHint.Size = UDim2.new(1, -82, 0, 18)
qualityHint.BackgroundTransparency = 1
qualityHint.Text = "CLEAN SPOTS TO CHARGE"
qualityHint.TextColor3 = Color3.fromRGB(196, 216, 221)
qualityHint.TextSize = 12
qualityHint.Font = Enum.Font.GothamMedium
qualityHint.TextXAlignment = Enum.TextXAlignment.Left
qualityHint.ZIndex = 9
qualityHint.Parent = qualityPanel

local qualityAbilityButton = Instance.new("TextButton")
qualityAbilityButton.AnchorPoint = Vector2.new(1, 0.5)
qualityAbilityButton.Position = UDim2.new(1, -12, 0.5, 8)
qualityAbilityButton.Size = UDim2.fromOffset(50, 50)
qualityAbilityButton.BackgroundColor3 = COLORS.Gold
qualityAbilityButton.BorderSizePixel = 0
qualityAbilityButton.Text = utf8.char(0x26A1)
qualityAbilityButton.TextColor3 = COLORS.Ink
qualityAbilityButton.TextSize = 30
qualityAbilityButton.Font = Enum.Font.GothamBold
qualityAbilityButton.Visible = false
qualityAbilityButton.ZIndex = 11
qualityAbilityButton.Parent = qualityPanel
addCorner(qualityAbilityButton, 6)

local qualityReady = false
local function claimQualityAbility()
	if qualityReady and qualityPanel.Visible then
		claimQualitySpongeAbility:FireServer()
	end
end

qualityAbilityButton.MouseButton1Click:Connect(claimQualityAbility)

local qualityRainbowConnection: RBXScriptConnection? = nil
local function updateQualityPosition()
	local camera = Workspace.CurrentCamera
	if camera and camera.ViewportSize.X < 700 then
		qualityPanel.Position = UDim2.new(1, -12, 0.72, 0)
	else
		qualityPanel.Position = UDim2.new(1, -18, 0.5, 0)
	end
end

local viewportConnection: RBXScriptConnection? = nil
local function bindViewportUpdates()
	if viewportConnection then
		viewportConnection:Disconnect()
	end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection =
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateQualityPosition)
	end
	updateQualityPosition()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportUpdates)
bindViewportUpdates()

local function setQualityRainbowEnabled(enabled: boolean)
	if enabled and not qualityRainbowConnection then
		qualityRainbowConnection = RunService.RenderStepped:Connect(function()
			local rainbow = Color3.fromHSV((os.clock() * 0.32) % 1, 0.85, 1)
			qualityBarFill.BackgroundColor3 = rainbow
			qualityStroke.Color = rainbow
			qualityAbilityButton.BackgroundColor3 = rainbow
		end)
	elseif not enabled and qualityRainbowConnection then
		qualityRainbowConnection:Disconnect()
		qualityRainbowConnection = nil
	end
end

local cleaningPanel = Instance.new("Frame")
cleaningPanel.Name = "CleaningMinigame"
cleaningPanel.AnchorPoint = Vector2.new(0.5, 1)
cleaningPanel.Position = UDim2.new(0.5, 0, 1, -105)
cleaningPanel.Size = UDim2.new(0.72, 0, 0, 128)
cleaningPanel.BackgroundColor3 = COLORS.Panel
cleaningPanel.BorderSizePixel = 0
cleaningPanel.Visible = false
cleaningPanel.ZIndex = 10
cleaningPanel.Parent = screenGui
addCorner(cleaningPanel)
addStroke(cleaningPanel, COLORS.Gold, 3)

local cleaningConstraint = Instance.new("UISizeConstraint")
cleaningConstraint.MinSize = Vector2.new(300, 128)
cleaningConstraint.MaxSize = Vector2.new(620, 128)
cleaningConstraint.Parent = cleaningPanel

local cleaningTitle = Instance.new("TextLabel")
cleaningTitle.Position = UDim2.fromOffset(18, 10)
cleaningTitle.Size = UDim2.new(1, -36, 0, 28)
cleaningTitle.BackgroundTransparency = 1
cleaningTitle.Text = "CLEANING"
cleaningTitle.TextColor3 = COLORS.Cream
cleaningTitle.TextSize = 21
cleaningTitle.Font = Enum.Font.GothamBold
cleaningTitle.TextXAlignment = Enum.TextXAlignment.Left
cleaningTitle.ZIndex = 11
cleaningTitle.Parent = cleaningPanel

local progressBack = Instance.new("Frame")
progressBack.Position = UDim2.fromOffset(18, 48)
progressBack.Size = UDim2.new(1, -36, 0, 48)
progressBack.BackgroundColor3 = Color3.fromRGB(12, 22, 27)
progressBack.BorderSizePixel = 0
progressBack.ZIndex = 11
progressBack.Parent = cleaningPanel
addCorner(progressBack, 4)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = COLORS.Blue
progressFill.BorderSizePixel = 0
progressFill.ZIndex = 12
progressFill.Parent = progressBack
addCorner(progressFill, 4)

local progressText = Instance.new("TextLabel")
progressText.Size = UDim2.fromScale(1, 1)
progressText.BackgroundTransparency = 1
progressText.Text = "0 / 0"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextSize = 20
progressText.Font = Enum.Font.GothamBold
progressText.ZIndex = 13
progressText.Parent = progressBack

local cleaningHint = Instance.new("TextLabel")
cleaningHint.Position = UDim2.new(0, 18, 1, -26)
cleaningHint.Size = UDim2.new(1, -36, 0, 18)
cleaningHint.BackgroundTransparency = 1
cleaningHint.Text = "CLICK OR TAP ANYWHERE"
cleaningHint.TextColor3 = Color3.fromRGB(190, 210, 216)
cleaningHint.TextSize = 13
cleaningHint.Font = Enum.Font.GothamMedium
cleaningHint.ZIndex = 11
cleaningHint.Parent = cleaningPanel

local activeCleaning = false
local displayedProgress = 0
local serverProgress = 0
local requiredClicks = 1
local decayClicksPerSecond = 0
local lastProgressUpdate = 0
local cleaningRenderConnection: RBXScriptConnection? = nil

local function stopCleaningRender()
	if cleaningRenderConnection then
		cleaningRenderConnection:Disconnect()
		cleaningRenderConnection = nil
	end
end

local function startCleaningRender()
	stopCleaningRender()
	cleaningRenderConnection = RunService.RenderStepped:Connect(function()
		displayedProgress =
			math.max(0, serverProgress - (os.clock() - lastProgressUpdate) * decayClicksPerSecond)
		local fraction = math.clamp(displayedProgress / requiredClicks, 0, 1)
		progressFill.Size = UDim2.fromScale(fraction, 1)
		progressText.Text =
			string.format("%d / %d", math.floor(displayedProgress + 0.5), requiredClicks)
	end)
end

cleaningStarted.OnClientEvent:Connect(function(data)
	activeCleaning = true
	serverProgress = 0
	displayedProgress = 0
	requiredClicks = data.requiredClicks or 1
	decayClicksPerSecond = data.decayClicksPerSecond or 0
	lastProgressUpdate = os.clock()
	cleaningTitle.Text = "CLEANING"
	progressFill.Size = UDim2.fromScale(0, 1)
	progressText.Text = string.format("0 / %d", requiredClicks)
	cleaningPanel.Visible = true
	setNavigationEnabled(false)
	startCleaningRender()
end)

cleaningProgress.OnClientEvent:Connect(function(progress, required)
	serverProgress = progress
	displayedProgress = progress
	requiredClicks = required
	lastProgressUpdate = os.clock()
end)

cleaningEnded.OnClientEvent:Connect(function(completed, message)
	activeCleaning = false
	stopCleaningRender()
	cleaningPanel.Visible = false
	setNavigationEnabled(true)
	if not completed and message then
		showNotification(message)
	end
end)

local dialogue = Instance.new("Frame")
dialogue.Name = "ShopDialogue"
dialogue.AnchorPoint = Vector2.new(0.5, 1)
dialogue.Position = UDim2.new(0.5, 0, 1, -28)
dialogue.Size = UDim2.new(0.86, 0, 0, 188)
dialogue.BackgroundColor3 = COLORS.Ink
dialogue.BorderSizePixel = 0
dialogue.Visible = false
dialogue.ZIndex = 15
dialogue.Parent = screenGui
addCorner(dialogue)
addStroke(dialogue, COLORS.Gold, 4)

local dialogueConstraint = Instance.new("UISizeConstraint")
dialogueConstraint.MinSize = Vector2.new(340, 188)
dialogueConstraint.MaxSize = Vector2.new(980, 188)
dialogueConstraint.Parent = dialogue

local clerkName = Instance.new("TextLabel")
clerkName.Position = UDim2.fromOffset(24, 18)
clerkName.Size = UDim2.new(0.64, -24, 0, 30)
clerkName.BackgroundTransparency = 1
clerkName.Text = "MILO"
clerkName.TextColor3 = COLORS.Gold
clerkName.TextSize = 21
clerkName.Font = Enum.Font.GothamBold
clerkName.TextXAlignment = Enum.TextXAlignment.Left
clerkName.ZIndex = 16
clerkName.Parent = dialogue

local dialogueText = Instance.new("TextLabel")
dialogueText.Position = UDim2.fromOffset(24, 55)
dialogueText.Size = UDim2.new(0.64, -28, 1, -75)
dialogueText.BackgroundTransparency = 1
dialogueText.Text = "Hey there! Looking to put some shine on that car? Want to check out my shop?"
dialogueText.TextColor3 = COLORS.Cream
dialogueText.TextSize = 19
dialogueText.TextWrapped = true
dialogueText.Font = Enum.Font.GothamMedium
dialogueText.TextXAlignment = Enum.TextXAlignment.Left
dialogueText.TextYAlignment = Enum.TextYAlignment.Top
dialogueText.ZIndex = 16
dialogueText.Parent = dialogue

local function createChoiceButton(text: string, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Position = position
	button.Size = UDim2.new(0.31, 0, 0, 58)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 16
	button.Parent = dialogue
	addCorner(button, 4)
	return button
end

local buyChoice = createChoiceButton("I want to buy", UDim2.new(0.66, 0, 0, 28), COLORS.Green)
local leaveChoice = createChoiceButton("Nevermind", UDim2.new(0.66, 0, 0, 102), COLORS.PanelLight)

local shop = Instance.new("Frame")
shop.Name = "ShopMenu"
shop.AnchorPoint = Vector2.new(0.5, 0.5)
shop.Position = UDim2.fromScale(0.5, 0.5)
shop.Size = UDim2.fromScale(0.84, 0.82)
shop.BackgroundColor3 = COLORS.Panel
shop.BorderSizePixel = 0
shop.Visible = false
shop.ZIndex = 15
shop.Parent = screenGui
addCorner(shop)
addStroke(shop, COLORS.Gold, 3)

local shopConstraint = Instance.new("UISizeConstraint")
shopConstraint.MinSize = Vector2.new(340, 300)
shopConstraint.MaxSize = Vector2.new(760, 490)
shopConstraint.Parent = shop

local shopTitle = Instance.new("TextLabel")
shopTitle.Position = UDim2.fromOffset(22, 14)
shopTitle.Size = UDim2.new(1, -84, 0, 42)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "CORNER CLEAN SUPPLY"
shopTitle.TextColor3 = COLORS.Cream
shopTitle.TextSize = 24
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.ZIndex = 16
shopTitle.Parent = shop

local closeShop = Instance.new("TextButton")
closeShop.AnchorPoint = Vector2.new(1, 0)
closeShop.Position = UDim2.new(1, -16, 0, 14)
closeShop.Size = UDim2.fromOffset(42, 42)
closeShop.BackgroundColor3 = COLORS.Red
closeShop.BorderSizePixel = 0
closeShop.Text = "X"
closeShop.TextColor3 = Color3.fromRGB(255, 255, 255)
closeShop.TextSize = 20
closeShop.Font = Enum.Font.GothamBold
closeShop.ZIndex = 16
closeShop.Parent = shop
addCorner(closeShop, 4)

local shopItems = Instance.new("ScrollingFrame")
shopItems.Position = UDim2.fromOffset(20, 72)
shopItems.Size = UDim2.new(1, -40, 1, -92)
shopItems.BackgroundTransparency = 1
shopItems.BorderSizePixel = 0
shopItems.CanvasSize = UDim2.fromScale(0, 0)
shopItems.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopItems.ScrollBarThickness = 6
shopItems.ScrollBarImageColor3 = COLORS.Gold
shopItems.ZIndex = 16
shopItems.Parent = shop

local shopList = Instance.new("UIListLayout")
shopList.Padding = UDim.new(0, 10)
shopList.FillDirection = Enum.FillDirection.Vertical
shopList.SortOrder = Enum.SortOrder.LayoutOrder
shopList.Parent = shopItems

local latestShopTools = {}
local activeShopClerk: BasePart? = nil
local shopSessionOpen = false
local shopSessionToken = 0

local function closeShopSession()
	shopSessionOpen = false
	shopSessionToken += 1
	activeShopClerk = nil
	dialogue.Visible = false
	shop.Visible = false
end

local function monitorShopDistance()
	shopSessionToken += 1
	local token = shopSessionToken
	task.spawn(function()
		while shopSessionOpen and token == shopSessionToken do
			task.wait(0.2)
			if not activeShopClerk or not activeShopClerk.Parent then
				closeShopSession()
				return
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if
				not root
				or not root:IsA("BasePart")
				or (root.Position - activeShopClerk.Position).Magnitude > 22
			then
				closeShopSession()
				return
			end
		end
	end)
end

local function renderShop(toolDefinitions)
	latestShopTools = toolDefinitions
	for _, child in ipairs(shopItems:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	for index, definition in ipairs(toolDefinitions) do
		local row = Instance.new("Frame")
		row.Name = definition.Id
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 132)
		row.BackgroundColor3 = COLORS.PanelLight
		row.BorderSizePixel = 0
		row.ZIndex = 16
		row.Parent = shopItems
		addCorner(row, 5)

		local itemName = Instance.new("TextLabel")
		itemName.Position = UDim2.fromOffset(18, 13)
		itemName.Size = UDim2.new(1, -160, 0, 30)
		itemName.BackgroundTransparency = 1
		itemName.Text = definition.DisplayName
		itemName.TextColor3 = COLORS.Cream
		itemName.TextSize = 21
		itemName.Font = Enum.Font.GothamBold
		itemName.TextXAlignment = Enum.TextXAlignment.Left
		itemName.ZIndex = 17
		itemName.Parent = row

		local details = Instance.new("TextLabel")
		details.Position = UDim2.fromOffset(18, 48)
		details.Size = UDim2.new(1, -170, 0, 74)
		details.BackgroundTransparency = 1
		details.Text = string.format(
			"Durability: %d | %d-%d clicks\n%s",
			definition.MaxDurability,
			definition.ClicksMin,
			definition.ClicksMax,
			definition.Description or ""
		)
		details.TextColor3 = Color3.fromRGB(202, 219, 222)
		details.TextSize = 14
		details.TextWrapped = true
		details.Font = Enum.Font.GothamMedium
		details.TextXAlignment = Enum.TextXAlignment.Left
		details.TextYAlignment = Enum.TextYAlignment.Top
		details.ZIndex = 17
		details.Parent = row

		local buyButton = Instance.new("TextButton")
		buyButton.AnchorPoint = Vector2.new(1, 0.5)
		buyButton.Position = UDim2.new(1, -14, 0.5, 0)
		buyButton.Size = UDim2.fromOffset(125, 70)
		buyButton.BackgroundColor3 = COLORS.Green
		buyButton.BorderSizePixel = 0
		buyButton.Text = string.format("BUY\n%d coins", definition.Price)
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextSize = 17
		buyButton.Font = Enum.Font.GothamBold
		buyButton.ZIndex = 17
		buyButton.Parent = row
		addCorner(buyButton, 4)
		buyButton.MouseButton1Click:Connect(function()
			purchaseTool:FireServer(definition.Id)
		end)
	end
end

openShopDialogue.OnClientEvent:Connect(function(shopTools, clerk)
	renderShop(shopTools)
	activeShopClerk = if typeof(clerk) == "Instance" and clerk:IsA("BasePart") then clerk else nil
	shopSessionOpen = true
	shop.Visible = false
	dialogue.Visible = true
	monitorShopDistance()
end)

buyChoice.MouseButton1Click:Connect(function()
	dialogue.Visible = false
	if #latestShopTools > 0 then
		shop.Visible = true
	end
end)

leaveChoice.MouseButton1Click:Connect(function()
	closeShopSession()
end)

closeShop.MouseButton1Click:Connect(function()
	closeShopSession()
end)

local lastDirtRequestAt = 0
local lastDirtRequestTarget: BasePart? = nil
local function pointIsInside(gui: GuiObject, position: Vector3): boolean
	local topLeft = gui.AbsolutePosition
	local bottomRight = topLeft + gui.AbsoluteSize
	return position.X >= topLeft.X
		and position.X <= bottomRight.X
		and position.Y >= topLeft.Y
		and position.Y <= bottomRight.Y
end

local function requestDirtSpot(dirt: BasePart?)
	if
		not dirt
		or dirt:GetAttribute("IsDirtPatch") ~= true
		or activeCleaning
		or dialogue.Visible
		or shop.Visible
	then
		return
	end
	local now = os.clock()
	if dirt == lastDirtRequestTarget and now - lastDirtRequestAt < 0.15 then
		return
	end
	lastDirtRequestTarget = dirt
	lastDirtRequestAt = now
	requestCleanSpot:FireServer(dirt)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	local isPointerClick = input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	if activeCleaning and isPointerClick then
		if dialogue.Visible or shop.Visible or inventoryController:isVisible() then
			return
		end
		if qualityAbilityButton.Visible and pointIsInside(qualityAbilityButton, input.Position) then
			return
		end
		local sprintButton = ContextActionService:GetButton("CarWashRushSprint")
		if sprintButton and pointIsInside(sprintButton, input.Position) then
			return
		end
		cleaningClick:FireServer()
		return
	end

	if gameProcessed or dialogue.Visible or shop.Visible or inventoryController:isVisible() then
		return
	end
	if not isPointerClick then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	params.IgnoreWater = true
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	requestDirtSpot(if result and result.Instance:IsA("BasePart") then result.Instance else nil)
end)

notifyRemote.OnClientEvent:Connect(showNotification)

local latestInventory = nil
local function updateMoneyStatus()
	if latestInventory then
		moneyLabel.Text = string.format("COINS  %d", latestInventory.coins or 0)
	end
end

local function updateExperienceStatus()
	if not latestInventory then
		return
	end
	local level = latestInventory.level or 0
	local experience = latestInventory.experience or 0
	local required = math.max(1, latestInventory.experienceRequired or 50)
	levelLabel.Text = string.format("LEVEL %d", level)
	experienceText.Text = string.format("%d / %d XP", experience, required)
	experienceBarFill.Size = UDim2.fromScale(math.clamp(experience / required, 0, 1), 1)
end

local function updateQualitySpongeStatus()
	if not latestInventory then
		qualityPanel.Visible = false
		qualityReady = false
		setQualityRainbowEnabled(false)
		return
	end
	local equippedToolId = nil
	local equippedToolDurability = 0
	for _, item in ipairs(latestInventory.inventory) do
		if item.id == latestInventory.equippedItemId then
			equippedToolId = item.toolId
			equippedToolDurability = item.durability
			break
		end
	end
	if equippedToolId ~= "tool_quality_sponge" or equippedToolDurability <= 0 then
		qualityPanel.Visible = false
		qualityAbilityButton.Visible = false
		qualityReady = false
		setQualityRainbowEnabled(false)
		return
	end

	local required = Config.Cleaning.QualitySpongeChargeRequired
	local charge = math.clamp(latestInventory.qualitySpongeCharge or 0, 0, required)
	qualityReady = charge >= required
	setQualityRainbowEnabled(qualityReady)
	qualityPanel.Visible = true
	qualityChargeText.Text = string.format("%d/%d", charge, required)
	qualityBarFill.Size = UDim2.fromScale(charge / required, 1)
	qualityAbilityButton.Visible = qualityReady and UserInputService.TouchEnabled
	if qualityReady then
		qualityTitle.Text = "CHARGE READY"
		if UserInputService.TouchEnabled then
			qualityHint.Text =
				string.format("TAP BOLT: +%d COINS", Config.Cleaning.QualitySpongeAbilityReward)
		else
			qualityHint.Text = string.format(
				"PRESS E TO CLAIM %d COINS",
				Config.Cleaning.QualitySpongeAbilityReward
			)
		end
	else
		qualityTitle.Text = "QUALITY CHARGE"
		qualityHint.Text = "CLEAN SPOTS TO CHARGE"
		qualityBarFill.BackgroundColor3 = COLORS.Blue
		qualityStroke.Color = COLORS.Blue
		qualityAbilityButton.BackgroundColor3 = COLORS.Gold
	end
end

local function updateToolStatus()
	if not latestInventory then
		return
	end
	local equippedId = latestInventory.equippedItemId
	for _, item in ipairs(latestInventory.inventory) do
		if item.id == equippedId then
			local state = if item.durability <= 0
				then "BROKEN"
				else string.format("%d/%d", item.durability, item.maxDurability)
			toolStatus.Text = string.format("%s  |  %s", item.displayName, state)
			return
		end
	end
	toolStatus.Text = "No cleaning tool equipped"
end

local function isCleaningToolHeld(): boolean
	local character = player.Character
	if not character then
		return false
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("CarWashRushTool") == true then
			return true
		end
	end
	return false
end

local function updateDirtHighlights()
	highlightController:setHeld(isCleaningToolHeld())
end

inventoryUpdated.OnClientEvent:Connect(function(snapshot)
	latestInventory = snapshot
	inventoryController:setSnapshot(snapshot)
	updateMoneyStatus()
	updateExperienceStatus()
	updateQualitySpongeStatus()
	updateToolStatus()
	updateDirtHighlights()
end)

local sprinting = false
local function setSprinting(value: boolean)
	if sprinting == value then
		return
	end
	sprinting = value
	sprintChanged:FireServer(value)
end

local function sprintAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		setSprinting(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		setSprinting(false)
	end
	return Enum.ContextActionResult.Sink
end

local function blockJump()
	return Enum.ContextActionResult.Sink
end

local function qualityAbilityAction(_, inputState)
	if inputState == Enum.UserInputState.Begin and qualityReady and qualityPanel.Visible then
		claimQualityAbility()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("CarWashRushSprint", sprintAction, true, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle("CarWashRushSprint", "Sprint")
ContextActionService:SetPosition("CarWashRushSprint", UDim2.new(1, -105, 1, -275))
ContextActionService:BindActionAtPriority(
	"CarWashRushDisableJump",
	blockJump,
	false,
	3000,
	Enum.KeyCode.Space,
	Enum.KeyCode.ButtonA
)
ContextActionService:BindActionAtPriority(
	"CarWashRushQualityAbility",
	qualityAbilityAction,
	false,
	2500,
	Enum.KeyCode.E
)

local function configureLocalCharacter(character: Model)
	setSprinting(false)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end

	local mouse = player:GetMouse()
	local connectedTools = {}
	local function connectTool(tool: Instance)
		if
			not tool:IsA("Tool")
			or tool:GetAttribute("CarWashRushTool") ~= true
			or connectedTools[tool]
		then
			return
		end
		connectedTools[tool] = true
		tool.Equipped:Connect(function()
			task.defer(updateDirtHighlights)
		end)
		tool.Unequipped:Connect(function()
			task.defer(updateDirtHighlights)
		end)
		tool.Activated:Connect(function()
			local target = mouse.Target
			requestDirtSpot(if target and target:IsA("BasePart") then target else nil)
		end)
	end
	character.ChildAdded:Connect(function(child)
		connectTool(child)
		task.defer(updateDirtHighlights)
	end)
	character.ChildRemoved:Connect(function()
		task.defer(updateDirtHighlights)
	end)
	for _, child in ipairs(character:GetChildren()) do
		connectTool(child)
	end
	task.defer(updateDirtHighlights)

	if UserInputService.TouchEnabled then
		task.delay(1, function()
			for _, descendant in ipairs(playerGui:GetDescendants()) do
				if descendant:IsA("GuiButton") and descendant.Name == "JumpButton" then
					descendant.Visible = false
				end
			end
		end)
	end
end

player.CharacterAdded:Connect(configureLocalCharacter)
if player.Character then
	task.defer(configureLocalCharacter, player.Character)
end

requestInventory:FireServer()
print("[Car Wash Rush] Client loaded.")
