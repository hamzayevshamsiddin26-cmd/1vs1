--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ServerScriptService.DataManager
	Description: Handles DataStoreService persistence for player progression,
	Coins, XP, Level, Wins/Losses, Weapon/Character skins, Settings, and Leaderboards.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))

local DataManager = {}

export type PlayerProfile = {
	Coins: number,
	XP: number,
	Level: number,
	Wins: number,
	Losses: number,
	Kills: number,
	Deaths: number,
	WinStreak: number,
	OwnedWeaponSkins: { [string]: boolean },
	EquippedWeaponSkin: string,
	OwnedCharacterSkins: { [string]: boolean },
	EquippedCharacterSkin: string,
	Settings: {
		FOV: number,
		Sensitivity: number,
		AimSensitivity: number,
		SfxVolume: number,
		MusicVolume: number,
		HighQualityNeon: boolean,
	},
}

local DATASTORE_NAME = "NeonDuel_PlayerData_v2"
local LEADERBOARD_STORE_NAME = "NeonDuel_WinsLeaderboard_v2"

local playerStore: DataStore? = nil
local winsOrderedStore: OrderedDataStore? = nil

pcall(function()
	playerStore = DataStoreService:GetDataStore(DATASTORE_NAME)
	winsOrderedStore = DataStoreService:GetOrderedDataStore(LEADERBOARD_STORE_NAME)
end)

local Profiles: { [Player]: PlayerProfile } = {}
local CachedLeaderboard: { { Name: string, Wins: number, Level: number } } = {
	{ Name = "VORTEX_99", Wins = 48, Level = 19 },
	{ Name = "CYBER_VALKYRIE", Wins = 39, Level = 16 },
	{ Name = "KRYPTON_X", Wins = 31, Level = 14 },
	{ Name = "NEON_GHOST", Wins = 24, Level = 11 },
	{ Name = "SYNTH_ZERO", Wins = 18, Level = 9 },
}

local function getDefaultProfile(): PlayerProfile
	return {
		Coins = 350,
		XP = 0,
		Level = 1,
		Wins = 0,
		Losses = 0,
		Kills = 0,
		Deaths = 0,
		WinStreak = 0,
		OwnedWeaponSkins = {
			DefaultCyan = true,
		},
		EquippedWeaponSkin = "DefaultCyan",
		OwnedCharacterSkins = {
			CyberOperative = true,
		},
		EquippedCharacterSkin = "CyberOperative",
		Settings = {
			FOV = 78,
			Sensitivity = 0.5,
			AimSensitivity = 0.35,
			SfxVolume = 0.8,
			MusicVolume = 0.45,
			HighQualityNeon = true,
		},
	}
end

local function reconcileProfile(saved: any): PlayerProfile
	local defaultData = getDefaultProfile()
	if type(saved) ~= "table" then
		return defaultData
	end

	for key, val in pairs(defaultData) do
		if saved[key] == nil then
			saved[key] = val
		elseif type(val) == "table" and type(saved[key]) == "table" then
			for subKey, subVal in pairs(val) do
				if saved[key][subKey] == nil then
					saved[key][subKey] = subVal
				end
			end
		end
	end

	return saved :: PlayerProfile
end

local function syncLeaderstats(player: Player, profile: PlayerProfile)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local function setStat(name: string, value: number)
		local stat = leaderstats:FindFirstChild(name) :: IntValue?
		if not stat then
			stat = Instance.new("IntValue")
			stat.Name = name
			stat.Parent = leaderstats
		end
		if stat then
			stat.Value = value
		end
	end

	setStat("Level", profile.Level)
	setStat("Wins", profile.Wins)
	setStat("Kills", profile.Kills)
	setStat("Coins", profile.Coins)
end

function DataManager.LoadProfile(player: Player): PlayerProfile
	if Profiles[player] then
		return Profiles[player]
	end

	local loadedData: any = nil
	if playerStore and player.UserId > 0 then
		local ok, result = pcall(function()
			return (playerStore :: DataStore):GetAsync("Player_" .. tostring(player.UserId))
		end)
		if ok and result then
			loadedData = result
		end
	end

	local profile = reconcileProfile(loadedData)
	Profiles[player] = profile
	syncLeaderstats(player, profile)
	DataManager.SyncToClient(player)
	return profile
end

function DataManager.GetProfile(player: Player): PlayerProfile
	return Profiles[player] or DataManager.LoadProfile(player)
end

function DataManager.SaveProfile(player: Player)
	local profile = Profiles[player]
	if not profile then
		return
	end

	if playerStore and player.UserId > 0 and not RunService:IsStudio() then
		pcall(function()
			(playerStore :: DataStore):UpdateAsync("Player_" .. tostring(player.UserId), function()
				return profile
			end)
		end)
	elseif playerStore and player.UserId > 0 then
		-- Also attempt save in Studio if API services are enabled
		pcall(function()
			(playerStore :: DataStore):SetAsync("Player_" .. tostring(player.UserId), profile)
		end)
	end

	if winsOrderedStore and player.UserId > 0 and profile.Wins > 0 then
		pcall(function()
			(winsOrderedStore :: OrderedDataStore):SetAsync(player.Name, profile.Wins)
		end)
	end
end

function DataManager.SyncToClient(player: Player)
	local profile = Profiles[player]
	if not profile then
		return
	end
	syncLeaderstats(player, profile)

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local dataRemote = remotes:FindFirstChild("PlayerDataUpdate") :: RemoteEvent?
		if dataRemote then
			dataRemote:FireClient(player, profile, DataManager.GetLeaderboard())
		end
	end
end

function DataManager.AddCoins(player: Player, amount: number)
	local profile = DataManager.GetProfile(player)
	profile.Coins = math.max(0, profile.Coins + math.floor(amount))
	DataManager.SyncToClient(player)
end

function DataManager.AddXP(player: Player, amount: number): boolean
	local profile = DataManager.GetProfile(player)
	profile.XP += math.floor(amount)

	local leveledUp = false
	local required = ShopConfig.GetXPRequiredForLevel(profile.Level)
	while profile.XP >= required do
		profile.XP -= required
		profile.Level += 1
		profile.Coins += ShopConfig.Rewards.CoinsPerLevelUp
		leveledUp = true
		required = ShopConfig.GetXPRequiredForLevel(profile.Level)
	end

	DataManager.SyncToClient(player)
	return leveledUp
end

function DataManager.RecordKill(player: Player)
	local profile = DataManager.GetProfile(player)
	profile.Kills += 1
	profile.Coins += ShopConfig.Rewards.CoinsPerKill
	DataManager.AddXP(player, ShopConfig.Rewards.XPPerKill)
end

function DataManager.RecordDeath(player: Player)
	local profile = DataManager.GetProfile(player)
	profile.Deaths += 1
	DataManager.SyncToClient(player)
end

function DataManager.RecordMatchOutcome(player: Player, won: boolean)
	local profile = DataManager.GetProfile(player)
	if won then
		profile.Wins += 1
		profile.WinStreak += 1
		profile.Coins += ShopConfig.Rewards.CoinsPerWin
		DataManager.AddXP(player, ShopConfig.Rewards.XPPerWin)
	else
		profile.Losses += 1
		profile.WinStreak = 0
		profile.Coins += ShopConfig.Rewards.CoinsPerLoss
		DataManager.AddXP(player, ShopConfig.Rewards.XPPerLoss)
	end
	DataManager.SaveProfile(player)
end

function DataManager.UpdateSettings(player: Player, newSettings: { [string]: any })
	local profile = DataManager.GetProfile(player)
	if type(newSettings) ~= "table" then
		return
	end
	if type(newSettings.FOV) == "number" then
		profile.Settings.FOV = math.clamp(newSettings.FOV, 60, 105)
	end
	if type(newSettings.Sensitivity) == "number" then
		profile.Settings.Sensitivity = math.clamp(newSettings.Sensitivity, 0.1, 2.0)
	end
	if type(newSettings.AimSensitivity) == "number" then
		profile.Settings.AimSensitivity = math.clamp(newSettings.AimSensitivity, 0.1, 1.5)
	end
	if type(newSettings.SfxVolume) == "number" then
		profile.Settings.SfxVolume = math.clamp(newSettings.SfxVolume, 0, 1)
	end
	if type(newSettings.MusicVolume) == "number" then
		profile.Settings.MusicVolume = math.clamp(newSettings.MusicVolume, 0, 1)
	end
	if type(newSettings.HighQualityNeon) == "boolean" then
		profile.Settings.HighQualityNeon = newSettings.HighQualityNeon
	end
	DataManager.SyncToClient(player)
end

function DataManager.GetLeaderboard(): { { Name: string, Wins: number, Level: number } }
	local entries: { { Name: string, Wins: number, Level: number } } = {}
	local seenNames: { [string]: boolean } = {}

	-- Include all active players in server
	for _, plr in ipairs(Players:GetPlayers()) do
		local prof = Profiles[plr]
		if prof then
			table.insert(entries, {
				Name = plr.Name,
				Wins = prof.Wins,
				Level = prof.Level,
			})
			seenNames[plr.Name] = true
		end
	end

	-- Merge cached global entries
	for _, item in ipairs(CachedLeaderboard) do
		if not seenNames[item.Name] then
			table.insert(entries, item)
			seenNames[item.Name] = true
		end
	end

	table.sort(entries, function(a, b)
		if a.Wins == b.Wins then
			return a.Level > b.Level
		end
		return a.Wins > b.Wins
	end)

	local top10 = {}
	for i = 1, math.min(10, #entries) do
		table.insert(top10, entries[i])
	end
	return top10
end

function DataManager.RefreshGlobalLeaderboard()
	if not winsOrderedStore then
		return
	end
	pcall(function()
		local pages = (winsOrderedStore :: OrderedDataStore):GetSortedAsync(false, 10)
		local topPage = pages:GetCurrentPage()
		if #topPage > 0 then
			local updated = {}
			for _, entry in ipairs(topPage) do
				table.insert(updated, {
					Name = tostring(entry.key),
					Wins = tonumber(entry.value) or 0,
					Level = math.max(1, math.floor((tonumber(entry.value) or 0) / 2) + 1),
				})
			end
			CachedLeaderboard = updated
		end
	end)
end

function DataManager.CleanupPlayer(player: Player)
	DataManager.SaveProfile(player)
	Profiles[player] = nil
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataManager.SaveProfile(player)
	end
end)

return DataManager

