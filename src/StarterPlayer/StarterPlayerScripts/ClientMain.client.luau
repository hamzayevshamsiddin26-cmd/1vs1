--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Script: StarterPlayerScripts.ClientMain
	Description: Main client entry point. Initializes MainMenuUI, HUDController, and
	FPSController, and wires all client-side RemoteEvent listeners.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local MainMenuUI = require(script.Parent:WaitForChild("MainMenuUI"))
local HUDController = require(script.Parent:WaitForChild("HUDController"))
local FPSController = require(script.Parent:WaitForChild("FPSController"))

-- Disable default Roblox CoreGui backpack & health bar for clean competitive FPS UI
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Initialize Controllers
HUDController.Init()
MainMenuUI.Init()
FPSController.Init()

MainMenuUI.OnSettingsChanged = function(settings: any)
	FPSController.ApplySettings(settings)
end

-- Connect Server -> Client RemoteEvents
local matchStateRemote = Remotes:WaitForChild("MatchStateUpdate") :: RemoteEvent
matchStateRemote.OnClientEvent:Connect(function(snapshot: any)
	if type(snapshot) == "table" then
		MainMenuUI.SetVisible(false)
		HUDController.SetVisible(true)
		FPSController.SetMatchActive(true)
		HUDController.UpdateMatchSnapshot(snapshot)
	else
		-- Returned to Main Menu
		FPSController.SetMatchActive(false)
		HUDController.SetVisible(false)
		MainMenuUI.SetVisible(true)
	end
end)

local arenaRotationRemote = Remotes:WaitForChild("ArenaRotationUpdate") :: RemoteEvent
arenaRotationRemote.OnClientEvent:Connect(function(payload: any)
	if type(payload) == "table" then
		HUDController.PlayArenaRotationAnimation(payload)
	end
end)

local weaponStateRemote = Remotes:WaitForChild("WeaponStateUpdate") :: RemoteEvent
weaponStateRemote.OnClientEvent:Connect(function(state: any)
	FPSController.UpdateWeaponStateFromServer(state)
end)

local weaponFiredRemote = Remotes:WaitForChild("WeaponFiredVisual") :: RemoteEvent
weaponFiredRemote.OnClientEvent:Connect(function(
	shooter: Player?,
	weaponId: string,
	origin: Vector3,
	endpoints: { Vector3 },
	hitEffects: any,
	neonColor: Color3
)
	FPSController.RenderWeaponFiredVisual(shooter, weaponId, origin, endpoints, hitEffects, neonColor)
end)

local damageRemote = Remotes:WaitForChild("DamageIndicator") :: RemoteEvent
damageRemote.OnClientEvent:Connect(function(info: any)
	HUDController.ShowDamageIndicator(info)
end)

local killFeedRemote = Remotes:WaitForChild("KillFeedEvent") :: RemoteEvent
killFeedRemote.OnClientEvent:Connect(function(killData: any)
	HUDController.PushKillFeed(killData)
end)

local matchEndedRemote = Remotes:WaitForChild("MatchEndedEvent") :: RemoteEvent
matchEndedRemote.OnClientEvent:Connect(function(summary: any)
	HUDController.ShowMatchEnded(summary)
end)

local playerDataRemote = Remotes:WaitForChild("PlayerDataUpdate") :: RemoteEvent
playerDataRemote.OnClientEvent:Connect(function(profile: any, leaderboard: any)
	MainMenuUI.UpdateProfileData(profile, leaderboard)
	if type(profile) == "table" and type(profile.EquippedWeaponSkin) == "string" then
		FPSController.SetEquippedSkin(profile.EquippedWeaponSkin)
	end
end)

local menuNotifRemote = Remotes:WaitForChild("MenuNotification") :: RemoteEvent
menuNotifRemote.OnClientEvent:Connect(function(notifType: string, payload: any)
	MainMenuUI.HandleNotification(notifType, if type(payload) == "table" then payload else {})
end)

