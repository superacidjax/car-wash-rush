local Workspace = game:GetService("Workspace")

local GreyboxStarterCorner = {}

local ROOT_FOLDER_NAME = "Greybox_StarterCorner"
local SHOP_CENTER = Vector3.new(220, 0, 0)

local function createFolder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createPart(
	name: string,
	parent: Instance,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = if canCollide == nil then true else canCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addSurfaceLabel(
	partToLabel: BasePart,
	text: string,
	face: Enum.NormalId?,
	textColor: Color3?
)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.MaxDistance = 95
	gui.Parent = partToLabel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(15, 20, 25)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function buildShop(root: Folder)
	local shop = createFolder(root, "StarterShop")
	createPart(
		"ShopFloor",
		shop,
		Vector3.new(66, 0.5, 54),
		SHOP_CENTER + Vector3.new(0, 0.25, 0),
		Color3.fromRGB(226, 219, 196),
		Enum.Material.Concrete
	)
	createPart(
		"BackWall",
		shop,
		Vector3.new(66, 18, 1),
		SHOP_CENTER + Vector3.new(0, 9, 26),
		Color3.fromRGB(62, 100, 116),
		Enum.Material.Brick
	)
	createPart(
		"Counter",
		shop,
		Vector3.new(25, 4, 5),
		SHOP_CENTER + Vector3.new(0, 2, 7),
		Color3.fromRGB(116, 76, 44),
		Enum.Material.Wood
	)
	createPart(
		"Register",
		shop,
		Vector3.new(3, 2, 2),
		SHOP_CENTER + Vector3.new(7, 5, 6.5),
		Color3.fromRGB(45, 48, 50),
		Enum.Material.Metal
	)

	local sign = createPart(
		"ShopSign",
		shop,
		Vector3.new(32, 7, 1),
		SHOP_CENTER + Vector3.new(0, 13, 25.3),
		Color3.fromRGB(250, 213, 70),
		Enum.Material.SmoothPlastic
	)
	sign.Orientation = Vector3.new(0, 180, 0)
	addSurfaceLabel(sign, "MILO'S SHOP", Enum.NormalId.Front)

	local clerk = Instance.new("Model")
	clerk.Name = "ShopClerk"
	clerk.Parent = shop
	createPart(
		"Legs",
		clerk,
		Vector3.new(3.5, 4, 2),
		SHOP_CENTER + Vector3.new(0, 2.5, 11),
		Color3.fromRGB(35, 50, 75),
		Enum.Material.Fabric
	)
	local torso = createPart(
		"Torso",
		clerk,
		Vector3.new(4.5, 5, 2.5),
		SHOP_CENTER + Vector3.new(0, 6.5, 11),
		Color3.fromRGB(55, 156, 112),
		Enum.Material.Fabric
	)
	local head = createPart(
		"Head",
		clerk,
		Vector3.new(3, 3, 3),
		SHOP_CENTER + Vector3.new(0, 10.5, 11),
		Color3.fromRGB(225, 179, 139),
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball
	createPart(
		"Apron",
		clerk,
		Vector3.new(3.5, 3.5, 0.25),
		SHOP_CENTER + Vector3.new(0, 6.2, 9.65),
		Color3.fromRGB(238, 238, 226),
		Enum.Material.Fabric,
		0,
		false
	)
	clerk.PrimaryPart = torso

	local nameGui = Instance.new("BillboardGui")
	nameGui.Name = "ClerkName"
	nameGui.Size = UDim2.fromOffset(180, 40)
	nameGui.StudsOffset = Vector3.new(0, 2.8, 0)
	nameGui.AlwaysOnTop = true
	nameGui.MaxDistance = 35
	nameGui.Parent = head
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Milo"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = nameGui

	local shopArrival = createPart(
		"ShopArrival",
		shop,
		Vector3.new(6, 0.2, 6),
		SHOP_CENTER + Vector3.new(-13, 0.55, -15),
		Color3.fromRGB(120, 255, 150),
		Enum.Material.Neon,
		1,
		false
	)

	return {
		clerk = torso,
		arrival = shopArrival,
	}
end

function GreyboxStarterCorner.findExisting()
	local root = Workspace:FindFirstChild(ROOT_FOLDER_NAME)
	if not root then
		error("Greybox starter corner was not found in Workspace.")
	end
	local shop = root:WaitForChild("StarterShop")
	return {
		root = root,
		safeZones = root:WaitForChild("PlayerSafeZones"),
		shopClerk = shop:WaitForChild("ShopClerk"):WaitForChild("Torso"),
		shopArrival = shop:WaitForChild("ShopArrival"),
	}
end

function GreyboxStarterCorner.build()
	local old = Workspace:FindFirstChild(ROOT_FOLDER_NAME)
	if old then
		old:Destroy()
	end

	local root = createFolder(Workspace, ROOT_FOLDER_NAME)
	local roads = createFolder(root, "Roads")
	local sidewalks = createFolder(root, "Sidewalks")
	local safeZones = createFolder(root, "PlayerSafeZones")

	createPart(
		"Ground_Base",
		root,
		Vector3.new(2000, 1, 2200),
		Vector3.new(0, -0.5, 0),
		Color3.fromRGB(77, 139, 72),
		Enum.Material.Grass
	)
	createPart(
		"Road_NorthSouth",
		roads,
		Vector3.new(44, 0.2, 600),
		Vector3.new(0, 0.05, 0),
		Color3.fromRGB(42, 42, 42),
		Enum.Material.Asphalt
	)
	createPart(
		"Road_EastWest",
		roads,
		Vector3.new(600, 0.2, 44),
		Vector3.new(0, 0.06, 0),
		Color3.fromRGB(42, 42, 42),
		Enum.Material.Asphalt
	)
	createPart(
		"Yellow_Line_NS",
		roads,
		Vector3.new(2, 0.08, 570),
		Vector3.new(0, 0.22, 0),
		Color3.fromRGB(245, 210, 55),
		Enum.Material.SmoothPlastic
	)
	createPart(
		"Yellow_Line_EW",
		roads,
		Vector3.new(570, 0.08, 2),
		Vector3.new(0, 0.23, 0),
		Color3.fromRGB(245, 210, 55),
		Enum.Material.SmoothPlastic
	)
	createPart(
		"Sidewalk_East",
		sidewalks,
		Vector3.new(280, 0.25, 570),
		Vector3.new(162, 0.16, 0),
		Color3.fromRGB(172, 172, 167),
		Enum.Material.Concrete
	)
	createPart(
		"Sidewalk_West",
		sidewalks,
		Vector3.new(280, 0.25, 570),
		Vector3.new(-162, 0.16, 0),
		Color3.fromRGB(172, 172, 167),
		Enum.Material.Concrete
	)

	local shop = buildShop(root)
	return {
		root = root,
		safeZones = safeZones,
		shopClerk = shop.clerk,
		shopArrival = shop.arrival,
	}
end

return GreyboxStarterCorner
