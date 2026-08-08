local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local MovementSystem = {}

local function configureCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.WalkSpeed = Config.Player.WalkSpeed
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(configureCharacter)
	if player.Character then
		task.defer(configureCharacter, player.Character)
	end
end

function MovementSystem.start()
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Remotes.get("SprintChanged").OnServerEvent:Connect(function(player, sprinting)
		if type(sprinting) ~= "boolean" then
			return
		end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = if sprinting
				then Config.Player.WalkSpeed * Config.Player.SprintMultiplier
				else Config.Player.WalkSpeed
		end
	end)
end

return MovementSystem
