local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Systems = script.Parent:WaitForChild("Systems")

local GreyboxStarterCorner = require(Systems:WaitForChild("GreyboxStarterCorner"))
local MovementSystem = require(Systems:WaitForChild("MovementSystem"))
local PlayerData = require(Systems:WaitForChild("PlayerData"))
local PrototypeGameplay = require(Systems:WaitForChild("PrototypeGameplay"))
local Remotes = require(Systems:WaitForChild("Remotes"))

Remotes.start(Config.RemotesFolderName)
PlayerData.start()

local greybox = nil
if Config.GenerateGreyboxOnStart then
	greybox = GreyboxStarterCorner.build()
else
	greybox = GreyboxStarterCorner.findExisting()
end

MovementSystem.start()
PrototypeGameplay.start(greybox)

print("[Car Wash Rush] Server loaded.")
