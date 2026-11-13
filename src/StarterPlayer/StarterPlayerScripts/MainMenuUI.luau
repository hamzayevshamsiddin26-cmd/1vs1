--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: StarterPlayerScripts.MainMenuUI
	Description: Implements the Cybercity Edition 2.0 (Image 1) Main Menu layout with
	translucent left sidebar, glowing NEON DUEL Edition 2.0 logo, purple highlight box
	with corner targeting brackets, bottom-right navigation prompts, and full interactive
	modals for PLAY 1VS1, FRIEND MATCH / PRIVATE / PRACTICE, SHOP, PLAYER PROFILE, and SETTINGS.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))
local ArenaConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ArenaConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local SoundManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundManager"))

local MainMenuUI = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MenuGui: ScreenGui? = nil
local RightModalContainer: Frame? = nil
local StatusBannerLabel: TextLabel? = nil
local TopProfileBadge: TextLabel? = nil

local CurrentProfile: any = {
	Coins = 350,
	XP = 0,
	Level = 1,
	Wins = 0,
	Losses = 0,
	Kills = 0,
	Deaths = 0,
	WinStreak = 0,
	OwnedWeaponSkins = { DefaultCyan = true },
	EquippedWeaponSkin = "DefaultCyan",
	OwnedCharacterSkins = { CyberOperative = true },
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
local CurrentLeaderboard: { { Name: string, Wins: number, Level: number } } = {}
local SelectedMenuIndex = 1
local ActivePanelName = "Play1v1"
local InQueue = false

MainMenuUI.OnSettingsChanged = nil :: ((settings: any) -> ())?

local function createCornerBrackets(parent: GuiObject): Frame
	local holder = Instance.new("Frame")
	holder.Name = "CornerBrackets"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local len = 10
	local thick = 2
	local color = Color3.fromRGB(235, 245, 255)

	local segments = {
		-- Top Left
		{ Pos = UDim2.new(0, -4, 0, -4), Size = UDim2.fromOffset(len, thick) },
		{ Pos = UDim2.new(0, -4, 0, -4), Size = UDim2.fromOffset(thick, len) },
		-- Top Right
		{ Pos = UDim2.new(1, -len + 4, 0, -4), Size = UDim2.fromOffset(len, thick) },
		{ Pos = UDim2.new(1, 2, 0, -4), Size = UDim2.fromOffset(thick, len) },
		-- Bottom Left
		{ Pos = UDim2.new(0, -4, 1, 2), Size = UDim2.fromOffset(len, thick) },
		{ Pos = UDim2.new(0, -4, 1, -len + 4), Size = UDim2.fromOffset(thick, len) },
		-- Bottom Right
		{ Pos = UDim2.new(1, -len + 4, 1, 2), Size = UDim2.fromOffset(len, thick) },
		{ Pos = UDim2.new(1, 2, 1, -len + 4), Size = UDim2.fromOffset(thick, len) },
	}

	for _, seg in ipairs(segments) do
		local bar = Instance.new("Frame")
		bar.Position = seg.Pos
		bar.Size = seg.Size
		bar.BackgroundColor3 = color
		bar.BorderSizePixel = 0
		bar.Parent = holder
	end

	return holder
end

local function makeCyberButton(
	parent: Instance,
	text: string,
	size: UDim2,
	pos: UDim2,
	accentColor: Color3,
	onClick: () -> ()
): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = Color3.fromRGB(22, 18, 42)
	btn.BackgroundTransparency = 0.2
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(240, 248, 255)
	btn.TextSize = 15
	btn.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 1.6
	stroke.Transparency = 0.15
	stroke.Parent = btn

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = btn

	btn.MouseEnter:Connect(function()
		SoundManager.Play2D("UIHover")
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = accentColor,
			TextColor3 = Color3.fromRGB(10, 12, 20),
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(22, 18, 42),
			TextColor3 = Color3.fromRGB(240, 248, 255),
		}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		SoundManager.Play2D("UIClick")
		onClick()
	end)

	return btn
end

local function clearModal()
	if not RightModalContainer then
		return
	end
	for _, child in ipairs(RightModalContainer:GetChildren()) do
		if not child:IsA("UIStroke") and not child:IsA("UICorner") then
			child:Destroy()
		end
	end
end

local function makeModalHeader(title: string, subtitle: string)
	if not RightModalContainer then
		return
	end
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, -36, 0, 58)
	header.Position = UDim2.fromOffset(18, 14)
	header.BackgroundTransparency = 1
	header.Parent = RightModalContainer

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, 0, 0, 30)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.Michroma
	titleLbl.Text = title
	titleLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
	titleLbl.TextSize = 22
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = header

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.new(1, 0, 0, 20)
	subLbl.Position = UDim2.fromOffset(0, 32)
	subLbl.BackgroundTransparency = 1
	subLbl.Font = Enum.Font.RobotoMono
	subLbl.Text = subtitle
	subLbl.TextColor3 = Color3.fromRGB(195, 140, 255)
	subLbl.TextSize = 13
	subLbl.TextXAlignment = Enum.TextXAlignment.Left
	subLbl.Parent = header

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 2)
	divider.Position = UDim2.fromOffset(0, 56)
	divider.BackgroundColor3 = Color3.fromRGB(165, 50, 255)
	divider.BorderSizePixel = 0
	divider.Parent = header
end

-- ============================================================================
-- MODAL 1: PLAY 1VS1 (Quick Matchmaking + Instant Cyber Duel)
-- ============================================================================
function MainMenuUI.RenderPlay1v1Modal()
	ActivePanelName = "Play1v1"
	clearModal()
	if not RightModalContainer then
		return
	end

	makeModalHeader(
		"COMPETITIVE 1VS1 DUEL",
		"2 PLAYERS // 100 HP // 5 WEAPON CLASSES // 120s ARENA ROTATION"
	)

	local infoBox = Instance.new("Frame")
	infoBox.Size = UDim2.new(1, -36, 0, 155)
	infoBox.Position = UDim2.fromOffset(18, 84)
	infoBox.BackgroundColor3 = Color3.fromRGB(14, 16, 30)
	infoBox.BackgroundTransparency = 0.25
	infoBox.BorderSizePixel = 0
	infoBox.Parent = RightModalContainer

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 225, 255)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.4
	stroke.Parent = infoBox

	local rulesText = Instance.new("TextLabel")
	rulesText.Size = UDim2.new(1, -24, 1, -20)
	rulesText.Position = UDim2.fromOffset(12, 10)
	rulesText.BackgroundTransparency = 1
	rulesText.Font = Enum.Font.RobotoMono
	rulesText.TextColor3 = Color3.fromRGB(220, 235, 255)
	rulesText.TextSize = 14
	rulesText.TextWrapped = true
	rulesText.TextXAlignment = Enum.TextXAlignment.Left
	rulesText.TextYAlignment = Enum.TextYAlignment.Top
	rulesText.Text = "• MATCH FORMAT: Strictly 1v1 First-Person Cyberpunk Duel (100 HP)\n"
		.. "• ARENA ROTATION: Switches across 5 Futuristic Arenas every 2 MINUTES (120s)\n"
		.. "• HP PERSISTENCE: Both players keep their exact HP during Arena Rotations\n"
		.. "• FULL ARSENAL: Assault Rifle [1], Sniper [2], Shotgun [3], SMG [4], Pistol [5]\n"
		.. "• WIN CONDITION: First player to reach 10 Kills wins (+150 Coins & +200 XP)"
	rulesText.Parent = infoBox

	-- Quick 1v1 Queue Button
	local queueBtnText = if InQueue then "CANCEL 1VS1 MATCHMAKING QUEUE" else "FIND 1VS1 MULTIPLAYER MATCH"
	local queueBtnColor = if InQueue then Color3.fromRGB(255, 50, 120) else Color3.fromRGB(0, 240, 255)

	makeCyberButton(
		RightModalContainer,
		queueBtnText,
		UDim2.new(1, -36, 0, 48),
		UDim2.fromOffset(18, 256),
		queueBtnColor,
		function()
			local qRemote = Remotes:FindFirstChild("QueueAction") :: RemoteEvent?
			if qRemote then
				InQueue = not InQueue
				qRemote:FireServer(if InQueue then "JoinQueue" else "LeaveQueue")
				MainMenuUI.RenderPlay1v1Modal()
			end
		end
	)

	-- Instant 1v1 vs Cyber Bot (so solo testers can jump into a full 1v1 duel immediately!)
	makeCyberButton(
		RightModalContainer,
		"INSTANT 1VS1 DUEL VS CYBER BOT [SOLO / PRACTICE]",
		UDim2.new(1, -36, 0, 46),
		UDim2.fromOffset(18, 316),
		Color3.fromRGB(215, 45, 255),
		function()
			local pRemote = Remotes:FindFirstChild("PracticeAction") :: RemoteEvent?
			if pRemote then
				pRemote:FireServer(10, 1, true)
			end
		end
	)

	-- Arena Preview Strip (All 5 Arenas)
	local arenaHeader = Instance.new("TextLabel")
	arenaHeader.Size = UDim2.new(1, -36, 0, 22)
	arenaHeader.Position = UDim2.fromOffset(18, 376)
	arenaHeader.BackgroundTransparency = 1
	arenaHeader.Font = Enum.Font.GothamBold
	arenaHeader.Text = "5 ROTATING ARENAS (SWITCHES EVERY 02:00 / 120 SECONDS):"
	arenaHeader.TextColor3 = Color3.fromRGB(0, 235, 255)
	arenaHeader.TextSize = 13
	arenaHeader.TextXAlignment = Enum.TextXAlignment.Left
	arenaHeader.Parent = RightModalContainer

	local listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(1, -36, 0, 88)
	listFrame.Position = UDim2.fromOffset(18, 402)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = RightModalContainer

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.32, 0, 0, 38)
	layout.CellPadding = UDim2.fromOffset(6, 6)
	layout.Parent = listFrame

	for i, arena in ipairs(ArenaConfig.Arenas) do
		makeCyberButton(
			listFrame,
			tostring(i) .. ". " .. arena.Name,
			UDim2.fromOffset(100, 36),
			UDim2.new(),
			arena.PrimaryNeon,
			function()
				local pRemote = Remotes:FindFirstChild("PracticeAction") :: RemoteEvent?
				if pRemote then
					pRemote:FireServer(10, arena.Index, true)
				end
			end
		)
	end
end

-- ============================================================================
-- MODAL 2: FRIEND MATCH, PRIVATE ROOM & TRAINING DUMMY
-- ============================================================================
function MainMenuUI.RenderFriendMatchModal()
	ActivePanelName = "FriendMatch"
	clearModal()
	if not RightModalContainer then
		return
	end

	makeModalHeader(
		"FRIEND MATCH // PRIVATE & PRACTICE",
		"CHALLENGE SERVER FRIENDS, HOST PRIVATE CODES, OR TRAIN VS DUMMY"
	)

	local selectedWinCondition = 10
	local selectedArenaIdx = 1

	-- Private Match Section
	local privLabel = Instance.new("TextLabel")
	privLabel.Size = UDim2.new(1, -36, 0, 22)
	privLabel.Position = UDim2.fromOffset(18, 80)
	privLabel.BackgroundTransparency = 1
	privLabel.Font = Enum.Font.GothamBold
	privLabel.Text = "PRIVATE MATCH CONFIGURATION:"
	privLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
	privLabel.TextSize = 14
	privLabel.TextXAlignment = Enum.TextXAlignment.Left
	privLabel.Parent = RightModalContainer

	local winBtn = nil :: TextButton?
	winBtn = makeCyberButton(
		RightModalContainer,
		"WIN CONDITION: 10 KILLS (CLICK TO CYCLE)",
		UDim2.new(0.48, -22, 0, 38),
		UDim2.fromOffset(18, 106),
		Color3.fromRGB(0, 235, 255),
		function()
			local options = { 5, 10, 15, 20 }
			local nextIdx = 1
			for idx, v in ipairs(options) do
				if v == selectedWinCondition then
					nextIdx = (idx % #options) + 1
					break
				end
			end
			selectedWinCondition = options[nextIdx]
			if winBtn then
				winBtn.Text = "WIN CONDITION: " .. tostring(selectedWinCondition) .. " KILLS"
			end
		end
	)

	local arenaBtn = nil :: TextButton?
	arenaBtn = makeCyberButton(
		RightModalContainer,
		"START ARENA: 1. CYBERCITY",
		UDim2.new(0.48, -22, 0, 38),
		UDim2.new(0.52, 4, 0, 106),
		Color3.fromRGB(195, 55, 255),
		function()
			selectedArenaIdx = (selectedArenaIdx % #ArenaConfig.Arenas) + 1
			local aDef = ArenaConfig.GetArenaByIndex(selectedArenaIdx)
			if arenaBtn then
				arenaBtn.Text = "START ARENA: " .. tostring(selectedArenaIdx) .. ". " .. string.sub(aDef.Name, 1, 12)
			end
		end
	)

	makeCyberButton(
		RightModalContainer,
		"CREATE PRIVATE MATCH ROOM CODE",
		UDim2.new(0.48, -22, 0, 40),
		UDim2.fromOffset(18, 154),
		Color3.fromRGB(255, 45, 175),
		function()
			local fmRemote = Remotes:FindFirstChild("FriendMatchAction") :: RemoteEvent?
			if fmRemote then
				fmRemote:FireServer("CreatePrivateRoom", {
					WinCondition = selectedWinCondition,
					ArenaIndex = selectedArenaIdx,
				})
			end
		end
	)

	-- Room Code Input + Join Button
	local codeInput = Instance.new("TextBox")
	codeInput.Size = UDim2.new(0.24, -12, 0, 40)
	codeInput.Position = UDim2.new(0.52, 4, 0, 154)
	codeInput.BackgroundColor3 = Color3.fromRGB(14, 16, 28)
	codeInput.BorderSizePixel = 0
	codeInput.Font = Enum.Font.RobotoMono
	codeInput.PlaceholderText = "CODE (NEON12)"
	codeInput.Text = ""
	codeInput.TextColor3 = Color3.fromRGB(0, 245, 255)
	codeInput.TextSize = 14
	codeInput.Parent = RightModalContainer

	local inputStroke = Instance.new("UIStroke")
	inputStroke.Color = Color3.fromRGB(0, 240, 255)
	inputStroke.Thickness = 1.2
	inputStroke.Parent = codeInput

	makeCyberButton(
		RightModalContainer,
		"JOIN CODE",
		UDim2.new(0.24, -14, 0, 40),
		UDim2.new(0.76, 2, 0, 154),
		Color3.fromRGB(0, 245, 200),
		function()
			local fmRemote = Remotes:FindFirstChild("FriendMatchAction") :: RemoteEvent?
			if fmRemote and #codeInput.Text > 0 then
				fmRemote:FireServer("JoinPrivateRoom", { RoomCode = codeInput.Text })
			end
		end
	)

	-- Practice Mode vs Training Dummy Section
	local pracLabel = Instance.new("TextLabel")
	pracLabel.Size = UDim2.new(1, -36, 0, 22)
	pracLabel.Position = UDim2.fromOffset(18, 208)
	pracLabel.BackgroundTransparency = 1
	pracLabel.Font = Enum.Font.GothamBold
	pracLabel.Text = "PRACTICE MODE (TRAINING DUMMY):"
	pracLabel.TextColor3 = Color3.fromRGB(255, 55, 185)
	pracLabel.TextSize = 14
	pracLabel.TextXAlignment = Enum.TextXAlignment.Left
	pracLabel.Parent = RightModalContainer

	makeCyberButton(
		RightModalContainer,
		"LAUNCH PRACTICE MODE (PASSIVE TARGET DUMMY)",
		UDim2.new(0.48, -22, 0, 42),
		UDim2.fromOffset(18, 234),
		Color3.fromRGB(0, 245, 200),
		function()
			local pRemote = Remotes:FindFirstChild("PracticeAction") :: RemoteEvent?
			if pRemote then
				pRemote:FireServer(selectedWinCondition, selectedArenaIdx, false)
			end
		end
	)

	makeCyberButton(
		RightModalContainer,
		"LAUNCH SPARRING BOT (BOT SHOOTS BACK)",
		UDim2.new(0.48, -22, 0, 42),
		UDim2.new(0.52, 4, 0, 234),
		Color3.fromRGB(215, 50, 255),
		function()
			local pRemote = Remotes:FindFirstChild("PracticeAction") :: RemoteEvent?
			if pRemote then
				pRemote:FireServer(selectedWinCondition, selectedArenaIdx, true)
			end
		end
	)

	-- Online Players / Friends List to Challenge
	local friendHdr = Instance.new("TextLabel")
	friendHdr.Size = UDim2.new(1, -36, 0, 22)
	friendHdr.Position = UDim2.fromOffset(18, 290)
	friendHdr.BackgroundTransparency = 1
	friendHdr.Font = Enum.Font.GothamBold
	friendHdr.Text = "ONLINE PLAYERS IN SERVER (CLICK TO CHALLENGE 1VS1):"
	friendHdr.TextColor3 = Color3.fromRGB(0, 235, 255)
	friendHdr.TextSize = 14
	friendHdr.TextXAlignment = Enum.TextXAlignment.Left
	friendHdr.Parent = RightModalContainer

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -36, 0, 175)
	scroll.Position = UDim2.fromOffset(18, 316)
	scroll.BackgroundColor3 = Color3.fromRGB(12, 14, 24)
	scroll.BackgroundTransparency = 0.3
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.Parent = RightModalContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = scroll

	local otherPlayersCount = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			otherPlayersCount += 1
			makeCyberButton(
				scroll,
				"CHALLENGE " .. string.upper(plr.Name) .. " TO 1VS1 DUEL",
				UDim2.new(1, -10, 0, 38),
				UDim2.new(),
				Color3.fromRGB(0, 235, 255),
				function()
					local fmRemote = Remotes:FindFirstChild("FriendMatchAction") :: RemoteEvent?
					if fmRemote then
						fmRemote:FireServer("ChallengePlayer", { TargetName = plr.Name })
					end
				end
			)
		end
	end

	if otherPlayersCount == 0 then
		local emptyLbl = Instance.new("TextLabel")
		emptyLbl.Size = UDim2.new(1, -16, 0, 48)
		emptyLbl.BackgroundTransparency = 1
		emptyLbl.Font = Enum.Font.RobotoMono
		emptyLbl.Text = "No other human players in this server instance yet. Invite a friend or click 'LAUNCH SPARRING BOT' above!"
		emptyLbl.TextColor3 = Color3.fromRGB(170, 185, 215)
		emptyLbl.TextSize = 13
		emptyLbl.TextWrapped = true
		emptyLbl.Parent = scroll
	end
end

-- ============================================================================
-- MODAL 3: SHOP (Weapon Skins & Character Skins)
-- ============================================================================
local currentShopTab: "WeaponSkin" | "CharacterSkin" = "WeaponSkin"

function MainMenuUI.RenderShopModal()
	ActivePanelName = "Shop"
	clearModal()
	if not RightModalContainer then
		return
	end

	makeModalHeader(
		"CYBER ARMORY & SKIN SHOP",
		"COINS BALANCE: " .. tostring(CurrentProfile.Coins or 0) .. " CR // CUSTOMIZE WEAPONS & EXOSUITS"
	)

	-- Tab Buttons
	makeCyberButton(
		RightModalContainer,
		"WEAPON SKINS (" .. tostring(#ShopConfig.WeaponSkins) .. ")",
		UDim2.new(0.48, -22, 0, 38),
		UDim2.fromOffset(18, 82),
		if currentShopTab == "WeaponSkin" then Color3.fromRGB(0, 245, 255) else Color3.fromRGB(90, 100, 135),
		function()
			currentShopTab = "WeaponSkin"
			MainMenuUI.RenderShopModal()
		end
	)

	makeCyberButton(
		RightModalContainer,
		"CHARACTER SKINS (" .. tostring(#ShopConfig.CharacterSkins) .. ")",
		UDim2.new(0.48, -22, 0, 38),
		UDim2.new(0.52, 4, 0, 82),
		if currentShopTab == "CharacterSkin" then Color3.fromRGB(225, 50, 255) else Color3.fromRGB(90, 100, 135),
		function()
			currentShopTab = "CharacterSkin"
			MainMenuUI.RenderShopModal()
		end
	)

	local gridScroll = Instance.new("ScrollingFrame")
	gridScroll.Size = UDim2.new(1, -36, 0, 365)
	gridScroll.Position = UDim2.fromOffset(18, 130)
	gridScroll.BackgroundTransparency = 1
	gridScroll.BorderSizePixel = 0
	gridScroll.ScrollBarThickness = 5
	gridScroll.CanvasSize = UDim2.fromOffset(0, 420)
	gridScroll.Parent = RightModalContainer

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 112)
	grid.CellPadding = UDim2.fromOffset(12, 12)
	grid.Parent = gridScroll

	local items = if currentShopTab == "WeaponSkin"
		then ShopConfig.WeaponSkins
		else ShopConfig.CharacterSkins
	local ownedMap = if currentShopTab == "WeaponSkin"
		then (CurrentProfile.OwnedWeaponSkins or {})
		else (CurrentProfile.OwnedCharacterSkins or {})
	local equippedId = if currentShopTab == "WeaponSkin"
		then CurrentProfile.EquippedWeaponSkin
		else CurrentProfile.EquippedCharacterSkin

	for _, item in ipairs(items) do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(16, 18, 32)
		card.BackgroundTransparency = 0.15
		card.BorderSizePixel = 0
		card.Parent = gridScroll

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 6)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = item.PrimaryNeon
		cardStroke.Thickness = if equippedId == item.Id then 2.4 else 1.2
		cardStroke.Parent = card

		-- Neon Color Swatch Preview Bar
		local swatch = Instance.new("Frame")
		swatch.Size = UDim2.new(0, 8, 1, -16)
		swatch.Position = UDim2.fromOffset(8, 8)
		swatch.BackgroundColor3 = item.PrimaryNeon
		swatch.BorderSizePixel = 0
		swatch.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -28, 0, 22)
		nameLbl.Position = UDim2.fromOffset(22, 6)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.Text = item.Name
		nameLbl.TextColor3 = item.PrimaryNeon
		nameLbl.TextSize = 14
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Parent = card

		local rarityLbl = Instance.new("TextLabel")
		rarityLbl.Size = UDim2.new(1, -28, 0, 16)
		rarityLbl.Position = UDim2.fromOffset(22, 26)
		rarityLbl.BackgroundTransparency = 1
		rarityLbl.Font = Enum.Font.RobotoMono
		rarityLbl.Text = string.upper(item.Rarity) .. " // " .. item.Description
		rarityLbl.TextColor3 = Color3.fromRGB(185, 195, 220)
		rarityLbl.TextSize = 11
		rarityLbl.TextTruncate = Enum.TextTruncate.AtEnd
		rarityLbl.TextXAlignment = Enum.TextXAlignment.Left
		rarityLbl.Parent = card

		local isOwned = (ownedMap[item.Id] == true)
		local isEquipped = (equippedId == item.Id)

		local btnText = if isEquipped
			then "EQUIPPED"
			elseif isOwned then "EQUIP SKIN"
			else ("BUY — " .. tostring(item.Price) .. " COINS")
		local btnAccent = if isEquipped
			then Color3.fromRGB(0, 255, 180)
			elseif isOwned then Color3.fromRGB(0, 225, 255)
			else Color3.fromRGB(255, 50, 180)

		makeCyberButton(
			card,
			btnText,
			UDim2.new(1, -30, 0, 34),
			UDim2.fromOffset(22, 68),
			btnAccent,
			function()
				local shopFunc = Remotes:FindFirstChild("ShopAction") :: RemoteFunction?
				if shopFunc then
					local action = if isOwned then "Equip" else "Buy"
					local ok, msg = shopFunc:InvokeServer(action, currentShopTab, item.Id)
					if StatusBannerLabel and type(msg) == "string" then
						StatusBannerLabel.Text = string.upper(msg)
						StatusBannerLabel.TextColor3 = if ok
							then Color3.fromRGB(0, 255, 190)
							else Color3.fromRGB(255, 70, 110)
					end
					MainMenuUI.RenderShopModal()
				end
			end
		)
	end
end

-- ============================================================================
-- MODAL 4: PLAYER PROFILE, STATISTICS & LEADERBOARD
-- ============================================================================
function MainMenuUI.RenderProfileModal()
	ActivePanelName = "Profile"
	clearModal()
	if not RightModalContainer then
		return
	end

	local lvl = CurrentProfile.Level or 1
	local xp = CurrentProfile.XP or 0
	local reqXP = ShopConfig.GetXPRequiredForLevel(lvl)
	local wins = CurrentProfile.Wins or 0
	local losses = CurrentProfile.Losses or 0
	local kills = CurrentProfile.Kills or 0
	local deaths = CurrentProfile.Deaths or 0
	local totalMatches = wins + losses
	local winRate = if totalMatches > 0 then math.floor((wins / totalMatches) * 100) else 0
	local kdRatio = if deaths > 0 then string.format("%.2f", kills / deaths) else tostring(kills)

	makeModalHeader(
		"OPERATIVE PROFILE // " .. string.upper(LocalPlayer.Name),
		"LEVEL " .. tostring(lvl) .. " (" .. tostring(xp) .. "/" .. tostring(reqXP) .. " XP) // COINS: " .. tostring(CurrentProfile.Coins or 0)
	)

	-- XP Progress Bar
	local xpBarBg = Instance.new("Frame")
	xpBarBg.Size = UDim2.new(1, -36, 0, 12)
	xpBarBg.Position = UDim2.fromOffset(18, 80)
	xpBarBg.BackgroundColor3 = Color3.fromRGB(16, 20, 34)
	xpBarBg.BorderSizePixel = 0
	xpBarBg.Parent = RightModalContainer

	local xpFill = Instance.new("Frame")
	xpFill.Size = UDim2.fromScale(math.clamp(xp / math.max(1, reqXP), 0, 1), 1)
	xpFill.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpBarBg

	-- 6 Stat Cards Grid
	local statsContainer = Instance.new("Frame")
	statsContainer.Size = UDim2.new(1, -36, 0, 130)
	statsContainer.Position = UDim2.fromOffset(18, 102)
	statsContainer.BackgroundTransparency = 1
	statsContainer.Parent = RightModalContainer

	local statGrid = Instance.new("UIGridLayout")
	statGrid.CellSize = UDim2.new(0.31, 0, 0, 58)
	statGrid.CellPadding = UDim2.fromOffset(10, 10)
	statGrid.Parent = statsContainer

	local statItems = {
		{ Label = "WINS", Value = tostring(wins), Color = Color3.fromRGB(0, 255, 190) },
		{ Label = "LOSSES", Value = tostring(losses), Color = Color3.fromRGB(255, 65, 135) },
		{ Label = "WIN RATE", Value = tostring(winRate) .. "%", Color = Color3.fromRGB(0, 235, 255) },
		{ Label = "TOTAL KILLS", Value = tostring(kills), Color = Color3.fromRGB(210, 65, 255) },
		{ Label = "K/D RATIO", Value = kdRatio, Color = Color3.fromRGB(255, 210, 60) },
		{ Label = "WIN STREAK", Value = tostring(CurrentProfile.WinStreak or 0), Color = Color3.fromRGB(0, 240, 255) },
	}

	for _, st in ipairs(statItems) do
		local box = Instance.new("Frame")
		box.BackgroundColor3 = Color3.fromRGB(15, 18, 32)
		box.BorderSizePixel = 0
		box.Parent = statsContainer

		local stroke = Instance.new("UIStroke")
		stroke.Color = st.Color
		stroke.Thickness = 1.2
		stroke.Transparency = 0.35
		stroke.Parent = box

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(1, 0, 0, 32)
		valLbl.Position = UDim2.fromOffset(0, 4)
		valLbl.BackgroundTransparency = 1
		valLbl.Font = Enum.Font.Michroma
		valLbl.Text = st.Value
		valLbl.TextColor3 = st.Color
		valLbl.TextSize = 19
		valLbl.Parent = box

		local capLbl = Instance.new("TextLabel")
		capLbl.Size = UDim2.new(1, 0, 0, 18)
		capLbl.Position = UDim2.fromOffset(0, 36)
		capLbl.BackgroundTransparency = 1
		capLbl.Font = Enum.Font.RobotoMono
		capLbl.Text = st.Label
		capLbl.TextColor3 = Color3.fromRGB(180, 195, 220)
		capLbl.TextSize = 11
		capLbl.Parent = box
	end

	-- Global & Server Leaderboard
	local lbHeader = Instance.new("TextLabel")
	lbHeader.Size = UDim2.new(1, -36, 0, 24)
	lbHeader.Position = UDim2.fromOffset(18, 242)
	lbHeader.BackgroundTransparency = 1
	lbHeader.Font = Enum.Font.GothamBold
	lbHeader.Text = "TOP CYBERCITY DUELISTS LEADERBOARD:"
	lbHeader.TextColor3 = Color3.fromRGB(0, 240, 255)
	lbHeader.TextSize = 14
	lbHeader.TextXAlignment = Enum.TextXAlignment.Left
	lbHeader.Parent = RightModalContainer

	local lbList = Instance.new("ScrollingFrame")
	lbList.Size = UDim2.new(1, -36, 0, 225)
	lbList.Position = UDim2.fromOffset(18, 270)
	lbList.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
	lbList.BackgroundTransparency = 0.25
	lbList.BorderSizePixel = 0
	lbList.ScrollBarThickness = 4
	lbList.Parent = RightModalContainer

	local lbLayout = Instance.new("UIListLayout")
	lbLayout.Padding = UDim.new(0, 4)
	lbLayout.Parent = lbList

	for rank, entry in ipairs(CurrentLeaderboard) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 34)
		row.BackgroundColor3 = if entry.Name == LocalPlayer.Name
			then Color3.fromRGB(48, 24, 72)
			else Color3.fromRGB(18, 22, 36)
		row.BorderSizePixel = 0
		row.Parent = lbList

		local rowText = Instance.new("TextLabel")
		rowText.Size = UDim2.new(1, -20, 1, 0)
		rowText.Position = UDim2.fromOffset(10, 0)
		rowText.BackgroundTransparency = 1
		rowText.Font = Enum.Font.RobotoMono
		rowText.Text = string.format(
			"#%02d   %-18s   WINS: %-4d   LVL: %d",
			rank,
			entry.Name,
			entry.Wins,
			entry.Level
		)
		rowText.TextColor3 = if rank == 1
			then Color3.fromRGB(255, 215, 55)
			elseif rank <= 3 then Color3.fromRGB(0, 240, 255)
			else Color3.fromRGB(215, 225, 245)
		rowText.TextSize = 13
		rowText.TextXAlignment = Enum.TextXAlignment.Left
		rowText.Parent = row
	end
end

-- ============================================================================
-- MODAL 5: SETTINGS
-- ============================================================================
function MainMenuUI.RenderSettingsModal()
	ActivePanelName = "Settings"
	clearModal()
	if not RightModalContainer then
		return
	end

	makeModalHeader(
		"SYSTEM SETTINGS // NEON DUEL 2.0",
		"CONFIGURE CAMERA FOV, AIM SENSITIVITY, AUDIO & CYBERPUNK POST-FX"
	)

	local settings = CurrentProfile.Settings

	local function createSettingRow(
		index: number,
		label: string,
		valueText: string,
		onDecrease: () -> (),
		onIncrease: () -> ()
	)
		local yPos = 86 + (index - 1) * 64
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -36, 0, 52)
		row.Position = UDim2.fromOffset(18, yPos)
		row.BackgroundColor3 = Color3.fromRGB(15, 18, 32)
		row.BorderSizePixel = 0
		row.Parent = RightModalContainer

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.55, 0, 1, 0)
		lbl.Position = UDim2.fromOffset(14, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = label
		lbl.TextColor3 = Color3.fromRGB(220, 235, 255)
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = row

		makeCyberButton(
			row,
			"-",
			UDim2.fromOffset(42, 36),
			UDim2.new(0.58, 0, 0, 8),
			Color3.fromRGB(195, 55, 255),
			onDecrease
		)

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0.18, 0, 1, 0)
		valLbl.Position = UDim2.new(0.68, 0, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Font = Enum.Font.Michroma
		valLbl.Text = valueText
		valLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
		valLbl.TextSize = 15
		valLbl.Parent = row

		makeCyberButton(
			row,
			"+",
			UDim2.fromOffset(42, 36),
			UDim2.new(0.88, 0, 0, 8),
			Color3.fromRGB(0, 240, 255),
			onIncrease
		)
	end

	local function pushSettingsUpdate()
		SoundManager.SetVolumes(settings.SfxVolume, settings.MusicVolume)
		if MainMenuUI.OnSettingsChanged then
			MainMenuUI.OnSettingsChanged(settings)
		end
		local sRemote = Remotes:FindFirstChild("UpdateSettings") :: RemoteEvent?
		if sRemote then
			sRemote:FireServer(settings)
		end
		MainMenuUI.RenderSettingsModal()
	end

	createSettingRow(1, "CAMERA FIELD OF VIEW (FOV)", tostring(settings.FOV) .. "°", function()
		settings.FOV = math.clamp(settings.FOV - 4, 65, 105)
		pushSettingsUpdate()
	end, function()
		settings.FOV = math.clamp(settings.FOV + 4, 65, 105)
		pushSettingsUpdate()
	end)

	createSettingRow(2, "LOOK SENSITIVITY", string.format("%.2f", settings.Sensitivity), function()
		settings.Sensitivity = math.clamp(math.floor((settings.Sensitivity - 0.1) * 100 + 0.5) / 100, 0.1, 2.0)
		pushSettingsUpdate()
	end, function()
		settings.Sensitivity = math.clamp(math.floor((settings.Sensitivity + 0.1) * 100 + 0.5) / 100, 0.1, 2.0)
		pushSettingsUpdate()
	end)

	createSettingRow(3, "ADS AIM SENSITIVITY", string.format("%.2f", settings.AimSensitivity), function()
		settings.AimSensitivity = math.clamp(math.floor((settings.AimSensitivity - 0.05) * 100 + 0.5) / 100, 0.1, 1.5)
		pushSettingsUpdate()
	end, function()
		settings.AimSensitivity = math.clamp(math.floor((settings.AimSensitivity + 0.05) * 100 + 0.5) / 100, 0.1, 1.5)
		pushSettingsUpdate()
	end)

	createSettingRow(4, "SFX AUDIO VOLUME", tostring(math.floor(settings.SfxVolume * 100 + 0.5)) .. "%", function()
		settings.SfxVolume = math.clamp(settings.SfxVolume - 0.1, 0, 1)
		pushSettingsUpdate()
	end, function()
		settings.SfxVolume = math.clamp(settings.SfxVolume + 0.1, 0, 1)
		pushSettingsUpdate()
	end)

	createSettingRow(5, "NEON BLOOM GRAPHICS", if settings.HighQualityNeon then "ULTRA" else "LOW", function()
		settings.HighQualityNeon = not settings.HighQualityNeon
		pushSettingsUpdate()
	end, function()
		settings.HighQualityNeon = not settings.HighQualityNeon
		pushSettingsUpdate()
	end)
end

-- ============================================================================
-- MAIN MENU CREATION (IMAGE 1 "CYBERCITY EDITION 2.0" ARCHITECTURE)
-- ============================================================================
function MainMenuUI.Init()
	local existing = PlayerGui:FindFirstChild("NeonDuelMainMenu")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "NeonDuelMainMenu"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui
	MenuGui = gui

	-- 1. Left Translucent Dark Glass Sidebar Panel (Matches Image 1)
	local leftSidebar = Instance.new("Frame")
	leftSidebar.Name = "CyberLeftSidebar"
	leftSidebar.Size = UDim2.fromScale(0.31, 1.0)
	leftSidebar.Position = UDim2.fromScale(0.055, 0)
	leftSidebar.BackgroundColor3 = Color3.fromRGB(16, 12, 34)
	leftSidebar.BackgroundTransparency = 0.30
	leftSidebar.BorderSizePixel = 0
	leftSidebar.Parent = gui

	-- Subtle vertical edge lines on the frosted sidebar (like Image 1)
	local leftEdge = Instance.new("Frame")
	leftEdge.Size = UDim2.new(0, 1, 1, 0)
	leftEdge.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
	leftEdge.BackgroundTransparency = 0.65
	leftEdge.BorderSizePixel = 0
	leftEdge.Parent = leftSidebar

	local rightEdge = Instance.new("Frame")
	rightEdge.Size = UDim2.new(0, 1, 1, 0)
	rightEdge.Position = UDim2.fromScale(1, 0)
	rightEdge.BackgroundColor3 = Color3.fromRGB(0, 225, 255)
	rightEdge.BackgroundTransparency = 0.65
	rightEdge.BorderSizePixel = 0
	rightEdge.Parent = leftSidebar

	-- 2. Top-Left "NEON DUEL" + "Edition 2.0" Logo (Styled like Image 1 "CYBERCITY Edition 2.0")
	local logoContainer = Instance.new("Frame")
	logoContainer.Name = "LogoContainer"
	logoContainer.Size = UDim2.new(0.88, 0, 0, 115)
	logoContainer.Position = UDim2.new(0.06, 0, 0.08, 0)
	logoContainer.BackgroundTransparency = 1
	logoContainer.Parent = leftSidebar

	-- Glow Shadow Behind Title
	local logoGlow = Instance.new("TextLabel")
	logoGlow.Size = UDim2.new(1, 0, 0, 56)
	logoGlow.Position = UDim2.fromOffset(2, 3)
	logoGlow.BackgroundTransparency = 1
	logoGlow.Font = Enum.Font.Michroma
	logoGlow.Text = "NEON DUEL"
	logoGlow.TextColor3 = Color3.fromRGB(255, 25, 175)
	logoGlow.TextTransparency = 0.25
	logoGlow.TextScaled = true
	logoGlow.TextXAlignment = Enum.TextXAlignment.Left
	logoGlow.Parent = logoContainer

	-- Main Metallic Cyan/Magenta Gradient Title
	local logoMain = Instance.new("TextLabel")
	logoMain.Size = UDim2.new(1, 0, 0, 56)
	logoMain.BackgroundTransparency = 1
	logoMain.Font = Enum.Font.Michroma
	logoMain.Text = "NEON DUEL"
	logoMain.TextColor3 = Color3.fromRGB(255, 255, 255)
	logoMain.TextScaled = true
	logoMain.TextXAlignment = Enum.TextXAlignment.Left
	logoMain.Parent = logoContainer

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Rotation = 90
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 255, 245)),
		ColorSequenceKeypoint.new(0.46, Color3.fromRGB(190, 255, 255)),
		ColorSequenceKeypoint.new(0.52, Color3.fromRGB(28, 12, 48)),
		ColorSequenceKeypoint.new(0.62, Color3.fromRGB(255, 45, 190)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 185, 245)),
	})
	titleGradient.Parent = logoMain

	-- Cursive/Slanted "Edition 2.0" Subtitle overlapping bottom-right of logo (like Image 1)
	local editionLabel = Instance.new("TextLabel")
	editionLabel.Name = "Edition2Label"
	editionLabel.Size = UDim2.new(0.75, 0, 0, 36)
	editionLabel.Position = UDim2.new(0.22, 0, 0, 44)
	editionLabel.Rotation = -7
	editionLabel.BackgroundTransparency = 1
	editionLabel.Font = Enum.Font.GothamMedium
	editionLabel.RichText = true
	editionLabel.Text = "<i>Edition 2.0</i>"
	editionLabel.TextColor3 = Color3.fromRGB(250, 235, 255)
	editionLabel.TextSize = 27
	editionLabel.TextStrokeColor3 = Color3.fromRGB(255, 40, 185)
	editionLabel.TextStrokeTransparency = 0.25
	editionLabel.TextXAlignment = Enum.TextXAlignment.Left
	editionLabel.Parent = logoContainer

	-- Mini Profile Status Bar under logo
	local profileSummary = Instance.new("TextLabel")
	profileSummary.Size = UDim2.new(0.88, 0, 0, 22)
	profileSummary.Position = UDim2.new(0.06, 0, 0.23, 0)
	profileSummary.BackgroundTransparency = 1
	profileSummary.Font = Enum.Font.RobotoMono
	profileSummary.Text = "LVL 1 // 350 COINS // 0W - 0L"
	profileSummary.TextColor3 = Color3.fromRGB(165, 225, 255)
	profileSummary.TextSize = 13
	profileSummary.TextXAlignment = Enum.TextXAlignment.Left
	profileSummary.Parent = leftSidebar
	TopProfileBadge = profileSummary

	-- 3. Left-Aligned Vertical Menu Items (Styled like Image 1 "Continue / Load game / New game / Settings / Quit game")
	local menuItems = {
		{ Name = "PLAY 1VS1", OpenPanel = MainMenuUI.RenderPlay1v1Modal },
		{ Name = "FRIEND MATCH", OpenPanel = MainMenuUI.RenderFriendMatchModal },
		{ Name = "SHOP", OpenPanel = MainMenuUI.RenderShopModal },
		{ Name = "PLAYER PROFILE", OpenPanel = MainMenuUI.RenderProfileModal },
		{ Name = "SETTINGS", OpenPanel = MainMenuUI.RenderSettingsModal },
	}

	local menuListFrame = Instance.new("Frame")
	menuListFrame.Name = "MenuButtonsList"
	menuListFrame.Size = UDim2.new(0.86, 0, 0, 340)
	menuListFrame.Position = UDim2.new(0.07, 0, 0.29, 0)
	menuListFrame.BackgroundTransparency = 1
	menuListFrame.Parent = leftSidebar

	local buttonRefs: { { Button: TextButton, Brackets: Frame } } = {}

	local function updateMenuSelection(newIndex: number)
		SelectedMenuIndex = math.clamp(newIndex, 1, #menuItems)
		for idx, ref in ipairs(buttonRefs) do
			local isSelected = (idx == SelectedMenuIndex)
			ref.Brackets.Visible = isSelected
			TweenService:Create(ref.Button, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
				BackgroundTransparency = if isSelected then 0.32 else 1.0,
				BackgroundColor3 = if isSelected
					then Color3.fromRGB(122, 42, 148)
					else Color3.fromRGB(20, 12, 34),
				TextColor3 = if isSelected
					then Color3.fromRGB(250, 245, 255)
					else Color3.fromRGB(115, 245, 255),
			}):Play()
		end
	end

	for i, item in ipairs(menuItems) do
		local btn = Instance.new("TextButton")
		btn.Name = "MenuBtn_" .. tostring(i)
		btn.Size = UDim2.new(1, 0, 0, 52)
		btn.Position = UDim2.fromOffset(0, (i - 1) * 64)
		btn.BackgroundColor3 = Color3.fromRGB(122, 42, 148)
		btn.BackgroundTransparency = if i == 1 then 0.32 else 1.0
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Font = Enum.Font.RobotoMono
		btn.Text = "  " .. item.Name
		btn.TextColor3 = if i == 1 then Color3.fromRGB(250, 245, 255) else Color3.fromRGB(115, 245, 255)
		btn.TextSize = 22
		btn.TextStrokeColor3 = Color3.fromRGB(0, 185, 255)
		btn.TextStrokeTransparency = 0.65
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = menuListFrame

		local brackets = createCornerBrackets(btn)
		brackets.Visible = (i == 1)

		table.insert(buttonRefs, {
			Button = btn,
			Brackets = brackets,
		})

		btn.MouseEnter:Connect(function()
			SoundManager.Play2D("UIHover")
			updateMenuSelection(i)
		end)

		btn.MouseButton1Click:Connect(function()
			SoundManager.Play2D("UIClick")
			updateMenuSelection(i)
			item.OpenPanel()
		end)
	end

	-- Status Banner at Bottom of Left Sidebar
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0.86, 0, 0, 42)
	statusLabel.Position = UDim2.new(0.07, 0, 0.88, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.RobotoMono
	statusLabel.Text = "READY // SELECT A MODE TO DEPLOY"
	statusLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
	statusLabel.TextSize = 13
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = leftSidebar
	StatusBannerLabel = statusLabel

	-- 4. Right Interactive Sub-Panel Container (Translucent Cyber Glass Frame)
	local rightModal = Instance.new("Frame")
	rightModal.Name = "RightSubPanel"
	rightModal.Size = UDim2.fromScale(0.54, 0.72)
	rightModal.Position = UDim2.fromScale(0.41, 0.13)
	rightModal.BackgroundColor3 = Color3.fromRGB(12, 10, 26)
	rightModal.BackgroundTransparency = 0.22
	rightModal.BorderSizePixel = 0
	rightModal.Parent = gui
	RightModalContainer = rightModal

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 8)
	modalCorner.Parent = rightModal

	local modalStroke = Instance.new("UIStroke")
	modalStroke.Color = Color3.fromRGB(0, 230, 255)
	modalStroke.Thickness = 1.5
	modalStroke.Transparency = 0.25
	modalStroke.Parent = rightModal

	-- 5. Bottom-Right Controller/Keyboard Navigation Prompt (Matches Image 1: "+ NAVIGATE   (X) SELECT")
	local navLegend = Instance.new("Frame")
	navLegend.Name = "BottomRightNavLegend"
	navLegend.Size = UDim2.fromOffset(270, 38)
	navLegend.Position = UDim2.new(1, -295, 1, -52)
	navLegend.BackgroundTransparency = 1
	navLegend.Parent = gui

	local dpadIcon = Instance.new("TextLabel")
	dpadIcon.Size = UDim2.fromOffset(28, 28)
	dpadIcon.Position = UDim2.fromOffset(0, 5)
	dpadIcon.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
	dpadIcon.BackgroundTransparency = 0.85
	dpadIcon.Font = Enum.Font.GothamBlack
	dpadIcon.Text = "┼"
	dpadIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	dpadIcon.TextSize = 20
	dpadIcon.Parent = navLegend

	local navText = Instance.new("TextLabel")
	navText.Size = UDim2.fromOffset(90, 28)
	navText.Position = UDim2.fromOffset(36, 5)
	navText.BackgroundTransparency = 1
	navText.Font = Enum.Font.GothamBold
	navText.Text = "NAVIGATE"
	navText.TextColor3 = Color3.fromRGB(240, 245, 255)
	navText.TextSize = 13
	navText.TextXAlignment = Enum.TextXAlignment.Left
	navText.Parent = navLegend

	local selectCircle = Instance.new("TextLabel")
	selectCircle.Size = UDim2.fromOffset(26, 26)
	selectCircle.Position = UDim2.fromOffset(145, 6)
	selectCircle.BackgroundColor3 = Color3.fromRGB(220, 240, 255)
	selectCircle.Font = Enum.Font.GothamBlack
	selectCircle.Text = "✕"
	selectCircle.TextColor3 = Color3.fromRGB(16, 18, 30)
	selectCircle.TextSize = 14
	selectCircle.Parent = navLegend

	local selCorner = Instance.new("UICorner")
	selCorner.CornerRadius = UDim.new(1, 0)
	selCorner.Parent = selectCircle

	local selText = Instance.new("TextLabel")
	selText.Size = UDim2.fromOffset(80, 28)
	selText.Position = UDim2.fromOffset(180, 5)
	selText.BackgroundTransparency = 1
	selText.Font = Enum.Font.GothamBold
	selText.Text = "SELECT"
	selText.TextColor3 = Color3.fromRGB(240, 245, 255)
	selText.TextSize = 13
	selText.TextXAlignment = Enum.TextXAlignment.Left
	selText.Parent = navLegend

	-- Keyboard Up/Down/Enter Navigation Support
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not gui.Enabled then
			return
		end
		if input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
			SoundManager.Play2D("UIHover")
			local nextIdx = (SelectedMenuIndex % #menuItems) + 1
			updateMenuSelection(nextIdx)
			menuItems[nextIdx].OpenPanel()
		elseif input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
			SoundManager.Play2D("UIHover")
			local prevIdx = ((SelectedMenuIndex - 2) % #menuItems) + 1
			updateMenuSelection(prevIdx)
			menuItems[prevIdx].OpenPanel()
		elseif input.KeyCode == Enum.KeyCode.Return then
			SoundManager.Play2D("UIClick")
			menuItems[SelectedMenuIndex].OpenPanel()
		end
	end)

	-- Render initial panel
	MainMenuUI.RenderPlay1v1Modal()
end

function MainMenuUI.SetVisible(visible: boolean)
	if MenuGui then
		MenuGui.Enabled = visible
	end
	if visible then
		InQueue = false
	end
end

function MainMenuUI.IsVisible(): boolean
	return if MenuGui then MenuGui.Enabled else false
end

function MainMenuUI.UpdateProfileData(profile: any, leaderboard: any)
	if type(profile) == "table" then
		CurrentProfile = profile
		if TopProfileBadge then
			TopProfileBadge.Text = string.format(
				"LVL %d // %d COINS // %dW - %dL // KILLS: %d",
				profile.Level or 1,
				profile.Coins or 0,
				profile.Wins or 0,
				profile.Losses or 0,
				profile.Kills or 0
			)
		end
		if MainMenuUI.OnSettingsChanged and profile.Settings then
			MainMenuUI.OnSettingsChanged(profile.Settings)
		end
	end
	if type(leaderboard) == "table" then
		CurrentLeaderboard = leaderboard
	end

	if MenuGui and MenuGui.Enabled then
		if ActivePanelName == "Shop" then
			MainMenuUI.RenderShopModal()
		elseif ActivePanelName == "Profile" then
			MainMenuUI.RenderProfileModal()
		end
	end
end

function MainMenuUI.HandleNotification(notifType: string, payload: { [string]: any })
	if not StatusBannerLabel then
		return
	end
	if notifType == "QueueStatus" then
		InQueue = payload.InQueue == true
		StatusBannerLabel.Text = tostring(payload.Message or "")
		StatusBannerLabel.TextColor3 = Color3.fromRGB(0, 245, 255)
		if ActivePanelName == "Play1v1" then
			MainMenuUI.RenderPlay1v1Modal()
		end
	elseif notifType == "PrivateRoomCreated" then
		StatusBannerLabel.Text = "PRIVATE ROOM CREATED! CODE: "
			.. tostring(payload.RoomCode)
			.. " (SHARE WITH FRIEND OR CLICK JOIN TO TEST SOLO)"
		StatusBannerLabel.TextColor3 = Color3.fromRGB(0, 255, 190)
	elseif notifType == "IncomingChallenge" then
		local challenger = tostring(payload.ChallengerName or "Player")
		StatusBannerLabel.Text = "DUEL CHALLENGE FROM " .. challenger .. "! CLICK FRIEND MATCH TO ACCEPT"
		StatusBannerLabel.TextColor3 = Color3.fromRGB(255, 50, 185)
		local fmRemote = Remotes:FindFirstChild("FriendMatchAction") :: RemoteEvent?
		if fmRemote then
			-- Auto-display accept button on right modal
			if RightModalContainer then
				makeCyberButton(
					RightModalContainer,
					"ACCEPT 1VS1 DUEL FROM " .. string.upper(challenger),
					UDim2.new(1, -36, 0, 44),
					UDim2.new(0, 18, 1, -56),
					Color3.fromRGB(0, 255, 190),
					function()
						fmRemote:FireServer("AcceptChallenge", {})
					end
				)
			end
		end
	elseif notifType == "Error" then
		StatusBannerLabel.Text = tostring(payload.Message or "ERROR")
		StatusBannerLabel.TextColor3 = Color3.fromRGB(255, 70, 100)
	elseif notifType == "Info" then
		StatusBannerLabel.Text = tostring(payload.Message or "")
		StatusBannerLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
	end
end

function MainMenuUI.GetProfile(): any
	return CurrentProfile
end

return MainMenuUI

