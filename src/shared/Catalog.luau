local Catalog = {}

Catalog.ToolOrder = {
	"tool_rag",
	"tool_sponge",
	"tool_quality_sponge",
}

Catalog.Tools = {
	tool_old_rag = {
		DisplayName = "Old Rag",
		Price = nil,
		BaseResaleValue = 3,
		MaxDurability = 20,
		ClicksMin = 10,
		ClicksMax = 15,
		HandleColor = Color3.fromRGB(145, 126, 105),
		HandleSize = Vector3.new(1.9, 0.25, 1.4),
		Material = Enum.Material.Fabric,
	},
	tool_rag = {
		DisplayName = "Rag",
		ShopDescription = "A dependable basic cloth for getting started.",
		Price = 25,
		BaseResaleValue = 10,
		MaxDurability = 50,
		ClicksMin = 10,
		ClicksMax = 15,
		HandleColor = Color3.fromRGB(225, 225, 215),
		HandleSize = Vector3.new(1.9, 0.25, 1.4),
		Material = Enum.Material.Fabric,
	},
	tool_sponge = {
		DisplayName = "Sponge",
		ShopDescription = "Earns 1 bonus coin for every dirt spot it cleans.",
		Price = 125,
		BaseResaleValue = 60,
		MaxDurability = 75,
		ClicksMin = 5,
		ClicksMax = 9,
		HandleColor = Color3.fromRGB(250, 205, 45),
		HandleSize = Vector3.new(1.5, 0.7, 1),
		Material = Enum.Material.SmoothPlastic,
	},
	tool_quality_sponge = {
		DisplayName = "Quality Sponge",
		ShopDescription = "Its shine seems to build toward a charged reward...",
		Price = 500,
		BaseResaleValue = 300,
		MaxDurability = 200,
		ClicksMin = 3,
		ClicksMax = 4,
		HandleColor = Color3.fromRGB(45, 205, 245),
		HandleSize = Vector3.new(1.7, 0.8, 1.1),
		Material = Enum.Material.SmoothPlastic,
	},
}

function Catalog.getTool(toolId: string)
	return Catalog.Tools[toolId]
end

function Catalog.getShopTools()
	local shopTools = {}
	for _, toolId in ipairs(Catalog.ToolOrder) do
		local definition = Catalog.Tools[toolId]
		if definition and definition.Price then
			table.insert(shopTools, {
				Id = toolId,
				DisplayName = definition.DisplayName,
				Price = definition.Price,
				MaxDurability = definition.MaxDurability,
				ClicksMin = definition.ClicksMin,
				ClicksMax = definition.ClicksMax,
				Description = definition.ShopDescription,
			})
		end
	end
	return shopTools
end

return Catalog
