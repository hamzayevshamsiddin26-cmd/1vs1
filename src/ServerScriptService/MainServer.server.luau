--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Script: ServerScriptService.MainServer
	Description: Main server bootstrapper. Initializes RemoteEvents, builds the 5
	futuristic cyberpunk arenas, starts the 120-second arena rotation loop, and
	connects client-server network endpoints.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(script.Parent:WaitForChild("DataManager"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local MatchManager = require(script.Parent:WaitForChild("MatchManager"))
local ShopServer = require(script.Parent:WaitForChild("ShopServer"))

-- 1. Create RemoteEvents & RemoteFunctions in ReplicatedStorage.Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local remoteEventNames = {
	"FireWeapon",
	"ReloadWeapon",
	"SwitchWeapon",
	"AimState",
	"WeaponStateUpdate",
	"WeaponFiredVisual",
	"QueueAction",
	"PracticeAction",
	"FriendMatchAction",
	"UpdateSettings",
	"MatchStateUpdate",
	"ArenaRotationUpdate",
	"DamageIndicator",
	"KillFeedEvent",
	"MatchEndedEvent",
	"PlayerDataUpdate",
	"MenuNotification",
}

local Remotes: { [string]: RemoteEvent } = {}
for _, name in ipairs(remoteEventNames) do
	local ev = remotesFolder:FindFirstChild(name) :: RemoteEvent?
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = remotesFolder
	end
	Remotes[name] = ev :: RemoteEvent
end

local shopFunction = remotesFolder:FindFirstChild("ShopAction") :: RemoteFunction?
if not shopFunction then
	shopFunction = Instance.new("RemoteFunction")
	shopFunction.Name = "ShopAction"
	shopFunction.Parent = remotesFolder
end

-- 2. Build all 5 Futuristic Cyberpunk Arenas & Lighting
ArenaBuilder.BuildAllArenas()

-- 3. Start Match & 120-Second Arena Rotation Loop
MatchManager.StartLoop()

-- 4. Connect Combat Remotes
Remotes.FireWeapon.OnServerEvent:Connect(function(player: Player, origin: any, directions: any)
	CombatServer.HandleFireWeapon(player, origin, directions)
end)

Remotes.ReloadWeapon.OnServerEvent:Connect(function(player: Player)
	CombatServer.ReloadWeapon(player)
end)

Remotes.SwitchWeapon.OnServerEvent:Connect(function(player: Player, weaponId: any)
	if type(weaponId) == "string" then
		CombatServer.SwitchWeapon(player, weaponId)
	end
end)

Remotes.AimState.OnServerEvent:Connect(function(player: Player, isAiming: any)
	CombatServer.SetAimState(player, isAiming == true)
end)

-- 5. Connect Matchmaking, Friend Match, Private Room, and Practice Mode Remotes
Remotes.QueueAction.OnServerEvent:Connect(function(player: Player, action: any)
	if type(action) == "string" then
		MatchManager.HandleQueueAction(player, action)
	end
end)

Remotes.PracticeAction.OnServerEvent:Connect(function(
	player: Player,
	winCondition: any,
	startArenaIndex: any,
	botFiresBack: any
)
	MatchManager.HandlePracticeAction(
		player,
		tonumber(winCondition),
		tonumber(startArenaIndex),
		if type(botFiresBack) == "boolean" then botFiresBack else true
	)
end)

Remotes.FriendMatchAction.OnServerEvent:Connect(function(player: Player, action: any, payload: any)
	if type(action) == "string" then
		MatchManager.HandleFriendAndPrivateAction(player, action, if type(payload) == "table" then payload else nil)
	end
end)

-- 6. Connect Shop & Settings Remotes
if shopFunction then
	shopFunction.OnServerInvoke = function(player: Player, action: any, category: any, itemId: any)
		if type(action) == "string" and type(category) == "string" and type(itemId) == "string" then
			return ShopServer.HandleShopAction(player, action, category, itemId)
		end
		return false, "Invalid request parameters."
	end
end

Remotes.UpdateSettings.OnServerEvent:Connect(function(player: Player, newSettings: any)
	if type(newSettings) == "table" then
		DataManager.UpdateSettings(player, newSettings)
	end
end)

-- 7. Player Lifecycle Management
local function onPlayerAdded(player: Player)
	DataManager.LoadProfile(player)
	CombatServer.GetOrCreateState(player)

	player.CharacterAdded:Connect(function(character: Model)
		task.defer(function()
			ShopServer.ApplyCharacterSkin(player, character)
			CombatServer.AttachThirdPersonWeapon(player)
		end)
	end)

	-- Spawn in safe lobby box initially while viewing the Cybercity Main Menu
	player:LoadCharacter()
	if player.Character then
		player.Character:PivotTo(CFrame.new(0, 505, 0))
	end

	task.delay(0.5, function()
		if player.Parent == Players then
			DataManager.SyncToClient(player)
			CombatServer.SyncWeaponState(player)
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player: Player)
	MatchManager.LeaveMatch(player)
	CombatServer.CleanupPlayer(player)
	DataManager.CleanupPlayer(player)
end)

-- Periodically refresh global OrderedDataStore leaderboard
task.spawn(function()
	while true do
		DataManager.RefreshGlobalLeaderboard()
		task.wait(60)
	end
end)

