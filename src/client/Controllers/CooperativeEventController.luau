--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CooperativeEventController = {}
CooperativeEventController.__index = CooperativeEventController

local INSTRUCTIONS = {
	foam = "Click or tap steadily to cover the bus evenly with foam.",
	scrub = "Hold and trace back and forth to scrub the loosened dirt.",
	pressure = "Aim while spraying. Releasing aim immediately stops the stream.",
	wheels = "Click or tap to work around every wheel and rim.",
	vacuum = "Hold and follow the moving debris before suction expires.",
	polish = "Tap in a steady rhythm to keep the polisher in its safe range.",
}

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addStroke(parent: GuiObject, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = parent
end

function CooperativeEventController.new(parent: ScreenGui, remotes: any): any
	local self = setmetatable({}, CooperativeEventController)
	self.state = nil :: any
	self.minigame = nil :: any
	self.pointerHeld = false
	self.aimHeld = false
	self.sprayHeld = false
	self.lastPointer = nil :: Vector3?
	self.lastSendAt = 0
	self.localContribution = 0

	local status = Instance.new("Frame")
	status.Name = "CooperativeEventStatus"
	status.AnchorPoint = Vector2.new(0.5, 0)
	status.Position = UDim2.new(0.5, 0, 0, 100)
	status.Size = UDim2.new(0.58, 0, 0, 64)
	status.BackgroundColor3 = Color3.fromRGB(82, 55, 32)
	status.BorderSizePixel = 0
	status.Visible = false
	status.ZIndex = 22
	status.Parent = parent
	local statusConstraint = Instance.new("UISizeConstraint")
	statusConstraint.MinSize = Vector2.new(280, 64)
	statusConstraint.MaxSize = Vector2.new(620, 64)
	statusConstraint.Parent = status
	addCorner(status, 6)
	addStroke(status, Color3.fromRGB(255, 193, 72), 2)

	local statusTitle = Instance.new("TextLabel")
	statusTitle.Position = UDim2.fromOffset(12, 7)
	statusTitle.Size = UDim2.new(1, -104, 0, 23)
	statusTitle.BackgroundTransparency = 1
	statusTitle.TextColor3 = Color3.fromRGB(255, 239, 191)
	statusTitle.TextSize = 15
	statusTitle.Font = Enum.Font.GothamBold
	statusTitle.TextXAlignment = Enum.TextXAlignment.Left
	statusTitle.ZIndex = 23
	statusTitle.Parent = status

	local statusProgress = Instance.new("TextLabel")
	statusProgress.Position = UDim2.fromOffset(12, 33)
	statusProgress.Size = UDim2.new(1, -24, 0, 22)
	statusProgress.BackgroundTransparency = 1
	statusProgress.TextColor3 = Color3.fromRGB(229, 235, 229)
	statusProgress.TextSize = 13
	statusProgress.Font = Enum.Font.Gotham
	statusProgress.TextXAlignment = Enum.TextXAlignment.Left
	statusProgress.ZIndex = 23
	statusProgress.Parent = status

	local statusTimer = Instance.new("TextLabel")
	statusTimer.AnchorPoint = Vector2.new(1, 0)
	statusTimer.Position = UDim2.new(1, -12, 0, 8)
	statusTimer.Size = UDim2.fromOffset(90, 22)
	statusTimer.BackgroundTransparency = 1
	statusTimer.TextColor3 = Color3.fromRGB(109, 231, 167)
	statusTimer.TextSize = 14
	statusTimer.Font = Enum.Font.GothamBold
	statusTimer.TextXAlignment = Enum.TextXAlignment.Right
	statusTimer.ZIndex = 23
	statusTimer.Parent = status

	local panel = Instance.new("Frame")
	panel.Name = "EventMinigame"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -24)
	panel.Size = UDim2.new(0.72, 0, 0, 154)
	panel.BackgroundColor3 = Color3.fromRGB(19, 34, 40)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 60
	panel.Parent = parent
	local panelConstraint = Instance.new("UISizeConstraint")
	panelConstraint.MinSize = Vector2.new(290, 154)
	panelConstraint.MaxSize = Vector2.new(720, 154)
	panelConstraint.Parent = panel
	addCorner(panel, 6)
	addStroke(panel, Color3.fromRGB(76, 202, 226), 2)

	local phaseTitle = Instance.new("TextLabel")
	phaseTitle.Position = UDim2.fromOffset(16, 10)
	phaseTitle.Size = UDim2.new(1, -72, 0, 28)
	phaseTitle.BackgroundTransparency = 1
	phaseTitle.TextColor3 = Color3.fromRGB(255, 225, 122)
	phaseTitle.TextSize = 18
	phaseTitle.Font = Enum.Font.GothamBold
	phaseTitle.TextXAlignment = Enum.TextXAlignment.Left
	phaseTitle.ZIndex = 61
	phaseTitle.Parent = panel

	local instruction = Instance.new("TextLabel")
	instruction.Position = UDim2.fromOffset(16, 42)
	instruction.Size = UDim2.new(1, -32, 0, 43)
	instruction.BackgroundTransparency = 1
	instruction.TextColor3 = Color3.fromRGB(238, 243, 235)
	instruction.TextSize = 14
	instruction.Font = Enum.Font.Gotham
	instruction.TextWrapped = true
	instruction.TextXAlignment = Enum.TextXAlignment.Left
	instruction.TextYAlignment = Enum.TextYAlignment.Top
	instruction.ZIndex = 61
	instruction.Parent = panel

	local actionBar = Instance.new("Frame")
	actionBar.Position = UDim2.fromOffset(16, 97)
	actionBar.Size = UDim2.new(1, -32, 0, 22)
	actionBar.BackgroundColor3 = Color3.fromRGB(42, 62, 67)
	actionBar.BorderSizePixel = 0
	actionBar.ZIndex = 61
	actionBar.Parent = panel
	addCorner(actionBar, 4)
	local actionFill = Instance.new("Frame")
	actionFill.Size = UDim2.fromScale(0, 1)
	actionFill.BackgroundColor3 = Color3.fromRGB(82, 215, 139)
	actionFill.BorderSizePixel = 0
	actionFill.ZIndex = 62
	actionFill.Parent = actionBar
	addCorner(actionFill, 4)

	local personal = Instance.new("TextLabel")
	personal.Position = UDim2.fromOffset(16, 124)
	personal.Size = UDim2.new(1, -32, 0, 20)
	personal.BackgroundTransparency = 1
	personal.TextColor3 = Color3.fromRGB(134, 219, 236)
	personal.TextSize = 12
	personal.Font = Enum.Font.GothamBold
	personal.TextXAlignment = Enum.TextXAlignment.Left
	personal.ZIndex = 61
	personal.Parent = panel

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 9)
	close.Size = UDim2.fromOffset(36, 34)
	close.BackgroundColor3 = Color3.fromRGB(182, 63, 57)
	close.BorderSizePixel = 0
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.TextSize = 16
	close.Font = Enum.Font.GothamBold
	close.ZIndex = 63
	close.Parent = panel
	addCorner(close, 4)

	local aimPad = Instance.new("Frame")
	aimPad.Name = "PressureAim"
	aimPad.AnchorPoint = Vector2.new(1, 1)
	aimPad.Position = UDim2.new(1, -24, 1, -194)
	aimPad.Size = UDim2.fromOffset(132, 132)
	aimPad.BackgroundColor3 = Color3.fromRGB(22, 45, 54)
	aimPad.BackgroundTransparency = 0.18
	aimPad.BorderSizePixel = 0
	aimPad.Visible = false
	aimPad.ZIndex = 65
	aimPad.Parent = parent
	addCorner(aimPad, 66)
	addStroke(aimPad, Color3.fromRGB(96, 207, 230), 2)
	local crosshair = Instance.new("TextLabel")
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.Size = UDim2.fromOffset(46, 46)
	crosshair.BackgroundTransparency = 1
	crosshair.Text = "+"
	crosshair.TextColor3 = Color3.fromRGB(229, 250, 255)
	crosshair.TextSize = 38
	crosshair.Font = Enum.Font.GothamBold
	crosshair.ZIndex = 66
	crosshair.Parent = aimPad

	local spray = Instance.new("TextButton")
	spray.Name = "PressureSpray"
	spray.AnchorPoint = Vector2.new(1, 1)
	spray.Position = UDim2.new(1, -34, 1, -338)
	spray.Size = UDim2.fromOffset(112, 52)
	spray.BackgroundColor3 = Color3.fromRGB(36, 137, 176)
	spray.BorderSizePixel = 0
	spray.Text = "SPRAY"
	spray.TextColor3 = Color3.new(1, 1, 1)
	spray.TextSize = 16
	spray.Font = Enum.Font.GothamBold
	spray.Visible = false
	spray.ZIndex = 65
	spray.Parent = parent
	addCorner(spray, 6)
	addStroke(spray, Color3.fromRGB(119, 224, 246), 2)

	self.status = status
	self.statusTitle = statusTitle
	self.statusProgress = statusProgress
	self.statusTimer = statusTimer
	self.panel = panel
	self.phaseTitle = phaseTitle
	self.instruction = instruction
	self.actionFill = actionFill
	self.personal = personal
	self.aimPad = aimPad
	self.spray = spray

	local function stopMinigame()
		self.minigame = nil
		self.pointerHeld = false
		self.aimHeld = false
		self.sprayHeld = false
		panel.Visible = false
		aimPad.Visible = false
		spray.Visible = false
	end

	local function sendAction()
		local minigame = self.minigame
		if not minigame then
			return
		end
		local now = os.clock()
		if now - self.lastSendAt < 0.08 then
			return
		end
		self.lastSendAt = now
		self.localContribution += 1
		personal.Text = string.format("YOUR CONTRIBUTION  %d", self.localContribution)
		remotes.action:FireServer(minigame.phaseId)
	end

	close.MouseButton1Click:Connect(stopMinigame)
	remotes.minigame.OnClientEvent:Connect(function(data)
		if data.active ~= true then
			stopMinigame()
			return
		end
		self.minigame = data
		self.localContribution = 0
		phaseTitle.Text = string.format("%s  |  %s", string.upper(data.phaseName), data.toolName)
		instruction.Text = INSTRUCTIONS[data.phaseId] or "Work with the crew to finish this phase."
		personal.Text = "YOUR CONTRIBUTION  0"
		panel.Visible = true
		local touchPressure = data.phaseId == "pressure" and UserInputService.TouchEnabled
		aimPad.Visible = touchPressure
		spray.Visible = touchPressure
	end)
	remotes.state.OnClientEvent:Connect(function(state)
		self.state = state
		status.Visible = state.active == true
		if state.active then
			statusTitle.Text =
				string.format("BUS EVENT: %s", string.upper(state.phaseName or "ARRIVING"))
			statusProgress.Text = string.format(
				"CREW PROGRESS  %d/%d    COMBO %d%%",
				state.progress or 0,
				state.goal or 0,
				state.combo or 0
			)
			actionFill.Size = UDim2.fromScale(
				math.clamp((state.progress or 0) / math.max(1, state.goal or 1), 0, 1),
				1
			)
		end
		if not state.active or (self.minigame and self.minigame.phaseId ~= state.phaseId) then
			stopMinigame()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		local minigame = self.minigame
		if not minigame then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.pointerHeld = true
			self.lastPointer = input.Position
			if not gameProcessed and minigame.phaseId ~= "pressure" then
				sendAction()
			end
		elseif input.UserInputType == Enum.UserInputType.Touch and not gameProcessed then
			self.pointerHeld = true
			self.lastPointer = input.Position
			if minigame.phaseId ~= "pressure" then
				sendAction()
			end
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		local minigame = self.minigame
		if not minigame or not self.pointerHeld then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local previous: Vector3 = self.lastPointer or input.Position
			self.lastPointer = input.Position
			if (input.Position - previous).Magnitude >= 12 then
				if minigame.phaseId == "scrub" or minigame.phaseId == "vacuum" then
					sendAction()
				end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self.pointerHeld = false
			if not self.aimHeld then
				self.sprayHeld = false
			end
		end
	end)

	aimPad.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			self.aimHeld = true
		end
	end)
	aimPad.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			self.aimHeld = false
			self.sprayHeld = false
		end
	end)
	spray.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			self.sprayHeld = true
		end
	end)
	spray.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			self.sprayHeld = false
		end
	end)

	RunService.RenderStepped:Connect(function()
		local state = self.state
		if state and state.active then
			local remaining = math.max(0, state.endsAt - os.time())
			statusTimer.Text =
				string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
		end
		local minigame = self.minigame
		if not minigame or minigame.phaseId ~= "pressure" then
			return
		end
		local spraying = if UserInputService.TouchEnabled
			then self.aimHeld and self.sprayHeld
			else self.pointerHeld
		if spraying then
			sendAction()
			local camera = Workspace.CurrentCamera
			if camera then
				camera.CFrame *= CFrame.new(
					(math.random() - 0.5) * 0.025,
					(math.random() - 0.5) * 0.025,
					0
				)
			end
		end
	end)

	if RunService:IsStudio() and remotes.force then
		local forceButton = Instance.new("TextButton")
		forceButton.Name = "ForceBusEvent"
		forceButton.AnchorPoint = Vector2.new(1, 0)
		forceButton.Position = UDim2.new(1, -18, 0, 18)
		forceButton.Size = UDim2.fromOffset(142, 38)
		forceButton.BackgroundColor3 = Color3.fromRGB(73, 54, 101)
		forceButton.BorderSizePixel = 0
		forceButton.Text = "TEST BUS EVENT"
		forceButton.TextColor3 = Color3.new(1, 1, 1)
		forceButton.TextSize = 13
		forceButton.Font = Enum.Font.GothamBold
		forceButton.ZIndex = 70
		forceButton.Parent = parent
		addCorner(forceButton, 5)
		addStroke(forceButton, Color3.fromRGB(181, 143, 230), 2)
		forceButton.MouseButton1Click:Connect(function()
			remotes.force:FireServer()
		end)
	end

	remotes.request:FireServer()
	return self
end

return CooperativeEventController
