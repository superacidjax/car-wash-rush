--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractionRules = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Domain"):WaitForChild("InteractionRules")
)

local SecurePrompt = {}

local function promptPosition(prompt: ProximityPrompt): Vector3?
	local parent = prompt.Parent
	if parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	elseif parent and parent:IsA("BasePart") then
		return parent.Position
	end
	return nil
end

local function isNear(player: Player, prompt: ProximityPrompt, maxDistance: number): boolean
	local position = promptPosition(prompt)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return position ~= nil
		and root ~= nil
		and root:IsA("BasePart")
		and (root.Position - position).Magnitude <= maxDistance
end

function SecurePrompt.bind(
	prompt: ProximityPrompt,
	requiredSeconds: number,
	callback: (Player) -> (),
	canBegin: ((Player) -> boolean)?
): () -> ()
	local startedAt: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
	local connections: { RBXScriptConnection } = {}

	table.insert(
		connections,
		prompt.PromptButtonHoldBegan:Connect(function(player)
			if
				prompt.Enabled
				and isNear(player, prompt, prompt.MaxActivationDistance + 2)
				and (not canBegin or canBegin(player))
			then
				startedAt[player] = os.clock()
			end
		end)
	)
	table.insert(
		connections,
		prompt.PromptButtonHoldEnded:Connect(function(player)
			local started = startedAt[player]
			task.delay(0.5, function()
				if startedAt[player] == started then
					startedAt[player] = nil
				end
			end)
		end)
	)
	table.insert(
		connections,
		prompt.Triggered:Connect(function(player)
			local started = startedAt[player]
			startedAt[player] = nil
			if
				prompt.Enabled
				and isNear(player, prompt, prompt.MaxActivationDistance + 2)
				and (not canBegin or canBegin(player))
				and InteractionRules.hasCompletedHold(started, os.clock(), requiredSeconds, 0.15)
			then
				callback(player)
			end
		end)
	)
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(startedAt)
	end
end

return SecurePrompt
