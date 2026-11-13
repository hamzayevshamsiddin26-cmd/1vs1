--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: StarterPlayerScripts.HUDController
	Description: Competitive Cyberpunk In-Match HUD displaying BOTH players' 100 HP
	health bars, kill counters, scoreboard, 120-second (02:00) Arena Rotation countdown,
	smooth ARENA CHANGING transition animation, 5-weapon slot bar, dynamic crosshair,
	sniper scope, hitmarkers, kill feed, and victory screen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))
local SoundManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundManager"))

local HUDController = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local HudGui: ScreenGui? = nil

-- Top Scoreboard & Both Players' HP Elements
local P1NameLabel: TextLabel? = nil
local P2NameLabel: TextLabel? = nil
local P1KillsLabel: TextLabel? = nil
local P2KillsLabel: TextLabel? = nil
local P1HealthBarFill: Frame? = nil
local P2HealthBarFill: Frame? = nil
local P1HealthText: TextLabel? = nil
local P2HealthText: TextLabel? = nil
local ArenaTimerLabel: TextLabel? = nil
local ArenaNameLabel: TextLabel? = nil
local WinGoalLabel: TextLabel? = nil

-- Bottom Local Vitals & Weapon HUD
local LocalHPNumber: TextLabel? = nil
local LocalHPBarFill: Frame? = nil
local WeaponNameLabel: TextLabel? = nil
local AmmoMagLabel: TextLabel? = nil
local AmmoReserveLabel: TextLabel? = nil
local ReloadingBanner: TextLabel? = nil
local SlotFrames: { [string]: Frame } = {}

-- Crosshair, Scope, Hitmarker, Vignette, Overlays
local CrosshairRoot: Frame? = nil
local CrosshairBars: { Frame } = {}
local SniperScopeFrame: Frame? = nil
local HitmarkerFrame: Frame? = nil
local HeadshotLabel: TextLabel? = nil
local DamageVignette: Frame? = nil
local ArenaTransitionOverlay: Frame? = nil
local ArenaTransitionTitle: TextLabel? = nil
local ArenaTransitionSub: TextLabel? = nil
local ArenaTransitionHPNote: TextLabel? = nil
local KillFeedContainer: Frame? = nil
local MatchEndOverlay: Frame? = nil
local MatchEndTitle: TextLabel? = nil
local MatchEndSub: TextLabel? = nil

HUDController.OnWeaponSlotClicked = nil :: ((weaponId: string) -> ())?

local lastWarningSecond = -1

local function formatTimeMMSS(seconds: number): string
	local clamped = math.max(0, math.floor(seconds))
	local mins = math.floor(clamped / 60)
	local secs = clamped % 60
	return string.format("%02d:%02d", mins, secs)
end

function HUDController.Init()
	local existing = PlayerGui:FindFirstChild("NeonDuelHUD")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "NeonDuelHUD"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui
	HudGui = gui

	-- ========================================================================
	-- 1. DAMAGE TAKEN VIGNETTE OVERLAY
	-- ========================================================================
	local vignette = Instance.new("Frame")
	vignette.Name = "DamageVignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(255, 20, 80)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.Parent = gui
	DamageVignette = vignette

	-- ========================================================================
	-- 2. TOP SCOREBOARD: BOTH PLAYERS' HEALTH (100 HP), KILLS & 120s ARENA TIMER
	-- ========================================================================
	local topScoreboard = Instance.new("Frame")
	topScoreboard.Name = "TopDuelScoreboard"
	topScoreboard.AnchorPoint = Vector2.new(0.5, 0)
	topScoreboard.Size = UDim2.fromOffset(740, 86)
	topScoreboard.Position = UDim2.new(0.5, 0, 0, 12)
	topScoreboard.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
	topScoreboard.BackgroundTransparency = 0.2
	topScoreboard.BorderSizePixel = 0
	topScoreboard.Parent = gui

	local sbCorner = Instance.new("UICorner")
	sbCorner.CornerRadius = UDim.new(0, 8)
	sbCorner.Parent = topScoreboard

	local sbStroke = Instance.new("UIStroke")
	sbStroke.Color = Color3.fromRGB(0, 235, 255)
	sbStroke.Thickness = 1.6
	sbStroke.Transparency = 0.25
	sbStroke.Parent = topScoreboard

	-- Player 1 Side (Left)
	local p1Name = Instance.new("TextLabel")
	p1Name.Size = UDim2.fromOffset(210, 22)
	p1Name.Position = UDim2.fromOffset(16, 8)
	p1Name.BackgroundTransparency = 1
	p1Name.Font = Enum.Font.GothamBold
	p1Name.Text = "PLAYER 1"
	p1Name.TextColor3 = Color3.fromRGB(0, 240, 255)
	p1Name.TextSize = 14
	p1Name.TextXAlignment = Enum.TextXAlignment.Left
	p1Name.Parent = topScoreboard
	P1NameLabel = p1Name

	local p1Kills = Instance.new("TextLabel")
	p1Kills.Size = UDim2.fromOffset(54, 48)
	p1Kills.Position = UDim2.fromOffset(235, 10)
	p1Kills.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
	p1Kills.Font = Enum.Font.Michroma
	p1Kills.Text = "0"
	p1Kills.TextColor3 = Color3.fromRGB(0, 245, 255)
	p1Kills.TextSize = 24
	p1Kills.Parent = topScoreboard
	P1KillsLabel = p1Kills

	local p1HpBg = Instance.new("Frame")
	p1HpBg.Size = UDim2.fromOffset(210, 16)
	p1HpBg.Position = UDim2.fromOffset(16, 36)
	p1HpBg.BackgroundColor3 = Color3.fromRGB(24, 28, 44)
	p1HpBg.BorderSizePixel = 0
	p1HpBg.Parent = topScoreboard

	local p1HpFill = Instance.new("Frame")
	p1HpFill.Size = UDim2.fromScale(1, 1)
	p1HpFill.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
	p1HpFill.BorderSizePixel = 0
	p1HpFill.Parent = p1HpBg
	P1HealthBarFill = p1HpFill

	local p1HpTxt = Instance.new("TextLabel")
	p1HpTxt.Size = UDim2.fromScale(1, 1)
	p1HpTxt.BackgroundTransparency = 1
	p1HpTxt.Font = Enum.Font.RobotoMono
	p1HpTxt.Text = "100 / 100 HP"
	p1HpTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	p1HpTxt.TextSize = 11
	p1HpTxt.Parent = p1HpBg
	P1HealthText = p1HpTxt

	-- Center 120-Second Arena Rotation Timer & Arena Name
	local centerBox = Instance.new("Frame")
	centerBox.AnchorPoint = Vector2.new(0.5, 0)
	centerBox.Size = UDim2.fromOffset(150, 74)
	centerBox.Position = UDim2.new(0.5, 0, 0, 6)
	centerBox.BackgroundColor3 = Color3.fromRGB(18, 14, 34)
	centerBox.BorderSizePixel = 0
	centerBox.Parent = topScoreboard

	local timerCaption = Instance.new("TextLabel")
	timerCaption.Size = UDim2.new(1, 0, 0, 14)
	timerCaption.Position = UDim2.fromOffset(0, 2)
	timerCaption.BackgroundTransparency = 1
	timerCaption.Font = Enum.Font.RobotoMono
	timerCaption.Text = "ARENA ROTATION"
	timerCaption.TextColor3 = Color3.fromRGB(200, 150, 255)
	timerCaption.TextSize = 10
	timerCaption.Parent = centerBox

	local timerVal = Instance.new("TextLabel")
	timerVal.Size = UDim2.new(1, 0, 0, 32)
	timerVal.Position = UDim2.fromOffset(0, 16)
	timerVal.BackgroundTransparency = 1
	timerVal.Font = Enum.Font.Michroma
	timerVal.Text = "02:00"
	timerVal.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerVal.TextSize = 24
	timerVal.Parent = centerBox
	ArenaTimerLabel = timerVal

	local arenaLbl = Instance.new("TextLabel")
	arenaLbl.Size = UDim2.new(1, 0, 0, 14)
	arenaLbl.Position = UDim2.fromOffset(0, 48)
	arenaLbl.BackgroundTransparency = 1
	arenaLbl.Font = Enum.Font.GothamBold
	arenaLbl.Text = "CYBERCITY STREET"
	arenaLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
	arenaLbl.TextSize = 10
	arenaLbl.Parent = centerBox
	ArenaNameLabel = arenaLbl

	local winGoal = Instance.new("TextLabel")
	winGoal.Size = UDim2.new(1, 0, 0, 12)
	winGoal.Position = UDim2.fromOffset(0, 61)
	winGoal.BackgroundTransparency = 1
	winGoal.Font = Enum.Font.RobotoMono
	winGoal.Text = "FIRST TO 10 KILLS"
	winGoal.TextColor3 = Color3.fromRGB(175, 190, 215)
	winGoal.TextSize = 9
	winGoal.Parent = centerBox
	WinGoalLabel = winGoal

	-- Player 2 Side (Right)
	local p2Kills = Instance.new("TextLabel")
	p2Kills.Size = UDim2.fromOffset(54, 48)
	p2Kills.Position = UDim2.new(1, -289, 0, 10)
	p2Kills.BackgroundColor3 = Color3.fromRGB(34, 16, 38)
	p2Kills.Font = Enum.Font.Michroma
	p2Kills.Text = "0"
	p2Kills.TextColor3 = Color3.fromRGB(255, 50, 180)
	p2Kills.TextSize = 24
	p2Kills.Parent = topScoreboard
	P2KillsLabel = p2Kills

	local p2Name = Instance.new("TextLabel")
	p2Name.Size = UDim2.fromOffset(210, 22)
	p2Name.Position = UDim2.new(1, -226, 0, 8)
	p2Name.BackgroundTransparency = 1
	p2Name.Font = Enum.Font.GothamBold
	p2Name.Text = "OPPONENT"
	p2Name.TextColor3 = Color3.fromRGB(255, 55, 185)
	p2Name.TextSize = 14
	p2Name.TextXAlignment = Enum.TextXAlignment.Right
	p2Name.Parent = topScoreboard
	P2NameLabel = p2Name

	local p2HpBg = Instance.new("Frame")
	p2HpBg.Size = UDim2.fromOffset(210, 16)
	p2HpBg.Position = UDim2.new(1, -226, 0, 36)
	p2HpBg.BackgroundColor3 = Color3.fromRGB(24, 28, 44)
	p2HpBg.BorderSizePixel = 0
	p2HpBg.Parent = topScoreboard

	local p2HpFill = Instance.new("Frame")
	p2HpFill.Size = UDim2.fromScale(1, 1)
	p2HpFill.BackgroundColor3 = Color3.fromRGB(255, 45, 175)
	p2HpFill.BorderSizePixel = 0
	p2HpFill.Parent = p2HpBg
	P2HealthBarFill = p2HpFill

	local p2HpTxt = Instance.new("TextLabel")
	p2HpTxt.Size = UDim2.fromScale(1, 1)
	p2HpTxt.BackgroundTransparency = 1
	p2HpTxt.Font = Enum.Font.RobotoMono
	p2HpTxt.Text = "100 / 100 HP"
	p2HpTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	p2HpTxt.TextSize = 11
	p2HpTxt.Parent = p2HpBg
	P2HealthText = p2HpTxt

	-- Top-Left Return to Menu Button
	local leaveBtn = Instance.new("TextButton")
	leaveBtn.Size = UDim2.fromOffset(135, 34)
	leaveBtn.Position = UDim2.fromOffset(16, 16)
	leaveBtn.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
	leaveBtn.BackgroundTransparency = 0.2
	leaveBtn.Font = Enum.Font.GothamBold
	leaveBtn.Text = "[M] MAIN MENU"
	leaveBtn.TextColor3 = Color3.fromRGB(0, 235, 255)
	leaveBtn.TextSize = 12
	leaveBtn.Parent = gui

	local leaveStroke = Instance.new("UIStroke")
	leaveStroke.Color = Color3.fromRGB(0, 235, 255)
	leaveStroke.Thickness = 1.2
	leaveStroke.Parent = leaveBtn

	leaveBtn.MouseButton1Click:Connect(function()
		local qRemote = Remotes:FindFirstChild("QueueAction") :: RemoteEvent?
		if qRemote then
			qRemote:FireServer("LeaveMatch")
		end
	end)

	-- ========================================================================
	-- 3. BOTTOM-LEFT LOCAL PLAYER VITALS PANEL
	-- ========================================================================
	local vitalsCard = Instance.new("Frame")
	vitalsCard.Name = "LocalVitalsCard"
	vitalsCard.Size = UDim2.fromOffset(265, 76)
	vitalsCard.Position = UDim2.new(0, 22, 1, -98)
	vitalsCard.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
	vitalsCard.BackgroundTransparency = 0.2
	vitalsCard.BorderSizePixel = 0
	vitalsCard.Parent = gui

	local vStroke = Instance.new("UIStroke")
	vStroke.Color = Color3.fromRGB(0, 240, 255)
	vStroke.Thickness = 1.4
	vStroke.Parent = vitalsCard

	local hpTag = Instance.new("TextLabel")
	hpTag.Size = UDim2.fromOffset(90, 20)
	hpTag.Position = UDim2.fromOffset(14, 8)
	hpTag.BackgroundTransparency = 1
	hpTag.Font = Enum.Font.RobotoMono
	hpTag.Text = "EXOSUIT HP"
	hpTag.TextColor3 = Color3.fromRGB(160, 220, 255)
	hpTag.TextSize = 12
	hpTag.TextXAlignment = Enum.TextXAlignment.Left
	hpTag.Parent = vitalsCard

	local hpNum = Instance.new("TextLabel")
	hpNum.Size = UDim2.fromOffset(130, 32)
	hpNum.Position = UDim2.fromOffset(120, 4)
	hpNum.BackgroundTransparency = 1
	hpNum.Font = Enum.Font.Michroma
	hpNum.Text = "100"
	hpNum.TextColor3 = Color3.fromRGB(0, 245, 255)
	hpNum.TextSize = 26
	hpNum.TextXAlignment = Enum.TextXAlignment.Right
	hpNum.Parent = vitalsCard
	LocalHPNumber = hpNum

	local localHpBg = Instance.new("Frame")
	localHpBg.Size = UDim2.new(1, -28, 0, 18)
	localHpBg.Position = UDim2.fromOffset(14, 44)
	localHpBg.BackgroundColor3 = Color3.fromRGB(24, 28, 44)
	localHpBg.BorderSizePixel = 0
	localHpBg.Parent = vitalsCard

	local localHpFill = Instance.new("Frame")
	localHpFill.Size = UDim2.fromScale(1, 1)
	localHpFill.BackgroundColor3 = Color3.fromRGB(0, 245, 255)
	localHpFill.BorderSizePixel = 0
	localHpFill.Parent = localHpBg
	LocalHPBarFill = localHpFill

	-- ========================================================================
	-- 4. BOTTOM-RIGHT WEAPON & AMMO HUD + 5-WEAPON SLOT SELECTOR
	-- ========================================================================
	local weaponCard = Instance.new("Frame")
	weaponCard.Name = "WeaponHudCard"
	weaponCard.Size = UDim2.fromOffset(330, 122)
	weaponCard.Position = UDim2.new(1, -352, 1, -144)
	weaponCard.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
	weaponCard.BackgroundTransparency = 0.2
	weaponCard.BorderSizePixel = 0
	weaponCard.Parent = gui

	local wStroke = Instance.new("UIStroke")
	wStroke.Color = Color3.fromRGB(190, 50, 255)
	wStroke.Thickness = 1.4
	wStroke.Parent = weaponCard

	local wName = Instance.new("TextLabel")
	wName.Size = UDim2.new(1, -24, 0, 22)
	wName.Position = UDim2.fromOffset(12, 8)
	wName.BackgroundTransparency = 1
	wName.Font = Enum.Font.Michroma
	wName.Text = "PULSE RIFLE VX-4"
	wName.TextColor3 = Color3.fromRGB(0, 240, 255)
	wName.TextSize = 15
	wName.TextXAlignment = Enum.TextXAlignment.Left
	wName.Parent = weaponCard
	WeaponNameLabel = wName

	local ammoMag = Instance.new("TextLabel")
	ammoMag.Size = UDim2.fromOffset(90, 38)
	ammoMag.Position = UDim2.fromOffset(12, 30)
	ammoMag.BackgroundTransparency = 1
	ammoMag.Font = Enum.Font.Michroma
	ammoMag.Text = "30"
	ammoMag.TextColor3 = Color3.fromRGB(255, 255, 255)
	ammoMag.TextSize = 30
	ammoMag.TextXAlignment = Enum.TextXAlignment.Left
	ammoMag.Parent = weaponCard
	AmmoMagLabel = ammoMag

	local ammoRes = Instance.new("TextLabel")
	ammoRes.Size = UDim2.fromOffset(100, 24)
	ammoRes.Position = UDim2.fromOffset(92, 40)
	ammoRes.BackgroundTransparency = 1
	ammoRes.Font = Enum.Font.RobotoMono
	ammoRes.Text = "/ 150"
	ammoRes.TextColor3 = Color3.fromRGB(165, 180, 210)
	ammoRes.TextSize = 18
	ammoRes.TextXAlignment = Enum.TextXAlignment.Left
	ammoRes.Parent = weaponCard
	AmmoReserveLabel = ammoRes

	local reloadBanner = Instance.new("TextLabel")
	reloadBanner.Size = UDim2.fromOffset(130, 24)
	reloadBanner.Position = UDim2.fromOffset(188, 38)
	reloadBanner.BackgroundTransparency = 1
	reloadBanner.Font = Enum.Font.GothamBold
	reloadBanner.Text = "[R] RELOAD"
	reloadBanner.TextColor3 = Color3.fromRGB(255, 200, 60)
	reloadBanner.TextSize = 13
	reloadBanner.TextXAlignment = Enum.TextXAlignment.Right
	reloadBanner.Parent = weaponCard
	ReloadingBanner = reloadBanner

	-- 5 Weapon Slots Strip ([1] AR, [2] Sniper, [3] Shotgun, [4] SMG, [5] Pistol)
	local slotRow = Instance.new("Frame")
	slotRow.Size = UDim2.new(1, -20, 0, 40)
	slotRow.Position = UDim2.fromOffset(10, 74)
	slotRow.BackgroundTransparency = 1
	slotRow.Parent = weaponCard

	local shortLabels = {
		AssaultRifle = "AR",
		SniperRifle = "SNIPER",
		Shotgun = "SHOTGUN",
		SMG = "SMG",
		Pistol = "PISTOL",
	}

	SlotFrames = {}
	for idx, wId in ipairs(WeaponConfig.SlotOrder) do
		local slotBtn = Instance.new("TextButton")
		slotBtn.Size = UDim2.new(0.19, 0, 1, 0)
		slotBtn.Position = UDim2.fromScale((idx - 1) * 0.202, 0)
		slotBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
		slotBtn.BorderSizePixel = 0
		slotBtn.Font = Enum.Font.RobotoMono
		slotBtn.Text = "[" .. tostring(idx) .. "]\n" .. (shortLabels[wId] or wId)
		slotBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
		slotBtn.TextSize = 10
		slotBtn.Parent = slotRow

		local sStroke = Instance.new("UIStroke")
		sStroke.Name = "SlotStroke"
		sStroke.Color = Color3.fromRGB(70, 80, 110)
		sStroke.Thickness = 1.2
		sStroke.Parent = slotBtn

		SlotFrames[wId] = slotBtn :: any

		slotBtn.MouseButton1Click:Connect(function()
			if HUDController.OnWeaponSlotClicked then
				HUDController.OnWeaponSlotClicked(wId)
			end
		end)
	end

	-- ========================================================================
	-- 5. DYNAMIC CROSSHAIR, SNIPER SCOPE & HITMARKER
	-- ========================================================================
	local chRoot = Instance.new("Frame")
	chRoot.Name = "DynamicCrosshair"
	chRoot.AnchorPoint = Vector2.new(0.5, 0.5)
	chRoot.Size = UDim2.fromOffset(4, 4)
	chRoot.Position = UDim2.fromScale(0.5, 0.5)
	chRoot.BackgroundColor3 = Color3.fromRGB(0, 255, 240)
	chRoot.BorderSizePixel = 0
	chRoot.Parent = gui
	CrosshairRoot = chRoot

	CrosshairBars = {}
	local barDefs = {
		{ Size = UDim2.fromOffset(2, 10), Pos = UDim2.fromOffset(1, -16) }, -- Top
		{ Size = UDim2.fromOffset(2, 10), Pos = UDim2.fromOffset(1, 10) }, -- Bottom
		{ Size = UDim2.fromOffset(10, 2), Pos = UDim2.fromOffset(-16, 1) }, -- Left
		{ Size = UDim2.fromOffset(10, 2), Pos = UDim2.fromOffset(10, 1) }, -- Right
	}
	for _, b in ipairs(barDefs) do
		local bar = Instance.new("Frame")
		bar.Size = b.Size
		bar.Position = b.Pos
		bar.BackgroundColor3 = Color3.fromRGB(0, 245, 255)
		bar.BorderSizePixel = 0
		bar.Parent = chRoot
		table.insert(CrosshairBars, bar)
	end

	-- Cyber Sniper Scope Overlay
	local scopeFrame = Instance.new("Frame")
	scopeFrame.Name = "SniperScopeOverlay"
	scopeFrame.Size = UDim2.fromScale(1, 1)
	scopeFrame.BackgroundColor3 = Color3.fromRGB(4, 6, 14)
	scopeFrame.BackgroundTransparency = 0.25
	scopeFrame.Visible = false
	scopeFrame.Parent = gui
	SniperScopeFrame = scopeFrame

	local hLine = Instance.new("Frame")
	hLine.Size = UDim2.new(0.65, 0, 0, 1)
	hLine.AnchorPoint = Vector2.new(0.5, 0.5)
	hLine.Position = UDim2.fromScale(0.5, 0.5)
	hLine.BackgroundColor3 = Color3.fromRGB(195, 60, 255)
	hLine.BorderSizePixel = 0
	hLine.Parent = scopeFrame

	local vLine = Instance.new("Frame")
	vLine.Size = UDim2.new(0, 1, 0.65, 0)
	vLine.AnchorPoint = Vector2.new(0.5, 0.5)
	vLine.Position = UDim2.fromScale(0.5, 0.5)
	vLine.BackgroundColor3 = Color3.fromRGB(195, 60, 255)
	vLine.BorderSizePixel = 0
	vLine.Parent = scopeFrame

	local scopeRing = Instance.new("Frame")
	scopeRing.AnchorPoint = Vector2.new(0.5, 0.5)
	scopeRing.Size = UDim2.fromOffset(420, 420)
	scopeRing.Position = UDim2.fromScale(0.5, 0.5)
	scopeRing.BackgroundTransparency = 1
	scopeRing.Parent = scopeFrame

	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(1, 0)
	ringCorner.Parent = scopeRing

	local ringStroke = Instance.new("UIStroke")
	ringStroke.Color = Color3.fromRGB(0, 240, 255)
	ringStroke.Thickness = 2.5
	ringStroke.Parent = scopeRing

	-- Hitmarker X Overlay
	local hmFrame = Instance.new("Frame")
	hmFrame.Name = "Hitmarker"
	hmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	hmFrame.Size = UDim2.fromOffset(30, 30)
	hmFrame.Position = UDim2.fromScale(0.5, 0.5)
	hmFrame.BackgroundTransparency = 1
	hmFrame.Visible = false
	hmFrame.Parent = gui
	HitmarkerFrame = hmFrame

	for _, rot in ipairs({ 45, -45 }) do
		local slash = Instance.new("Frame")
		slash.Name = "Slash"
		slash.AnchorPoint = Vector2.new(0.5, 0.5)
		slash.Size = UDim2.fromOffset(22, 2)
		slash.Position = UDim2.fromScale(0.5, 0.5)
		slash.Rotation = rot
		slash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		slash.BorderSizePixel = 0
		slash.Parent = hmFrame
	end

	local hsBanner = Instance.new("TextLabel")
	hsBanner.AnchorPoint = Vector2.new(0.5, 0)
	hsBanner.Size = UDim2.fromOffset(220, 24)
	hsBanner.Position = UDim2.new(0.5, 0, 0.54, 0)
	hsBanner.BackgroundTransparency = 1
	hsBanner.Font = Enum.Font.Michroma
	hsBanner.Text = ""
	hsBanner.TextColor3 = Color3.fromRGB(255, 45, 165)
	hsBanner.TextSize = 14
	hsBanner.Parent = gui
	HeadshotLabel = hsBanner

	-- ========================================================================
	-- 6. KILL FEED (Top-Right)
	-- ========================================================================
	local kfFrame = Instance.new("Frame")
	kfFrame.Name = "KillFeed"
	kfFrame.Size = UDim2.fromOffset(310, 160)
	kfFrame.Position = UDim2.new(1, -326, 0, 108)
	kfFrame.BackgroundTransparency = 1
	kfFrame.Parent = gui
	KillFeedContainer = kfFrame

	local kfLayout = Instance.new("UIListLayout")
	kfLayout.Padding = UDim.new(0, 5)
	kfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	kfLayout.Parent = kfFrame

	-- ========================================================================
	-- 7. SMOOTH "ARENA CHANGING" TRANSITION ANIMATION OVERLAY (Every 120s)
	-- ========================================================================
	local arenaOverlay = Instance.new("Frame")
	arenaOverlay.Name = "ArenaChangingOverlay"
	arenaOverlay.Size = UDim2.fromScale(1, 1)
	arenaOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 22)
	arenaOverlay.BackgroundTransparency = 1
	arenaOverlay.Visible = false
	arenaOverlay.ZIndex = 20
	arenaOverlay.Parent = gui
	ArenaTransitionOverlay = arenaOverlay

	local arenaBanner = Instance.new("Frame")
	arenaBanner.AnchorPoint = Vector2.new(0.5, 0.5)
	arenaBanner.Size = UDim2.fromOffset(640, 170)
	arenaBanner.Position = UDim2.fromScale(0.5, 0.5)
	arenaBanner.BackgroundColor3 = Color3.fromRGB(16, 12, 34)
	arenaBanner.BackgroundTransparency = 0.1
	arenaBanner.BorderSizePixel = 0
	arenaBanner.ZIndex = 21
	arenaBanner.Parent = arenaOverlay

	local abStroke = Instance.new("UIStroke")
	abStroke.Color = Color3.fromRGB(0, 240, 255)
	abStroke.Thickness = 2.4
	abStroke.Parent = arenaBanner

	local abTitle = Instance.new("TextLabel")
	abTitle.Size = UDim2.new(1, -24, 0, 44)
	abTitle.Position = UDim2.fromOffset(12, 18)
	abTitle.BackgroundTransparency = 1
	abTitle.Font = Enum.Font.Michroma
	abTitle.Text = "ARENA CHANGING // 2:00 ROTATION"
	abTitle.TextColor3 = Color3.fromRGB(0, 245, 255)
	abTitle.TextSize = 24
	abTitle.ZIndex = 22
	abTitle.Parent = arenaBanner
	ArenaTransitionTitle = abTitle

	local abSub = Instance.new("TextLabel")
	abSub.Size = UDim2.new(1, -24, 0, 32)
	abSub.Position = UDim2.fromOffset(12, 68)
	abSub.BackgroundTransparency = 1
	abSub.Font = Enum.Font.GothamBold
	abSub.Text = "DEPLOYING TO NEXT SECTOR..."
	abSub.TextColor3 = Color3.fromRGB(255, 60, 190)
	abSub.TextSize = 18
	abSub.ZIndex = 22
	abSub.Parent = arenaBanner
	ArenaTransitionSub = abSub

	local abHP = Instance.new("TextLabel")
	abHP.Size = UDim2.new(1, -24, 0, 28)
	abHP.Position = UDim2.fromOffset(12, 114)
	abHP.BackgroundTransparency = 1
	abHP.Font = Enum.Font.RobotoMono
	abHP.Text = "BOTH PLAYERS' HP & SCORE PRESERVED"
	abHP.TextColor3 = Color3.fromRGB(0, 255, 190)
	abHP.TextSize = 15
	abHP.ZIndex = 22
	abHP.Parent = arenaBanner
	ArenaTransitionHPNote = abHP

	-- ========================================================================
	-- 8. MATCH VICTORY / DEFEAT SUMMARY OVERLAY
	-- ========================================================================
	local endOverlay = Instance.new("Frame")
	endOverlay.Name = "MatchEndedOverlay"
	endOverlay.Size = UDim2.fromScale(1, 1)
	endOverlay.BackgroundColor3 = Color3.fromRGB(6, 8, 18)
	endOverlay.BackgroundTransparency = 0.25
	endOverlay.Visible = false
	endOverlay.ZIndex = 25
	endOverlay.Parent = gui
	MatchEndOverlay = endOverlay

	local endTitle = Instance.new("TextLabel")
	endTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	endTitle.Size = UDim2.fromOffset(700, 64)
	endTitle.Position = UDim2.fromScale(0.5, 0.44)
	endTitle.BackgroundTransparency = 1
	endTitle.Font = Enum.Font.Michroma
	endTitle.Text = "VICTORY"
	endTitle.TextColor3 = Color3.fromRGB(0, 255, 200)
	endTitle.TextSize = 42
	endTitle.ZIndex = 26
	endTitle.Parent = endOverlay
	MatchEndTitle = endTitle

	local endSub = Instance.new("TextLabel")
	endSub.AnchorPoint = Vector2.new(0.5, 0.5)
	endSub.Size = UDim2.fromOffset(700, 40)
	endSub.Position = UDim2.fromScale(0.5, 0.54)
	endSub.BackgroundTransparency = 1
	endSub.Font = Enum.Font.RobotoMono
	endSub.Text = "+150 COINS // +200 XP // RETURNING TO CYBERCITY MENU..."
	endSub.TextColor3 = Color3.fromRGB(220, 235, 255)
	endSub.TextSize = 18
	endSub.ZIndex = 26
	endSub.Parent = endOverlay
	MatchEndSub = endSub
end

function HUDController.SetVisible(visible: boolean)
	if HudGui then
		HudGui.Enabled = visible
	end
	if not visible and MatchEndOverlay then
		MatchEndOverlay.Visible = false
	end
end

function HUDController.UpdateMatchSnapshot(snapshot: any)
	if type(snapshot) ~= "table" then
		return
	end

	if P1NameLabel then
		P1NameLabel.Text = string.upper(tostring(snapshot.P1Name or "PLAYER 1"))
	end
	if P2NameLabel then
		P2NameLabel.Text = string.upper(tostring(snapshot.P2Name or "PLAYER 2"))
	end
	if P1KillsLabel then
		P1KillsLabel.Text = tostring(snapshot.P1Kills or 0)
	end
	if P2KillsLabel then
		P2KillsLabel.Text = tostring(snapshot.P2Kills or 0)
	end

	local p1HP = math.clamp(tonumber(snapshot.P1Health) or 100, 0, 100)
	local p2HP = math.clamp(tonumber(snapshot.P2Health) or 100, 0, 100)

	if P1HealthBarFill then
		TweenService:Create(P1HealthBarFill, TweenInfo.new(0.15), {
			Size = UDim2.fromScale(p1HP / 100, 1),
		}):Play()
	end
	if P2HealthBarFill then
		TweenService:Create(P2HealthBarFill, TweenInfo.new(0.15), {
			Size = UDim2.fromScale(p2HP / 100, 1),
		}):Play()
	end
	if P1HealthText then
		P1HealthText.Text = tostring(p1HP) .. " / 100 HP"
	end
	if P2HealthText then
		P2HealthText.Text = tostring(p2HP) .. " / 100 HP"
	end

	-- Update Local Player Bottom-Left Vitals
	local myHP = if snapshot.P1Name == LocalPlayer.Name then p1HP else p2HP
	if LocalHPNumber then
		LocalHPNumber.Text = tostring(myHP)
		LocalHPNumber.TextColor3 = if myHP > 35
			then Color3.fromRGB(0, 245, 255)
			else Color3.fromRGB(255, 45, 110)
	end
	if LocalHPBarFill then
		TweenService:Create(LocalHPBarFill, TweenInfo.new(0.15), {
			Size = UDim2.fromScale(myHP / 100, 1),
			BackgroundColor3 = if myHP > 35
				then Color3.fromRGB(0, 245, 255)
				else Color3.fromRGB(255, 45, 110),
		}):Play()
	end

	-- Update 120-Second Arena Rotation Countdown Timer
	local remSeconds = tonumber(snapshot.ArenaTimeRemaining) or 120
	if ArenaTimerLabel then
		ArenaTimerLabel.Text = formatTimeMMSS(remSeconds)
		if remSeconds <= 10 then
			ArenaTimerLabel.TextColor3 = Color3.fromRGB(255, 50, 165)
			if remSeconds ~= lastWarningSecond and remSeconds > 0 then
				lastWarningSecond = remSeconds
				SoundManager.Play2D("ArenaWarning", 1.15, 0.35)
			end
		else
			ArenaTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	if ArenaNameLabel and snapshot.ArenaName then
		ArenaNameLabel.Text = tostring(snapshot.ArenaName)
	end
	if WinGoalLabel and snapshot.WinCondition then
		WinGoalLabel.Text = "FIRST TO " .. tostring(snapshot.WinCondition) .. " KILLS"
	end
end

function HUDController.UpdateWeaponHUD(equippedWeaponId: string, isReloading: boolean, ammoMap: any)
	local stats = WeaponConfig.GetWeapon(equippedWeaponId)
	if not stats then
		return
	end

	if WeaponNameLabel then
		WeaponNameLabel.Text = stats.Name
		WeaponNameLabel.TextColor3 = stats.NeonColor
	end

	local wAmmo = if type(ammoMap) == "table" then ammoMap[equippedWeaponId] else nil
	local mag = if wAmmo then wAmmo.Mag else stats.MagazineSize
	local res = if wAmmo then wAmmo.Reserve else stats.ReserveAmmo

	if AmmoMagLabel then
		AmmoMagLabel.Text = tostring(mag)
		AmmoMagLabel.TextColor3 = if mag > 0
			then Color3.fromRGB(255, 255, 255)
			else Color3.fromRGB(255, 55, 100)
	end
	if AmmoReserveLabel then
		AmmoReserveLabel.Text = "/ " .. tostring(res)
	end
	if ReloadingBanner then
		ReloadingBanner.Text = if isReloading then "RELOADING..." else "[R] RELOAD"
		ReloadingBanner.TextColor3 = if isReloading
			then Color3.fromRGB(255, 50, 175)
			else Color3.fromRGB(160, 220, 255)
	end

	for wId, btn in pairs(SlotFrames) do
		local stroke = btn:FindFirstChild("SlotStroke") :: UIStroke?
		local isSelected = (wId == equippedWeaponId)
		btn.BackgroundColor3 = if isSelected
			then Color3.fromRGB(45, 24, 72)
			else Color3.fromRGB(18, 22, 36)
		if stroke then
			stroke.Color = if isSelected
				then Color3.fromRGB(0, 245, 255)
				else Color3.fromRGB(70, 80, 110)
			stroke.Thickness = if isSelected then 2.0 else 1.1
		end
	end
end

function HUDController.SetCrosshairState(spreadPixels: number, isAiming: boolean, useSniperScope: boolean)
	if SniperScopeFrame then
		SniperScopeFrame.Visible = (isAiming and useSniperScope)
	end
	if CrosshairRoot then
		CrosshairRoot.Visible = not (isAiming and useSniperScope)
	end
	if #CrosshairBars == 4 then
		local gap = math.clamp(math.floor(spreadPixels), 4, 38)
		CrosshairBars[1].Position = UDim2.fromOffset(1, -(gap + 10))
		CrosshairBars[2].Position = UDim2.fromOffset(1, gap)
		CrosshairBars[3].Position = UDim2.fromOffset(-(gap + 10), 1)
		CrosshairBars[4].Position = UDim2.fromOffset(gap, 1)
	end
end

function HUDController.PlayArenaRotationAnimation(payload: any)
	if not ArenaTransitionOverlay or not ArenaTransitionTitle or not ArenaTransitionSub or not ArenaTransitionHPNote then
		return
	end

	SoundManager.Play2D("ArenaSwitch")

	ArenaTransitionTitle.Text = "ARENA CHANGING // " .. tostring(payload.NewArenaName or "NEXT SECTOR")
	ArenaTransitionSub.Text = tostring(payload.NewArenaSubtitle or "2-MINUTE ROTATION COMPLETE")
	ArenaTransitionHPNote.Text = string.format(
		"HP PRESERVED — P1: %d HP  |  P2: %d HP",
		tonumber(payload.P1PreservedHP) or 100,
		tonumber(payload.P2PreservedHP) or 100
	)

	ArenaTransitionOverlay.BackgroundTransparency = 1
	ArenaTransitionOverlay.Visible = true

	TweenService:Create(ArenaTransitionOverlay, TweenInfo.new(0.35), {
		BackgroundTransparency = 0.15,
	}):Play()

	task.delay(1.85, function()
		if ArenaTransitionOverlay then
			local fadeOut = TweenService:Create(ArenaTransitionOverlay, TweenInfo.new(0.45), {
				BackgroundTransparency = 1,
			})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				if ArenaTransitionOverlay then
					ArenaTransitionOverlay.Visible = false
				end
			end)
		end
	end)
end

function HUDController.ShowDamageIndicator(info: any)
	if type(info) ~= "table" then
		return
	end

	if info.Type == "Dealt" then
		local isHS = (info.IsHeadshot == true)
		SoundManager.Play2D(if isHS then "Headshot" else "Hitmarker")

		if HitmarkerFrame then
			HitmarkerFrame.Visible = true
			local color = if isHS then Color3.fromRGB(255, 40, 165) else Color3.fromRGB(0, 255, 240)
			for _, child in ipairs(HitmarkerFrame:GetChildren()) do
				if child:IsA("Frame") then
					child.BackgroundColor3 = color
				end
			end
			task.delay(0.16, function()
				if HitmarkerFrame then
					HitmarkerFrame.Visible = false
				end
			end)
		end

		if HeadshotLabel then
			HeadshotLabel.Text = if isHS
				then ("CRITICAL HEADSHOT! -" .. tostring(info.Damage))
				else ("-" .. tostring(info.Damage) .. " HP")
			HeadshotLabel.TextColor3 = if isHS
				then Color3.fromRGB(255, 45, 175)
				else Color3.fromRGB(0, 245, 255)
			task.delay(0.65, function()
				if HeadshotLabel then
					HeadshotLabel.Text = ""
				end
			end)
		end

		-- Spawn 3D Floating Billboard Damage Number at hit position
		if typeof(info.HitPosition) == "Vector3" then
			local anchor = Instance.new("Part")
			anchor.Size = Vector3.new(0.2, 0.2, 0.2)
			anchor.Transparency = 1
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanQuery = false
			anchor.Position = info.HitPosition + Vector3.new(0, 1.2, 0)
			anchor.Parent = Workspace

			local bGui = Instance.new("BillboardGui")
			bGui.Size = UDim2.fromOffset(100, 36)
			bGui.AlwaysOnTop = true
			bGui.Parent = anchor

			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.fromScale(1, 1)
			txt.BackgroundTransparency = 1
			txt.Font = Enum.Font.Michroma
			txt.Text = "-" .. tostring(info.Damage)
			txt.TextColor3 = if isHS then Color3.fromRGB(255, 40, 165) else Color3.fromRGB(0, 255, 240)
			txt.TextSize = if isHS then 22 else 17
			txt.Parent = bGui

			TweenService:Create(anchor, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = anchor.Position + Vector3.new(0, 3.2, 0),
			}):Play()

			task.delay(0.65, function()
				anchor:Destroy()
			end)
		end
	elseif info.Type == "Taken" then
		if DamageVignette then
			DamageVignette.BackgroundTransparency = 0.55
			TweenService:Create(DamageVignette, TweenInfo.new(0.45), {
				BackgroundTransparency = 1,
			}):Play()
		end
	end
end

function HUDController.PushKillFeed(killData: any)
	if not KillFeedContainer or type(killData) ~= "table" then
		return
	end

	local item = Instance.new("Frame")
	item.Size = UDim2.fromOffset(300, 28)
	item.BackgroundColor3 = Color3.fromRGB(14, 16, 30)
	item.BackgroundTransparency = 0.2
	item.BorderSizePixel = 0
	item.Parent = KillFeedContainer

	local stroke = Instance.new("UIStroke")
	stroke.Color = if killData.IsHeadshot
		then Color3.fromRGB(255, 45, 175)
		else Color3.fromRGB(0, 235, 255)
	stroke.Thickness = 1.2
	stroke.Parent = item

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -12, 1, 0)
	lbl.Position = UDim2.fromOffset(6, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.RobotoMono
	lbl.Text = string.format(
		"%s  [%s%s]  %s",
		tostring(killData.Killer),
		tostring(killData.Weapon),
		if killData.IsHeadshot then " ★HS" else "",
		tostring(killData.Victim)
	)
	lbl.TextColor3 = Color3.fromRGB(235, 245, 255)
	lbl.TextSize = 11
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Parent = item

	task.delay(4.5, function()
		if item.Parent then
			item:Destroy()
		end
	end)
end

function HUDController.ShowMatchEnded(summary: any)
	if not MatchEndOverlay or not MatchEndTitle or not MatchEndSub then
		return
	end
	SoundManager.Play2D("MatchVictory")

	local won = (summary.WinnerName == LocalPlayer.Name)
	MatchEndTitle.Text = if won
		then "VICTORY // CHAMPION"
		else ("DEFEAT // WINNER: " .. tostring(summary.WinnerName))
	MatchEndTitle.TextColor3 = if won
		then Color3.fromRGB(0, 255, 200)
		else Color3.fromRGB(255, 55, 150)

	MatchEndSub.Text = string.format(
		"FINAL SCORE: %s (%d) vs %s (%d) // RETURNING TO MAIN MENU...",
		tostring(summary.P1Name),
		tonumber(summary.P1Kills) or 0,
		tostring(summary.P2Name),
		tonumber(summary.P2Kills) or 0
	)
	MatchEndOverlay.Visible = true
end

return HUDController

