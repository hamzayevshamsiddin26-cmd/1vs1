--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ServerScriptService.MatchManager
	Description: Server-authoritative 1v1 matchmaking, Friend Challenges, Private Matches,
	Practice Mode (Training Dummy), 100 HP combat loop, and the mandatory 120-second
	(2-minute) seamless Arena Rotation system that preserves both players' HP.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ArenaConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ArenaConfig"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local ShopServer = require(script.Parent:WaitForChild("ShopServer"))

local MatchManager = {}

export type MatchSession = {
	MatchId: string,
	Mode: "Quick1v1" | "FriendMatch" | "PrivateMatch" | "PracticeMode",
	Player1: Player,
	Player2: Player?, -- nil in PracticeMode (uses DummyModel instead)
	DummyModel: Model?,
	DummyCombatEnabled: boolean,
	DummyNextFireClock: number,
	P1Kills: number,
	P2Kills: number,
	WinCondition: number,
	CurrentArenaIndex: number,
	ArenaTimeRemaining: number, -- Counts down from 120s (2 minutes)
	IsRotatingArena: boolean,
	IsEnded: boolean,
}

export type PrivateRoom = {
	RoomCode: string,
	Host: Player,
	WinCondition: number,
	StartArenaIndex: number,
}

local ActiveMatches: { [string]: MatchSession } = {}
local PlayerToMatch: { [Player]: MatchSession } = {}
local QuickQueue: { Player } = {}
local PrivateRooms: { [string]: PrivateRoom } = {}
local PendingFriendChallenges: { [Player]: Player } = {} -- [TargetPlayer] = ChallengerPlayer

local matchCounter = 0

local function getRemotes(): Folder
	return ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local function getCharacterHealth(char: Model?): number
	if not char then
		return 0
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return 0
	end
	return math.clamp(math.ceil(hum.Health), 0, 100)
end

local function buildMatchSnapshot(match: MatchSession)
	local arenaDef = ArenaConfig.GetArenaByIndex(match.CurrentArenaIndex)
	local p1Health = getCharacterHealth(match.Player1.Character)
	local p2Health = if match.Player2
		then getCharacterHealth(match.Player2.Character)
		else getCharacterHealth(match.DummyModel)
	local p2Name = if match.Player2 then match.Player2.Name else "CYBER BOT [MK-IV]"

	return {
		MatchId = match.MatchId,
		Mode = match.Mode,
		P1Name = match.Player1.Name,
		P2Name = p2Name,
		P1Kills = match.P1Kills,
		P2Kills = match.P2Kills,
		P1Health = p1Health,
		P1MaxHealth = 100,
		P2Health = p2Health,
		P2MaxHealth = 100,
		WinCondition = match.WinCondition,
		ArenaIndex = match.CurrentArenaIndex,
		ArenaId = arenaDef.Id,
		ArenaName = arenaDef.Name,
		ArenaSubtitle = arenaDef.Subtitle,
		ArenaTimeRemaining = math.ceil(match.ArenaTimeRemaining),
		ArenaDuration = ArenaConfig.ROTATION_INTERVAL, -- 120 seconds
		IsEnded = match.IsEnded,
	}
end

function MatchManager.BroadcastMatchState(match: MatchSession)
	local remotes = getRemotes()
	local stateRemote = remotes:FindFirstChild("MatchStateUpdate") :: RemoteEvent?
	if not stateRemote then
		return
	end

	local snapshot = buildMatchSnapshot(match)
	stateRemote:FireClient(match.Player1, snapshot)
	if match.Player2 then
		stateRemote:FireClient(match.Player2, snapshot)
	end
end

local function spawnOrTeleportCharacter(
	player: Player,
	targetCFrame: CFrame,
	preserveCurrentHealth: boolean,
	savedHealth: number?
)
	local char = player.Character
	if not char or not char:FindFirstChildOfClass("Humanoid") or (char:FindFirstChildOfClass("Humanoid") :: Humanoid).Health <= 0 then
		player:LoadCharacter()
		char = player.Character or player.CharacterAdded:Wait()
	end

	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	local root = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?

	if hum then
		hum.MaxHealth = 100
		if preserveCurrentHealth and savedHealth and savedHealth > 0 then
			-- CRITICAL: Keep exact player HP during 120-second arena rotation
			hum.Health = math.clamp(savedHealth, 1, 100)
		else
			hum.Health = 100
		end
		hum.WalkSpeed = 19
		hum.JumpPower = 52
	end

	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		char:PivotTo(targetCFrame)
	end

	ShopServer.ApplyCharacterSkin(player, char)

	if not preserveCurrentHealth then
		CombatServer.ResetLoadout(player)
	else
		CombatServer.AttachThirdPersonWeapon(player)
		CombatServer.SyncWeaponState(player)
	end
end

local function createTrainingDummy(spawnCFrame: CFrame, preserveHealth: number?): Model
	local dummy = Instance.new("Model")
	dummy.Name = "CYBER BOT [MK-IV]"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.CFrame = spawnCFrame
	root.Parent = dummy
	dummy.PrimaryPart = root

	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(24, 18, 36)
	torso.Material = Enum.Material.Metal
	torso.CanCollide = true
	torso.CFrame = spawnCFrame
	torso.Parent = dummy

	local weldTorso = Instance.new("WeldConstraint")
	weldTorso.Part0 = root
	weldTorso.Part1 = torso
	weldTorso.Parent = torso

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.25, 1.25, 1.25)
	head.Color = Color3.fromRGB(20, 22, 32)
	head.Material = Enum.Material.Metal
	head.CanCollide = true
	head.CFrame = spawnCFrame * CFrame.new(0, 1.65, 0)
	head.Parent = dummy

	local weldHead = Instance.new("WeldConstraint")
	weldHead.Part0 = root
	weldHead.Part1 = head
	weldHead.Parent = head

	local visor = Instance.new("Part")
	visor.Name = "CyberArmor_Visor"
	visor.Size = Vector3.new(1.28, 0.36, 0.65)
	visor.Color = Color3.fromRGB(255, 40, 175)
	visor.Material = Enum.Material.Neon
	visor.CanCollide = false
	visor.CFrame = head.CFrame * CFrame.new(0, 0.1, -0.35)
	visor.Parent = dummy

	local weldVisor = Instance.new("WeldConstraint")
	weldVisor.Part0 = head
	weldVisor.Part1 = visor
	weldVisor.Parent = visor

	local core = Instance.new("Part")
	core.Name = "CyberArmor_ChestCore"
	core.Size = Vector3.new(0.9, 0.9, 0.25)
	core.Color = Color3.fromRGB(0, 240, 255)
	core.Material = Enum.Material.Neon
	core.CanCollide = false
	core.CFrame = torso.CFrame * CFrame.new(0, 0.2, -0.45) * CFrame.Angles(0, 0, math.rad(45))
	core.Parent = dummy

	local weldCore = Instance.new("WeldConstraint")
	weldCore.Part0 = torso
	weldCore.Part1 = core
	weldCore.Parent = core

	-- Limbs
	local limbOffsets = {
		{ Name = "LeftArm", Offset = CFrame.new(-1.5, 0, 0), Size = Vector3.new(1, 2, 1) },
		{ Name = "RightArm", Offset = CFrame.new(1.5, 0, 0), Size = Vector3.new(1, 2, 1) },
		{ Name = "LeftLeg", Offset = CFrame.new(-0.55, -2, 0), Size = Vector3.new(1, 2, 1) },
		{ Name = "RightLeg", Offset = CFrame.new(0.55, -2, 0), Size = Vector3.new(1, 2, 1) },
	}
	for _, limbInfo in ipairs(limbOffsets) do
		local limb = Instance.new("Part")
		limb.Name = limbInfo.Name
		limb.Size = limbInfo.Size
		limb.Color = Color3.fromRGB(18, 22, 34)
		limb.Material = Enum.Material.Metal
		limb.CanCollide = false
		limb.CFrame = spawnCFrame * limbInfo.Offset
		limb.Parent = dummy

		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = limb
		w.Parent = limb
	end

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 100
	hum.Health = if preserveHealth and preserveHealth > 0 then math.clamp(preserveHealth, 1, 100) else 100
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.Parent = dummy

	dummy.Parent = Workspace
	return dummy
end

--[[
	IMPORTANT ARENA ROTATION LOGIC:
	Triggered every 120 seconds (2 minutes).
	Switches to the next unique arena smoothly while keeping both players' exact HP!
]]
local function rotateMatchArena(match: MatchSession)
	if match.IsEnded or match.IsRotatingArena then
		return
	end
	match.IsRotatingArena = true

	-- Record both players' exact current HP BEFORE switching arenas
	local p1SavedHP = getCharacterHealth(match.Player1.Character)
	if p1SavedHP <= 0 then
		p1SavedHP = 100
	end

	local p2SavedHP = 100
	if match.Player2 then
		p2SavedHP = getCharacterHealth(match.Player2.Character)
		if p2SavedHP <= 0 then
			p2SavedHP = 100
		end
	elseif match.DummyModel then
		p2SavedHP = getCharacterHealth(match.DummyModel)
		if p2SavedHP <= 0 then
			p2SavedHP = 100
		end
	end

	local nextArenaIndex = ArenaConfig.GetNextArenaIndex(match.CurrentArenaIndex)
	local nextArenaDef = ArenaConfig.GetArenaByIndex(nextArenaIndex)

	match.CurrentArenaIndex = nextArenaIndex
	match.ArenaTimeRemaining = ArenaConfig.ROTATION_INTERVAL -- Reset to 120 seconds

	-- Notify clients to play smooth ARENA CHANGING animation
	local remotes = getRemotes()
	local rotationRemote = remotes:FindFirstChild("ArenaRotationUpdate") :: RemoteEvent?
	if rotationRemote then
		local payload = {
			NewArenaIndex = nextArenaIndex,
			NewArenaId = nextArenaDef.Id,
			NewArenaName = nextArenaDef.Name,
			NewArenaSubtitle = nextArenaDef.Subtitle,
			Duration = ArenaConfig.ROTATION_INTERVAL,
			P1PreservedHP = p1SavedHP,
			P2PreservedHP = p2SavedHP,
		}
		rotationRemote:FireClient(match.Player1, payload)
		if match.Player2 then
			rotationRemote:FireClient(match.Player2, payload)
		end
	end

	-- Teleport both players mid-transition and preserve their exact HP
	task.delay(0.45, function()
		if match.IsEnded then
			return
		end

		local spawn1, spawn2 = ArenaBuilder.GetSpawnCFrames(nextArenaIndex)
		spawnOrTeleportCharacter(match.Player1, spawn1, true, p1SavedHP)

		if match.Player2 then
			spawnOrTeleportCharacter(match.Player2, spawn2, true, p2SavedHP)
		elseif match.DummyModel then
			match.DummyModel:Destroy()
			match.DummyModel = createTrainingDummy(spawn2, p2SavedHP)
		end

		match.IsRotatingArena = false
		MatchManager.BroadcastMatchState(match)
	end)
end

function MatchManager.StartMatch(
	player1: Player,
	player2: Player?,
	mode: "Quick1v1" | "FriendMatch" | "PrivateMatch" | "PracticeMode",
	winCondition: number?,
	startArenaIndex: number?,
	dummyCombatEnabled: boolean?
): MatchSession
	-- Clean up any previous match for these players
	if PlayerToMatch[player1] then
		MatchManager.LeaveMatch(player1)
	end
	if player2 and PlayerToMatch[player2] then
		MatchManager.LeaveMatch(player2)
	end

	matchCounter += 1
	local matchId = "Match_" .. tostring(matchCounter) .. "_" .. tostring(math.floor(os.clock()))
	local arenaIdx = startArenaIndex or math.random(1, #ArenaConfig.Arenas)
	local targetWins = math.clamp(winCondition or ArenaConfig.DEFAULT_WIN_KILLS, 3, 30)

	local spawn1, spawn2 = ArenaBuilder.GetSpawnCFrames(arenaIdx)
	local dummyModel: Model? = nil
	if not player2 then
		dummyModel = createTrainingDummy(spawn2, 100)
	end

	local session: MatchSession = {
		MatchId = matchId,
		Mode = mode,
		Player1 = player1,
		Player2 = player2,
		DummyModel = dummyModel,
		DummyCombatEnabled = if dummyCombatEnabled ~= nil then dummyCombatEnabled else true,
		DummyNextFireClock = os.clock() + 2.5,
		P1Kills = 0,
		P2Kills = 0,
		WinCondition = targetWins,
		CurrentArenaIndex = arenaIdx,
		ArenaTimeRemaining = ArenaConfig.ROTATION_INTERVAL, -- 120 seconds (2 minutes)
		IsRotatingArena = false,
		IsEnded = false,
	}

	ActiveMatches[matchId] = session
	PlayerToMatch[player1] = session
	if player2 then
		PlayerToMatch[player2] = session
	end

	spawnOrTeleportCharacter(player1, spawn1, false, 100)
	if player2 then
		spawnOrTeleportCharacter(player2, spawn2, false, 100)
	end

	MatchManager.BroadcastMatchState(session)
	return session
end

function MatchManager.EndMatch(match: MatchSession, winnerName: string, winnerPlayer: Player?)
	if match.IsEnded then
		return
	end
	match.IsEnded = true

	-- Award progression stats & Coins/XP
	if match.Mode ~= "PracticeMode" then
		if winnerPlayer == match.Player1 then
			DataManager.RecordMatchOutcome(match.Player1, true)
			if match.Player2 then
				DataManager.RecordMatchOutcome(match.Player2, false)
			end
		elseif match.Player2 and winnerPlayer == match.Player2 then
			DataManager.RecordMatchOutcome(match.Player2, true)
			DataManager.RecordMatchOutcome(match.Player1, false)
		end
	else
		-- Practice mode completion reward
		DataManager.AddCoins(match.Player1, 50)
		DataManager.AddXP(match.Player1, 75)
	end

	local remotes = getRemotes()
	local endRemote = remotes:FindFirstChild("MatchEndedEvent") :: RemoteEvent?
	if endRemote then
		local summary = {
			MatchId = match.MatchId,
			Mode = match.Mode,
			WinnerName = winnerName,
			P1Name = match.Player1.Name,
			P2Name = if match.Player2 then match.Player2.Name else "CYBER BOT [MK-IV]",
			P1Kills = match.P1Kills,
			P2Kills = match.P2Kills,
			WinCondition = match.WinCondition,
		}
		endRemote:FireClient(match.Player1, summary)
		if match.Player2 then
			endRemote:FireClient(match.Player2, summary)
		end
	end

	task.delay(4.5, function()
		MatchManager.CleanupMatch(match)
	end)
end

function MatchManager.CleanupMatch(match: MatchSession)
	ActiveMatches[match.MatchId] = nil

	if match.DummyModel then
		match.DummyModel:Destroy()
		match.DummyModel = nil
	end

	local function returnToMenu(plr: Player?)
		if not plr then
			return
		end
		if PlayerToMatch[plr] == match then
			PlayerToMatch[plr] = nil
		end
		if plr.Parent == Players then
			local char = plr.Character
			if char then
				char:PivotTo(CFrame.new(0, 505, 0))
			end
			local remotes = getRemotes()
			local stateRemote = remotes:FindFirstChild("MatchStateUpdate") :: RemoteEvent?
			if stateRemote then
				stateRemote:FireClient(plr, nil)
			end
		end
	end

	returnToMenu(match.Player1)
	returnToMenu(match.Player2)
end

function MatchManager.LeaveMatch(player: Player)
	-- Remove from queue if queued
	for i = #QuickQueue, 1, -1 do
		if QuickQueue[i] == player then
			table.remove(QuickQueue, i)
		end
	end

	-- Remove any hosted private room
	for code, room in pairs(PrivateRooms) do
		if room.Host == player then
			PrivateRooms[code] = nil
		end
	end

	local match = PlayerToMatch[player]
	if not match then
		return
	end

	if not match.IsEnded then
		if match.Player2 then
			local otherPlayer = if match.Player1 == player then match.Player2 else match.Player1
			if otherPlayer then
				MatchManager.EndMatch(match, otherPlayer.Name, otherPlayer)
				return
			end
		end
	end

	MatchManager.CleanupMatch(match)
end

-- ============================================================================
-- COMBAT DAMAGE & KILL VALIDATION HOOKS
-- ============================================================================
CombatServer.CanPlayerAttack = function(player: Player): boolean
	local match = PlayerToMatch[player]
	if not match or match.IsEnded or match.IsRotatingArena then
		return false
	end
	return true
end

CombatServer.OnValidatedHit = function(
	attacker: Player,
	victimModel: Model,
	damage: number,
	isHeadshot: boolean,
	weaponId: string,
	hitPosition: Vector3
)
	local match = PlayerToMatch[attacker]
	if not match or match.IsEnded or match.IsRotatingArena then
		return
	end

	-- Verify victim belongs to this match
	local victimPlayer = Players:GetPlayerFromCharacter(victimModel)
	local isDummyVictim = (match.DummyModel ~= nil and victimModel == match.DummyModel)

	if victimPlayer then
		if victimPlayer ~= match.Player1 and victimPlayer ~= match.Player2 then
			return
		end
		if victimPlayer == attacker then
			return
		end
	elseif not isDummyVictim then
		return
	end

	local hum = victimModel:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	local newHealth = math.max(0, hum.Health - damage)
	hum.Health = newHealth

	-- Send floating damage & hitmarker confirmation to attacker and victim
	local remotes = getRemotes()
	local dmgRemote = remotes:FindFirstChild("DamageIndicator") :: RemoteEvent?
	if dmgRemote then
		dmgRemote:FireClient(attacker, {
			Type = "Dealt",
			Damage = damage,
			IsHeadshot = isHeadshot,
			HitPosition = hitPosition,
			VictimRemainingHP = math.ceil(newHealth),
		})
		if victimPlayer then
			dmgRemote:FireClient(victimPlayer, {
				Type = "Taken",
				Damage = damage,
				IsHeadshot = isHeadshot,
				AttackerName = attacker.Name,
			})
		end
	end

	MatchManager.BroadcastMatchState(match)

	-- Handle Elimination & Win Condition
	if newHealth <= 0 then
		if attacker == match.Player1 then
			match.P1Kills += 1
		else
			match.P2Kills += 1
		end

		DataManager.RecordKill(attacker)
		if victimPlayer then
			DataManager.RecordDeath(victimPlayer)
		end

		local weaponStats = WeaponConfig.GetWeapon(weaponId)
		local weaponDisplayName = if weaponStats then weaponStats.Name else weaponId
		local victimName = if victimPlayer then victimPlayer.Name else "CYBER BOT [MK-IV]"

		local killRemote = remotes:FindFirstChild("KillFeedEvent") :: RemoteEvent?
		if killRemote then
			local killPayload = {
				Killer = attacker.Name,
				Victim = victimName,
				Weapon = weaponDisplayName,
				IsHeadshot = isHeadshot,
				P1Kills = match.P1Kills,
				P2Kills = match.P2Kills,
			}
			killRemote:FireClient(match.Player1, killPayload)
			if match.Player2 then
				killRemote:FireClient(match.Player2, killPayload)
			end
		end

		MatchManager.BroadcastMatchState(match)

		-- Check if attacker reached the configured Win Condition
		if match.P1Kills >= match.WinCondition then
			MatchManager.EndMatch(match, match.Player1.Name, match.Player1)
			return
		elseif match.P2Kills >= match.WinCondition then
			local p2Name = if match.Player2 then match.Player2.Name else "CYBER BOT [MK-IV]"
			MatchManager.EndMatch(match, p2Name, match.Player2)
			return
		end

		-- Respawn eliminated player/dummy in current arena after 2.2 seconds
		task.delay(2.2, function()
			if match.IsEnded then
				return
			end
			local spawn1, spawn2 = ArenaBuilder.GetSpawnCFrames(match.CurrentArenaIndex)
			if victimPlayer == match.Player1 then
				spawnOrTeleportCharacter(match.Player1, spawn1, false, 100)
			elseif victimPlayer and victimPlayer == match.Player2 then
				spawnOrTeleportCharacter(victimPlayer, spawn2, false, 100)
			elseif isDummyVictim then
				if match.DummyModel then
					match.DummyModel:Destroy()
				end
				match.DummyModel = createTrainingDummy(spawn2, 100)
			end
			MatchManager.BroadcastMatchState(match)
		end)
	end
end

-- ============================================================================
-- QUEUE, FRIEND MATCH, PRIVATE ROOM, AND PRACTICE HANDLERS
-- ============================================================================
function MatchManager.HandleQueueAction(player: Player, action: string)
	local remotes = getRemotes()
	local notifyRemote = remotes:FindFirstChild("MenuNotification") :: RemoteEvent?

	if action == "JoinQueue" then
		if PlayerToMatch[player] then
			return
		end
		for _, queuedPlr in ipairs(QuickQueue) do
			if queuedPlr == player then
				return
			end
		end
		table.insert(QuickQueue, player)

		if #QuickQueue >= 2 then
			local p1 = table.remove(QuickQueue, 1) :: Player
			local p2 = table.remove(QuickQueue, 1) :: Player
			if p1 and p2 and p1.Parent == Players and p2.Parent == Players then
				MatchManager.StartMatch(p1, p2, "Quick1v1", ArenaConfig.DEFAULT_WIN_KILLS)
				return
			end
		end

		if notifyRemote then
			notifyRemote:FireClient(player, "QueueStatus", {
				InQueue = true,
				QueueCount = #QuickQueue,
				Message = "SEARCHING FOR 1VS1 OPPONENT... (OR CLICK SOLO CYBER DUEL)",
			})
		end
	elseif action == "LeaveQueue" then
		for i = #QuickQueue, 1, -1 do
			if QuickQueue[i] == player then
				table.remove(QuickQueue, i)
			end
		end
		if notifyRemote then
			notifyRemote:FireClient(player, "QueueStatus", {
				InQueue = false,
				QueueCount = #QuickQueue,
				Message = "QUEUE CANCELLED",
			})
		end
	elseif action == "LeaveMatch" then
		MatchManager.LeaveMatch(player)
	end
end

function MatchManager.HandlePracticeAction(
	player: Player,
	winCondition: number?,
	startArenaIndex: number?,
	botFiresBack: boolean?
)
	MatchManager.StartMatch(
		player,
		nil,
		"PracticeMode",
		winCondition or 10,
		startArenaIndex or 1,
		if botFiresBack ~= nil then botFiresBack else true
	)
end

function MatchManager.HandleFriendAndPrivateAction(player: Player, action: string, data: { [string]: any }?)
	local remotes = getRemotes()
	local notifyRemote = remotes:FindFirstChild("MenuNotification") :: RemoteEvent?
	local payload = data or {}

	if action == "CreatePrivateRoom" then
		local code = "NEON" .. tostring(math.random(10, 99))
		local winCond = math.clamp(tonumber(payload.WinCondition) or 10, 5, 25)
		local startArena = math.clamp(tonumber(payload.ArenaIndex) or 1, 1, #ArenaConfig.Arenas)
		PrivateRooms[code] = {
			RoomCode = code,
			Host = player,
			WinCondition = winCond,
			StartArenaIndex = startArena,
		}
		if notifyRemote then
			notifyRemote:FireClient(player, "PrivateRoomCreated", {
				RoomCode = code,
				WinCondition = winCond,
				ArenaIndex = startArena,
			})
		end
	elseif action == "JoinPrivateRoom" then
		local code = string.upper(tostring(payload.RoomCode or ""))
		local room = PrivateRooms[code]
		if not room or not room.Host or room.Host.Parent ~= Players then
			if notifyRemote then
				notifyRemote:FireClient(player, "Error", { Message = "ROOM CODE NOT FOUND: " .. code })
			end
			return
		end
		if room.Host == player then
			-- Allow host to launch immediately into the room against Cyber Bot if testing solo
			PrivateRooms[code] = nil
			MatchManager.StartMatch(player, nil, "PrivateMatch", room.WinCondition, room.StartArenaIndex, true)
			return
		end
		local host = room.Host
		PrivateRooms[code] = nil
		MatchManager.StartMatch(host, player, "PrivateMatch", room.WinCondition, room.StartArenaIndex)
	elseif action == "ChallengePlayer" then
		local targetName = tostring(payload.TargetName or "")
		local targetPlayer = Players:FindFirstChild(targetName) :: Player?
		if not targetPlayer or targetPlayer == player then
			if notifyRemote then
				notifyRemote:FireClient(player, "Error", { Message = "PLAYER UNAVAILABLE FOR DUEL" })
			end
			return
		end
		PendingFriendChallenges[targetPlayer] = player
		if notifyRemote then
			notifyRemote:FireClient(targetPlayer, "IncomingChallenge", {
				ChallengerName = player.Name,
			})
			notifyRemote:FireClient(player, "Info", {
				Message = "CHALLENGE SENT TO " .. targetPlayer.Name,
			})
		end
	elseif action == "AcceptChallenge" then
		local challenger = PendingFriendChallenges[player]
		PendingFriendChallenges[player] = nil
		if challenger and challenger.Parent == Players then
			MatchManager.StartMatch(challenger, player, "FriendMatch", ArenaConfig.DEFAULT_WIN_KILLS, 1)
		end
	end
end

-- ============================================================================
-- MASTER 1-SECOND & HEARTBEAT LOOP (120s ARENA ROTATION & TRAINING DUMMY AI)
-- ============================================================================
function MatchManager.StartLoop()
	-- 1-second authoritative timer for 120-second Arena Rotation
	task.spawn(function()
		while true do
			task.wait(1)
			for _, match in pairs(ActiveMatches) do
				if not match.IsEnded and not match.IsRotatingArena then
					match.ArenaTimeRemaining = math.max(0, match.ArenaTimeRemaining - 1)
					if match.ArenaTimeRemaining <= 0 then
						rotateMatchArena(match)
					else
						MatchManager.BroadcastMatchState(match)
					end
				end
			end
		end
	end)

	-- Smooth Training Dummy movement & sparring loop (60Hz)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, match in pairs(ActiveMatches) do
			if not match.IsEnded and not match.IsRotatingArena and match.DummyModel then
				local dummy = match.DummyModel
				local dummyHum = dummy:FindFirstChildOfClass("Humanoid")
				local dummyRoot = dummy.PrimaryPart
				if dummyHum and dummyHum.Health > 0 and dummyRoot then
					local _, baseSpawn2 = ArenaBuilder.GetSpawnCFrames(match.CurrentArenaIndex)
					local strafeX = math.sin(now * 1.9) * 18
					local advanceZ = math.cos(now * 1.1) * 10
					local targetPos = baseSpawn2.Position + Vector3.new(strafeX, 0, advanceZ)

					local p1Char = match.Player1.Character
					local p1Root = if p1Char then p1Char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
					local lookTarget = if p1Root
						then Vector3.new(p1Root.Position.X, targetPos.Y, p1Root.Position.Z)
						else (targetPos + baseSpawn2.LookVector * 10)

					dummy:PivotTo(CFrame.lookAt(targetPos, lookTarget))

					-- Optional sparring fire from Cyber Bot so the player can test taking damage & health HUD
					if match.DummyCombatEnabled and p1Root and now >= match.DummyNextFireClock then
						match.DummyNextFireClock = now + 1.65
						local p1Hum = if p1Char then p1Char:FindFirstChildOfClass("Humanoid") else nil
						if p1Hum and p1Hum.Health > 0 then
							local botOrigin = targetPos + Vector3.new(0, 1.4, 0)
							local toPlayer = (p1Root.Position - botOrigin)
							if toPlayer.Magnitude < 160 then
								local rayParams = RaycastParams.new()
								rayParams.FilterType = Enum.RaycastFilterType.Exclude
								rayParams.FilterDescendantsInstances = { dummy }
								local res = Workspace:Raycast(botOrigin, toPlayer.Unit * 160, rayParams)
								if res and p1Char and res.Instance:IsDescendantOf(p1Char) then
									-- Deal light sparring damage (8 HP)
									local nextHP = math.max(0, p1Hum.Health - 8)
									p1Hum.Health = nextHP

									local remotes = getRemotes()
									local visualRemote = remotes:FindFirstChild("WeaponFiredVisual") :: RemoteEvent?
									if visualRemote then
										visualRemote:FireClient(
											match.Player1,
											nil,
											"SMG",
											botOrigin,
											{ res.Position },
											{ { Pos = res.Position, IsCharacter = true, IsHeadshot = false } },
											Color3.fromRGB(255, 45, 175)
										)
									end
									local dmgRemote = remotes:FindFirstChild("DamageIndicator") :: RemoteEvent?
									if dmgRemote then
										dmgRemote:FireClient(match.Player1, {
											Type = "Taken",
											Damage = 8,
											IsHeadshot = false,
											AttackerName = "CYBER BOT [MK-IV]",
										})
									end

									if nextHP <= 0 then
										match.P2Kills += 1
										DataManager.RecordDeath(match.Player1)
										if match.P2Kills >= match.WinCondition then
											MatchManager.EndMatch(match, "CYBER BOT [MK-IV]", nil)
										else
											task.delay(2.2, function()
												if not match.IsEnded then
													local s1, _ = ArenaBuilder.GetSpawnCFrames(match.CurrentArenaIndex)
													spawnOrTeleportCharacter(match.Player1, s1, false, 100)
													MatchManager.BroadcastMatchState(match)
												end
											end)
										end
									end
									MatchManager.BroadcastMatchState(match)
								end
							end
						end
					end
				end
			end
		end
	end)
end

return MatchManager

