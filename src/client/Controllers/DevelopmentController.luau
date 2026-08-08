--!strict

local RunService = game:GetService("RunService")

local DevelopmentController = {}

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

function DevelopmentController.new(
	parent: ScreenGui,
	devCommand: RemoteEvent,
	forceEvent: RemoteEvent
)
	if not RunService:IsStudio() then
		return
	end
	local toggle = Instance.new("TextButton")
	toggle.Name = "StudioTestToggle"
	toggle.AnchorPoint = Vector2.new(1, 0)
	toggle.Position = UDim2.new(1, -18, 0, 18)
	toggle.Size = UDim2.fromOffset(86, 38)
	toggle.BackgroundColor3 = Color3.fromRGB(72, 54, 100)
	toggle.BorderSizePixel = 0
	toggle.Text = "TEST"
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.TextSize = 14
	toggle.Font = Enum.Font.GothamBold
	toggle.ZIndex = 80
	toggle.Parent = parent
	addCorner(toggle, 5)

	local panel = Instance.new("Frame")
	panel.Name = "StudioTestPanel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -18, 0, 64)
	panel.Size = UDim2.fromOffset(210, 306)
	panel.BackgroundColor3 = Color3.fromRGB(24, 29, 40)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 80
	panel.Parent = parent
	addCorner(panel, 6)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(176, 139, 226)
	stroke.Thickness = 2
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -24, 0, 28)
	title.BackgroundTransparency = 1
	title.Text = "STUDIO TEST CONTROLS"
	title.TextColor3 = Color3.fromRGB(237, 222, 255)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 81
	title.Parent = panel

	local list = Instance.new("Frame")
	list.Position = UDim2.fromOffset(10, 42)
	list.Size = UDim2.new(1, -20, 1, -52)
	list.BackgroundTransparency = 1
	list.ZIndex = 81
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	local resetArmed = false
	local function addButton(label: string, callback: () -> ()): TextButton
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 38)
		button.BackgroundColor3 = Color3.fromRGB(59, 67, 86)
		button.BorderSizePixel = 0
		button.Text = label
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextSize = 13
		button.Font = Enum.Font.GothamBold
		button.ZIndex = 82
		button.Parent = list
		addCorner(button, 4)
		button.MouseButton1Click:Connect(callback)
		return button
	end

	addButton("+5,000 COINS", function()
		devCommand:FireServer("coins")
	end)
	addButton("SET LEVEL 10", function()
		devCommand:FireServer("level10")
	end)
	addButton("GRANT OLD RAG", function()
		devCommand:FireServer("rag")
	end)
	addButton("+50 EVENT TOKENS", function()
		devCommand:FireServer("tokens")
	end)
	addButton("START BUS EVENT", function()
		forceEvent:FireServer()
	end)
	local resetButton: TextButton
	resetButton = addButton("RESET PROFILE", function()
		if not resetArmed then
			resetArmed = true
			resetButton.Text = "CLICK AGAIN TO RESET"
			task.delay(4, function()
				resetArmed = false
				resetButton.Text = "RESET PROFILE"
			end)
			return
		end
		resetArmed = false
		resetButton.Text = "RESET PROFILE"
		devCommand:FireServer("reset_profile")
	end)

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

return DevelopmentController
