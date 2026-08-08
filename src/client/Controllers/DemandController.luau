--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DemandController = {}
DemandController.__index = DemandController

function DemandController.new(
	parent: ScreenGui,
	updatedRemote: RemoteEvent,
	requestRemote: RemoteEvent
): any
	local self = setmetatable({}, DemandController)
	self.state = nil

	local banner = Instance.new("Frame")
	banner.Name = "DemandBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 18)
	banner.Size = UDim2.new(0.62, 0, 0, 76)
	banner.BackgroundColor3 = Color3.fromRGB(25, 55, 64)
	banner.BorderSizePixel = 0
	banner.Visible = false
	banner.ZIndex = 20
	banner.Parent = parent
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(280, 76)
	sizeConstraint.MaxSize = Vector2.new(660, 76)
	sizeConstraint.Parent = banner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = banner
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(246, 198, 68)
	stroke.Thickness = 2
	stroke.Parent = banner

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(14, 8)
	title.Size = UDim2.new(1, -112, 0, 25)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 238, 157)
	title.TextSize = 17
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 21
	title.Parent = banner

	local description = Instance.new("TextLabel")
	description.Position = UDim2.fromOffset(14, 35)
	description.Size = UDim2.new(1, -28, 0, 31)
	description.BackgroundTransparency = 1
	description.TextColor3 = Color3.fromRGB(235, 243, 238)
	description.TextSize = 13
	description.Font = Enum.Font.Gotham
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.ZIndex = 21
	description.Parent = banner

	local timer = Instance.new("TextLabel")
	timer.AnchorPoint = Vector2.new(1, 0)
	timer.Position = UDim2.new(1, -12, 0, 9)
	timer.Size = UDim2.fromOffset(88, 24)
	timer.BackgroundTransparency = 1
	timer.TextColor3 = Color3.fromRGB(104, 220, 160)
	timer.TextSize = 15
	timer.Font = Enum.Font.GothamBold
	timer.TextXAlignment = Enum.TextXAlignment.Right
	timer.ZIndex = 21
	timer.Parent = banner

	self.banner = banner
	self.title = title
	self.description = description
	self.timer = timer

	updatedRemote.OnClientEvent:Connect(function(state)
		self.state = state
		banner.Visible = state.active == true
		if state.active then
			title.Text = "CITY DEMAND: " .. string.upper(state.displayName)
			description.Text = state.description
		end
	end)
	RunService.Heartbeat:Connect(function()
		local state = self.state
		if not state or not state.active then
			return
		end
		local remaining = math.max(0, state.endsAt - math.floor(Workspace:GetServerTimeNow()))
		timer.Text = string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
		if remaining == 0 then
			banner.Visible = false
		end
	end)

	requestRemote:FireServer()
	return self
end

return DemandController
