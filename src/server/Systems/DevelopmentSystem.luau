--!strict

local RunService = game:GetService("RunService")

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local DevelopmentSystem = {}

local function notify(player: Player, message: string)
	Remotes.get("Notify"):FireClient(player, message)
end

function DevelopmentSystem.start()
	Remotes.connect("DevCommand", function(player, command)
		if not RunService:IsStudio() or type(command) ~= "string" then
			return
		end
		if command == "coins" then
			PlayerData.addCoins(player, 5000)
			notify(player, "Studio test grant: +5,000 coins")
		elseif command == "level10" then
			PlayerData.setLevelForStudio(player, 10)
			notify(player, "Studio test level set to 10")
		elseif command == "rag" then
			if not PlayerData.grantFoundRag(player) then
				PlayerData.grantTool(player, "tool_old_rag", true)
			end
			notify(player, "Studio test rag granted")
		elseif command == "tokens" then
			PlayerData.addEventTokens(player, 50)
			notify(player, "Studio test grant: +50 event tokens")
		elseif command == "reset_profile" then
			PlayerData.resetForStudio(player)
			notify(player, "Studio test profile reset")
		end
	end)
end

return DevelopmentSystem
