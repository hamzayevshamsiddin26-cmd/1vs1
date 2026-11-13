--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: StarterPlayerScripts.FPSController
	Description: Handles the First-Person Shooting Camera, 3D Cyber Viewmodel (arms +
	neon weapon), ADS aiming, recoil recovery, bullet spread calculation, reloading,
	weapon switching (keys 1-5 & scroll wheel), neon tracer beams, and hit spark effects.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))
local ArenaConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ArenaConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local SoundManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundManager"))
local HUDController = require(script.Parent:WaitForChild("HUDController"))

local FPSController = {}

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local InActiveMatch = false
local EquippedWeaponId = "AssaultRifle"
local IsReloading = false
local ReloadStartClock = 0
local ReloadDuration = 2.0
local IsAiming = false
local IsFiringHeld = false
local IsSprinting = false
local IsCrouching = false
local InspectEndTime = 0
local LastLocalFireClock = 0

local AmmoState: { [string]: { Mag: number, Reserve: number } } = {}
local BaseFOV = 78
local EquippedSkinId = "DefaultCyan"

-- Viewmodel state
local ViewmodelContainer: Model? = nil
local ViewmodelRoot: BasePart? = nil
local ViewmodelMuzzle: BasePart? = nil
local RecoilKickOffset = Vector3.zero
local RecoilPitchAccum = 0
local SwayOffset = Vector2.zero

local function getCamera(): Camera
	return Workspace.CurrentCamera
end

local function destroyViewmodel()
	if ViewmodelContainer then
		ViewmodelContainer:Destroy()
		ViewmodelContainer = nil
		ViewmodelRoot = nil
		ViewmodelMuzzle = nil
	end
end

function FPSController.RebuildViewmodel()
	destroyViewmodel()
	if not InActiveMatch then
		return
	end

	local cam = getCamera()
	if not cam then
		return
	end

	local skin = ShopConfig.GetWeaponSkin(EquippedSkinId)
	local model, handle, muzzle = WeaponConfig.BuildWeaponModel(
		EquippedWeaponId,
		skin.PrimaryNeon,
		skin.SecondaryColor
	)
	model.Name = "FPSViewmodel"

	-- 1. Attach Right Trigger Forearm & Tactical Glove to Pistol Grip
	local rightArm = Instance.new("Part")
	rightArm.Name = "TacticalArmR"
	rightArm.Size = Vector3.new(0.28, 0.28, 1.35)
	rightArm.Color = Color3.fromRGB(54, 66, 50)
	rightArm.Material = Enum.Material.Fabric
	rightArm.CanCollide = false
	rightArm.CanQuery = false
	rightArm.CanTouch = false
	rightArm.Massless = true
	rightArm.CFrame = handle.CFrame * CFrame.new(0.18, -0.32, 0.85)
	rightArm.Parent = model

	local armWeldR = Instance.new("WeldConstraint")
	armWeldR.Part0 = handle
	armWeldR.Part1 = rightArm
	armWeldR.Parent = rightArm

	-- 2. Attach Left Support Forearm & Glove Gripping Front Handguard (Two-Handed Hold!)
	local leftArm = Instance.new("Part")
	leftArm.Name = "TacticalArmL"
	leftArm.Size = Vector3.new(0.26, 0.26, 1.65)
	leftArm.Color = Color3.fromRGB(54, 66, 50)
	leftArm.Material = Enum.Material.Fabric
	leftArm.CanCollide = false
	leftArm.CanQuery = false
	leftArm.CanTouch = false
	leftArm.Massless = true
	leftArm.CFrame = handle.CFrame * CFrame.new(-0.42, -0.26, 0.15) * CFrame.Angles(math.rad(12), math.rad(-28), 0)
	leftArm.Parent = model

	local armWeldL = Instance.new("WeldConstraint")
	armWeldL.Part0 = handle
	armWeldL.Part1 = leftArm
	armWeldL.Parent = leftArm

	local leftGlove = Instance.new("Part")
	leftGlove.Name = "LeftSupportGlove"
	leftGlove.Size = Vector3.new(0.32, 0.30, 0.36)
	leftGlove.Color = Color3.fromRGB(28, 30, 28)
	leftGlove.Material = Enum.Material.SmoothPlastic
	leftGlove.CanCollide = false
	leftGlove.CanQuery = false
	leftGlove.CanTouch = false
	leftGlove.Massless = true
	leftGlove.CFrame = handle.CFrame * CFrame.new(-0.04, -0.08, -0.68)
	leftGlove.Parent = model

	local gloveWeldL = Instance.new("WeldConstraint")
	gloveWeldL.Part0 = handle
	gloveWeldL.Part1 = leftGlove
	gloveWeldL.Parent = leftGlove

	handle.Anchored = true
	model.Parent = cam

	ViewmodelContainer = model
	ViewmodelRoot = handle
	ViewmodelMuzzle = muzzle
end

function FPSController.SetMatchActive(active: boolean)
	if InActiveMatch == active then
		return
	end
	InActiveMatch = active

	local cam = getCamera()
	if active then
		LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		LocalPlayer.CameraMinZoomDistance = 0.5
		LocalPlayer.CameraMaxZoomDistance = 0.5
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			cam.FieldOfView = BaseFOV
		end
		UserInputService.MouseIconEnabled = false
		FPSController.RebuildViewmodel()
	else
		IsFiringHeld = false
		IsAiming = false
		destroyViewmodel()
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		LocalPlayer.CameraMinZoomDistance = 8
		LocalPlayer.CameraMaxZoomDistance = 16
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end

function FPSController.ApplySettings(settings: any)
	if type(settings) ~= "table" then
		return
	end
	if type(settings.FOV) == "number" then
		BaseFOV = math.clamp(settings.FOV, 60, 105)
	end
end

function FPSController.SetEquippedSkin(skinId: string)
	if type(skinId) == "string" and skinId ~= EquippedSkinId then
		EquippedSkinId = skinId
		if InActiveMatch then
			FPSController.RebuildViewmodel()
		end
	end
end

function FPSController.UpdateWeaponStateFromServer(state: any)
	if type(state) ~= "table" then
		return
	end

	local prevWeapon = EquippedWeaponId
	if type(state.EquippedWeapon) == "string" then
		EquippedWeaponId = state.EquippedWeapon
	end
	IsReloading = (state.IsReloading == true)
	if type(state.Ammo) == "table" then
		AmmoState = state.Ammo
	end

	if prevWeapon ~= EquippedWeaponId and InActiveMatch then
		SoundManager.Play2D("WeaponSwitch")
		FPSController.RebuildViewmodel()
	end

	HUDController.UpdateWeaponHUD(EquippedWeaponId, IsReloading, AmmoState)
end

function FPSController.RequestSwitchWeapon(weaponId: string)
	if not InActiveMatch or weaponId == EquippedWeaponId then
		return
	end
	local stats = WeaponConfig.GetWeapon(weaponId)
	if not stats then
		return
	end

	IsAiming = false
	local switchRemote = Remotes:FindFirstChild("SwitchWeapon") :: RemoteEvent?
	if switchRemote then
		switchRemote:FireServer(weaponId)
	end
end

function FPSController.RequestReload()
	if not InActiveMatch or IsReloading then
		return
	end
	local stats = WeaponConfig.GetWeapon(EquippedWeaponId)
	if not stats then
		return
	end
	local curAmmo = AmmoState[EquippedWeaponId]
	if curAmmo and (curAmmo.Mag >= stats.MagazineSize or curAmmo.Reserve <= 0) then
		return
	end

	ReloadStartClock = os.clock()
	ReloadDuration = stats.ReloadTime
	SoundManager.Play2D("Reload")
	local reloadRemote = Remotes:FindFirstChild("ReloadWeapon") :: RemoteEvent?
	if reloadRemote then
		reloadRemote:FireServer()
	end
end

local function computeSpreadDirection(baseDirection: Vector3, spreadDegrees: number): Vector3
	if spreadDegrees <= 0.01 then
		return baseDirection.Unit
	end
	local spreadRad = math.rad(spreadDegrees)
	local rx = (math.random() - 0.5) * 2 * spreadRad
	local ry = (math.random() - 0.5) * 2 * spreadRad
	local cf = CFrame.lookAt(Vector3.zero, baseDirection) * CFrame.Angles(rx, ry, 0)
	return cf.LookVector.Unit
end

local function attemptFireShot()
	if not InActiveMatch or IsReloading then
		return
	end

	local char = LocalPlayer.Character
	local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
	if not hum or hum.Health <= 0 then
		return
	end

	local stats = WeaponConfig.GetWeapon(EquippedWeaponId)
	if not stats then
		return
	end

	local now = os.clock()
	if (now - LastLocalFireClock) < stats.FireRate then
		return
	end

	local wAmmo = AmmoState[EquippedWeaponId]
	if wAmmo and wAmmo.Mag <= 0 then
		FPSController.RequestReload()
		return
	end

	LastLocalFireClock = now
	if wAmmo then
		wAmmo.Mag = math.max(0, wAmmo.Mag - 1)
		HUDController.UpdateWeaponHUD(EquippedWeaponId, IsReloading, AmmoState)
	end

	local cam = getCamera()
	local origin = cam.CFrame.Position
	local baseLook = cam.CFrame.LookVector
	local spreadDeg = if IsAiming then stats.AdsSpread else stats.HipSpread

	local directions: { Vector3 } = {}
	for _ = 1, stats.Pellets do
		table.insert(directions, computeSpreadDirection(baseLook, spreadDeg))
	end

	-- Apply camera & viewmodel recoil kick
	RecoilKickOffset = Vector3.new(
		(math.random() - 0.5) * 0.06,
		0.05,
		stats.RecoilKickback
	)
	RecoilPitchAccum = math.min(RecoilPitchAccum + stats.RecoilPitch * 0.35, 8.0)

	-- Local muzzle flash blink & 3D Ejected Brass Shell Casing
	if ViewmodelMuzzle then
		local light = ViewmodelMuzzle:FindFirstChild("MuzzleFlashLight") :: PointLight?
		if light then
			light.Enabled = true
			task.delay(0.05, function()
				if light then
					light.Enabled = false
				end
			end)
		end
	end

	if ViewmodelRoot then
		local casing = Instance.new("Part")
		casing.Name = "BrassCasing"
		casing.Size = if EquippedWeaponId == "Shotgun"
			then Vector3.new(0.08, 0.08, 0.22)
			else Vector3.new(0.05, 0.05, 0.16)
		casing.Color = if EquippedWeaponId == "Shotgun"
			then Color3.fromRGB(205, 42, 42)
			else Color3.fromRGB(230, 184, 50)
		casing.Material = Enum.Material.Metal
		casing.CanCollide = false
		casing.CanQuery = false
		casing.CanTouch = false
		casing.CFrame = ViewmodelRoot.CFrame * CFrame.new(0.18, 0.12, -0.15)
		casing.Parent = Workspace
		casing.AssemblyLinearVelocity = (cam.CFrame.RightVector * 8) + (cam.CFrame.UpVector * 6)
		casing.AssemblyAngularVelocity = Vector3.new(18, 25, 12)
		task.delay(0.75, function()
			if casing then
				casing:Destroy()
			end
		end)
	end

	local fireRemote = Remotes:FindFirstChild("FireWeapon") :: RemoteEvent?
	if fireRemote then
		fireRemote:FireServer(origin, directions)
	end
end

function FPSController.RenderWeaponFiredVisual(
	shooter: Player?,
	weaponId: string,
	origin: Vector3,
	endpoints: { Vector3 },
	hitEffects: { { Pos: Vector3, IsCharacter: boolean, IsHeadshot: boolean } },
	neonColor: Color3
)
	local stats = WeaponConfig.GetWeapon(weaponId)
	if stats then
		local soundOriginPart: Instance? = nil
		if shooter and shooter.Character then
			soundOriginPart = shooter.Character:FindFirstChild("Head")
		end
		SoundManager.PlayWeaponFire(stats.FireSoundId, stats.FirePitch, soundOriginPart)
	end

	local visualStart = origin
	if shooter == LocalPlayer and ViewmodelMuzzle then
		visualStart = ViewmodelMuzzle.Position
	end

	-- Render neon laser tracer beam for each pellet
	for _, endPos in ipairs(endpoints) do
		local dist = (endPos - visualStart).Magnitude
		if dist > 0.5 then
			local beamPart = Instance.new("Part")
			beamPart.Name = "NeonTracer"
			beamPart.Anchored = true
			beamPart.CanCollide = false
			beamPart.CanQuery = false
			beamPart.CanTouch = false
			beamPart.Material = Enum.Material.Neon
			beamPart.Color = neonColor
			beamPart.Transparency = 0.15
			beamPart.Size = Vector3.new(0.09, 0.09, dist)
			beamPart.CFrame = CFrame.lookAt(visualStart, endPos) * CFrame.new(0, 0, -dist * 0.5)
			beamPart.Parent = Workspace

			TweenService:Create(beamPart, TweenInfo.new(0.12), {
				Transparency = 1,
				Size = Vector3.new(0.02, 0.02, dist),
			}):Play()

			task.delay(0.14, function()
				beamPart:Destroy()
			end)
		end
	end

	-- Render neon impact spark cubes
	for _, hit in ipairs(hitEffects) do
		local spark = Instance.new("Part")
		spark.Name = "NeonHitSpark"
		spark.Anchored = true
		spark.CanCollide = false
		spark.CanQuery = false
		spark.CanTouch = false
		spark.Material = Enum.Material.Neon
		spark.Color = if hit.IsHeadshot
			then Color3.fromRGB(255, 40, 170)
			elseif hit.IsCharacter then Color3.fromRGB(0, 255, 220)
			else neonColor
		spark.Size = Vector3.new(0.45, 0.45, 0.45)
		spark.CFrame = CFrame.new(hit.Pos) * CFrame.Angles(math.random(), math.random(), math.random())
		spark.Parent = Workspace

		TweenService:Create(spark, TweenInfo.new(0.22), {
			Size = Vector3.new(1.35, 1.35, 1.35),
			Transparency = 1,
		}):Play()

		task.delay(0.24, function()
			spark:Destroy()
		end)
	end
end

function FPSController.Init()
	HUDController.OnWeaponSlotClicked = function(weaponId: string)
		FPSController.RequestSwitchWeapon(weaponId)
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if input.KeyCode == Enum.KeyCode.M and InActiveMatch then
			local qRemote = Remotes:FindFirstChild("QueueAction") :: RemoteEvent?
			if qRemote then
				qRemote:FireServer("LeaveMatch")
			end
			return
		end

		if gameProcessed or not InActiveMatch then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsFiringHeld = true
			attemptFireShot()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			IsAiming = true
			local aimRemote = Remotes:FindFirstChild("AimState") :: RemoteEvent?
			if aimRemote then
				aimRemote:FireServer(true)
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			FPSController.RequestReload()
		elseif input.KeyCode == Enum.KeyCode.One then
			FPSController.RequestSwitchWeapon("AssaultRifle")
		elseif input.KeyCode == Enum.KeyCode.Two then
			FPSController.RequestSwitchWeapon("SniperRifle")
		elseif input.KeyCode == Enum.KeyCode.Three then
			FPSController.RequestSwitchWeapon("Shotgun")
		elseif input.KeyCode == Enum.KeyCode.Four then
			FPSController.RequestSwitchWeapon("SMG")
		elseif input.KeyCode == Enum.KeyCode.Five then
			FPSController.RequestSwitchWeapon("Pistol")
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsFiringHeld = false
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if IsAiming then
				IsAiming = false
				local aimRemote = Remotes:FindFirstChild("AimState") :: RemoteEvent?
				if aimRemote then
					aimRemote:FireServer(false)
				end
			end
		end
	end)

	-- Scroll wheel weapon switching
	UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or not InActiveMatch then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local stats = WeaponConfig.GetWeapon(EquippedWeaponId)
			local currentSlot = if stats then stats.Slot else 1
			local direction = if input.Position.Z > 0 then -1 else 1
			local nextSlot = ((currentSlot - 1 + direction) % #WeaponConfig.SlotOrder) + 1
			local nextWeapon = WeaponConfig.SlotOrder[nextSlot]
			if nextWeapon then
				FPSController.RequestSwitchWeapon(nextWeapon)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			SwayOffset = Vector2.new(
				math.clamp(-input.Delta.X * 0.002, -0.08, 0.08),
				math.clamp(-input.Delta.Y * 0.002, -0.08, 0.08)
			)
		end
	end)

	-- RenderStepped loop for Menu Camera vista OR First-Person Viewmodel + Auto-Fire
	RunService.RenderStepped:Connect(function(dt: number)
		local cam = getCamera()
		if not cam then
			return
		end

		if not InActiveMatch then
			-- Cinematic Cybercity Neon Street Camera Vista (Matches Image 1)
			cam.CameraType = Enum.CameraType.Scriptable
			cam.FieldOfView = 68
			local t = os.clock()
			local driftX = math.sin(t * 0.35) * 1.8
			local driftY = math.cos(t * 0.5) * 0.35
			cam.CFrame = ArenaConfig.MenuCameraCFrame * CFrame.new(driftX, driftY, 0)
			return
		end

		local stats = WeaponConfig.GetWeapon(EquippedWeaponId) or WeaponConfig.Weapons.AssaultRifle

		-- Full-auto firing for Assault Rifle & SMG
		if IsFiringHeld and stats.FireMode == "Auto" then
			attemptFireShot()
		end

		-- Smooth FOV interpolation for ADS
		local targetFOV = if IsAiming then stats.AdsFov else BaseFOV
		cam.FieldOfView = cam.FieldOfView + (targetFOV - cam.FieldOfView) * math.min(1, dt * 14)

		-- Recover recoil & sway
		RecoilKickOffset = RecoilKickOffset:Lerp(Vector3.zero, math.min(1, dt * 16))
		SwayOffset = SwayOffset:Lerp(Vector2.zero, math.min(1, dt * 10))
		if RecoilPitchAccum > 0.01 then
			local step = math.min(RecoilPitchAccum, dt * 12)
			RecoilPitchAccum -= step
			cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(step * 0.15), 0, 0)
		end

		-- Calculate walk bobbing
		local char = LocalPlayer.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local speed = if root then Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude else 0
		local bobTime = os.clock() * 9
		local bobX = if speed > 1 then math.cos(bobTime) * 0.04 else 0
		local bobY = if speed > 1 then math.abs(math.sin(bobTime)) * 0.04 else 0

		-- Position 3D First-Person Viewmodel
		if ViewmodelRoot and ViewmodelContainer then
			local hideViewmodelForScope = (IsAiming and stats.UseSniperScope)
			for _, part in ipairs(ViewmodelContainer:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = if hideViewmodelForScope then 1 else 0
				end
			end

			local baseOffset = if IsAiming
				then CFrame.new(0, -0.26, -1.05)
				else CFrame.new(0.52, -0.44, -1.25)

			local reloadTilt = CFrame.identity
			if IsReloading then
				local prog = math.clamp((os.clock() - ReloadStartClock) / math.max(0.5, ReloadDuration), 0, 1)
				if prog < 0.22 then
					local p = prog / 0.22
					reloadTilt = CFrame.new(-0.12 * p, -0.14 * p, 0) * CFrame.Angles(math.rad(16 * p), 0, math.rad(34 * p))
				elseif prog < 0.50 then
					local p = (prog - 0.22) / 0.28
					reloadTilt = CFrame.new(-0.12, -0.14 - 0.12 * math.sin(p * math.pi), 0) * CFrame.Angles(math.rad(16), 0, math.rad(34))
				elseif prog < 0.76 then
					local p = (prog - 0.50) / 0.26
					local jolt = if p > 0.65 then math.sin(((p - 0.65) / 0.35) * math.pi) * 0.14 else 0
					reloadTilt = CFrame.new(-0.12, -0.14 + jolt, 0) * CFrame.Angles(math.rad(16 + jolt * 40), 0, math.rad(34 - 10 * p))
				else
					local p = (prog - 0.76) / 0.24
					local boltPull = math.sin(p * math.pi) * 0.22
					reloadTilt = CFrame.new(-0.12 * (1 - p), -0.14 * (1 - p), boltPull) * CFrame.Angles(math.rad(16 * (1 - p)), 0, math.rad(24 * (1 - p)))
				end
			end

			ViewmodelRoot.CFrame = cam.CFrame
				* baseOffset
				* CFrame.new(
					bobX + SwayOffset.X + RecoilKickOffset.X,
					bobY + SwayOffset.Y + RecoilKickOffset.Y,
					RecoilKickOffset.Z
				)
				* reloadTilt
		end

		-- Update dynamic crosshair spread
		local spreadDeg = if IsAiming then stats.AdsSpread else stats.HipSpread
		local spreadPixels = 6 + spreadDeg * 3.5 + (speed * 0.35) + (RecoilKickOffset.Z * 18)
		HUDController.SetCrosshairState(spreadPixels, IsAiming, stats.UseSniperScope)
	end)
end

return FPSController

