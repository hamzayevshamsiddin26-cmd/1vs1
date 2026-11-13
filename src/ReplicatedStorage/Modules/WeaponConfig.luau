--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ReplicatedStorage.Modules.WeaponConfig
	Description: Complete configuration and procedural 3D cyberpunk model generator
	for all 5 weapon classes (Assault Rifle, Sniper Rifle, Shotgun, SMG, Pistol).
]]

local WeaponConfig = {}

export type WeaponStats = {
	Id: string,
	Name: string,
	Category: string,
	Slot: number,
	FireMode: "Auto" | "Semi",
	BaseDamage: number,
	HeadshotMultiplier: number,
	FireRate: number, -- Seconds between shots
	MagazineSize: number,
	ReserveAmmo: number,
	ReloadTime: number, -- Seconds
	Pellets: number,
	HipSpread: number, -- Degrees
	AdsSpread: number, -- Degrees
	AdsFov: number,
	UseSniperScope: boolean,
	MaxRange: number,
	RecoilPitch: number,
	RecoilYaw: number,
	RecoilKickback: number,
	EquipTime: number,
	NeonColor: Color3,
	SecondaryColor: Color3,
	FireSoundId: string,
	ReloadSoundId: string,
	FirePitch: number,
	ModelScale: Vector3,
	BarrelLength: number,
}

WeaponConfig.SlotOrder = {
	"AssaultRifle",
	"SniperRifle",
	"Shotgun",
	"SMG",
	"Pistol",
}

WeaponConfig.Weapons = {
	AssaultRifle = {
		Id = "AssaultRifle",
		Name = "CV-47 (AK-47)",
		Category = "Assault Rifle",
		Slot = 1,
		FireMode = "Auto",
		BaseDamage = 27,
		HeadshotMultiplier = 3.25,
		FireRate = 0.105,
		MagazineSize = 30,
		ReserveAmmo = 90,
		ReloadTime = 2.3,
		Pellets = 1,
		HipSpread = 1.8,
		AdsSpread = 0.35,
		AdsFov = 55,
		UseSniperScope = false,
		MaxRange = 450,
		RecoilPitch = 1.35,
		RecoilYaw = 0.55,
		RecoilKickback = 0.24,
		EquipTime = 0.35,
		NeonColor = Color3.fromRGB(122, 73, 36), -- Oiled walnut wood
		SecondaryColor = Color3.fromRGB(38, 41, 44), -- Dark blued steel
		FireSoundId = "rbxassetid://9114222085",
		ReloadSoundId = "rbxassetid://9114221580",
		FirePitch = 0.95,
		ModelScale = Vector3.new(0.28, 0.42, 2.35),
		BarrelLength = 1.35,
	},

	SniperRifle = {
		Id = "SniperRifle",
		Name = "MAGNUM SNIPER (AWP)",
		Category = "Sniper Rifle",
		Slot = 2,
		FireMode = "Semi",
		BaseDamage = 95,
		HeadshotMultiplier = 2.0,
		FireRate = 1.35,
		MagazineSize = 10,
		ReserveAmmo = 30,
		ReloadTime = 2.9,
		Pellets = 1,
		HipSpread = 4.8,
		AdsSpread = 0.02,
		AdsFov = 22,
		UseSniperScope = true,
		MaxRange = 900,
		RecoilPitch = 4.2,
		RecoilYaw = 0.8,
		RecoilKickback = 0.62,
		EquipTime = 0.5,
		NeonColor = Color3.fromRGB(63, 82, 56), -- Classic CS 1.6 Olive Green AWP
		SecondaryColor = Color3.fromRGB(27, 29, 31),
		FireSoundId = "rbxassetid://9114222085",
		ReloadSoundId = "rbxassetid://9114221580",
		FirePitch = 0.65,
		ModelScale = Vector3.new(0.3, 0.45, 3.4),
		BarrelLength = 2.1,
	},

	Shotgun = {
		Id = "Shotgun",
		Name = "LEONE 12 GAUGE (M3)",
		Category = "Shotgun",
		Slot = 3,
		FireMode = "Semi",
		BaseDamage = 16,
		HeadshotMultiplier = 1.5,
		FireRate = 0.88,
		MagazineSize = 8,
		ReserveAmmo = 32,
		ReloadTime = 2.5,
		Pellets = 8,
		HipSpread = 4.6,
		AdsSpread = 2.8,
		AdsFov = 62,
		UseSniperScope = false,
		MaxRange = 140,
		RecoilPitch = 3.6,
		RecoilYaw = 1.2,
		RecoilKickback = 0.50,
		EquipTime = 0.4,
		NeonColor = Color3.fromRGB(59, 64, 69),
		SecondaryColor = Color3.fromRGB(34, 37, 40),
		FireSoundId = "rbxassetid://9114222085",
		ReloadSoundId = "rbxassetid://9114221580",
		FirePitch = 0.78,
		ModelScale = Vector3.new(0.36, 0.44, 2.2),
		BarrelLength = 1.25,
	},

	SMG = {
		Id = "SMG",
		Name = "KM SUB-MACHINE (MP5)",
		Category = "SMG",
		Slot = 4,
		FireMode = "Auto",
		BaseDamage = 18,
		HeadshotMultiplier = 1.85,
		FireRate = 0.075,
		MagazineSize = 30,
		ReserveAmmo = 120,
		ReloadTime = 1.8,
		Pellets = 1,
		HipSpread = 2.2,
		AdsSpread = 0.65,
		AdsFov = 60,
		UseSniperScope = false,
		MaxRange = 250,
		RecoilPitch = 0.95,
		RecoilYaw = 0.75,
		RecoilKickback = 0.14,
		EquipTime = 0.25,
		NeonColor = Color3.fromRGB(50, 55, 60),
		SecondaryColor = Color3.fromRGB(31, 35, 38),
		FireSoundId = "rbxassetid://9114222085",
		ReloadSoundId = "rbxassetid://9114221580",
		FirePitch = 1.22,
		ModelScale = Vector3.new(0.26, 0.40, 1.65),
		BarrelLength = 0.9,
	},

	Pistol = {
		Id = "Pistol",
		Name = "NIGHT HAWK .50C (DEAGLE)",
		Category = "Pistol",
		Slot = 5,
		FireMode = "Semi",
		BaseDamage = 38,
		HeadshotMultiplier = 2.75,
		FireRate = 0.24,
		MagazineSize = 7,
		ReserveAmmo = 35,
		ReloadTime = 1.6,
		Pellets = 1,
		HipSpread = 1.4,
		AdsSpread = 0.25,
		AdsFov = 64,
		UseSniperScope = false,
		MaxRange = 280,
		RecoilPitch = 1.8,
		RecoilYaw = 0.4,
		RecoilKickback = 0.36,
		EquipTime = 0.2,
		NeonColor = Color3.fromRGB(168, 176, 184), -- Brushed chrome Desert Eagle
		SecondaryColor = Color3.fromRGB(35, 38, 41),
		FireSoundId = "rbxassetid://9114222085",
		ReloadSoundId = "rbxassetid://9114221580",
		FirePitch = 0.88,
		ModelScale = Vector3.new(0.22, 0.34, 1.05),
		BarrelLength = 0.6,
	},
}

function WeaponConfig.GetWeapon(weaponId: string): WeaponStats?
	return WeaponConfig.Weapons[weaponId]
end

function WeaponConfig.GetWeaponBySlot(slot: number): WeaponStats?
	local id = WeaponConfig.SlotOrder[slot]
	if id then
		return WeaponConfig.Weapons[id]
	end
	return nil
end

local function createPart(
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function weldParts(root: BasePart, part: BasePart, offset: CFrame)
	part.CFrame = root.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

--[[
	Builds a detailed multi-part 3D futuristic cyberpunk weapon model.
	Used for both the First-Person Viewmodel and 3rd-person character appearance.
]]
function WeaponConfig.BuildWeaponModel(
	weaponId: string,
	customNeonColor: Color3?,
	customBodyColor: Color3?
): (Model, BasePart, BasePart)
	local stats = WeaponConfig.GetWeapon(weaponId) or WeaponConfig.Weapons.AssaultRifle
	local neonColor = customNeonColor or stats.NeonColor
	local bodyColor = customBodyColor or stats.SecondaryColor

	local model = Instance.new("Model")
	model.Name = "Weapon_" .. stats.Id

	-- Main Receiver / Handle
	local receiver = createPart(
		"Handle",
		stats.ModelScale,
		bodyColor,
		Enum.Material.Metal,
		model
	)
	model.PrimaryPart = receiver

	-- Grip
	local grip = createPart(
		"Grip",
		Vector3.new(stats.ModelScale.X * 0.75, 0.55, 0.28),
		Color3.fromRGB(14, 16, 22),
		Enum.Material.SmoothPlastic,
		model
	)
	weldParts(receiver, grip, CFrame.new(0, -0.35, 0.25) * CFrame.Angles(math.rad(-16), 0, 0))

	-- Neon Energy Strip Left & Right
	local stripLength = stats.ModelScale.Z * 0.82
	local stripLeft = createPart(
		"NeonStripL",
		Vector3.new(0.04, 0.07, stripLength),
		neonColor,
		Enum.Material.Neon,
		model
	)
	weldParts(receiver, stripLeft, CFrame.new(-stats.ModelScale.X * 0.51, 0.04, -0.05))

	local stripRight = createPart(
		"NeonStripR",
		Vector3.new(0.04, 0.07, stripLength),
		neonColor,
		Enum.Material.Neon,
		model
	)
	weldParts(receiver, stripRight, CFrame.new(stats.ModelScale.X * 0.51, 0.04, -0.05))

	-- Top Rail & Futuristic Holographic Sight
	local topRail = createPart(
		"TopRail",
		Vector3.new(stats.ModelScale.X * 0.6, 0.08, stats.ModelScale.Z * 0.65),
		Color3.fromRGB(32, 36, 48),
		Enum.Material.Metal,
		model
	)
	weldParts(receiver, topRail, CFrame.new(0, stats.ModelScale.Y * 0.5 + 0.03, 0))

	if stats.Id == "SniperRifle" then
		-- High-Power Cyber Scope
		local scopeBody = createPart(
			"Scope",
			Vector3.new(0.22, 0.22, 1.15),
			bodyColor,
			Enum.Material.Metal,
			model
		)
		weldParts(receiver, scopeBody, CFrame.new(0, stats.ModelScale.Y * 0.5 + 0.20, 0.05))

		local scopeLens = createPart(
			"ScopeLens",
			Vector3.new(0.18, 0.18, 1.18),
			neonColor,
			Enum.Material.Neon,
			model
		)
		weldParts(receiver, scopeLens, CFrame.new(0, stats.ModelScale.Y * 0.5 + 0.20, 0.05))
	else
		-- Holo Sight Frame + Glowing Reticle Glass
		local sightFrame = createPart(
			"HoloSight",
			Vector3.new(stats.ModelScale.X * 0.7, 0.22, 0.32),
			bodyColor,
			Enum.Material.Metal,
			model
		)
		weldParts(receiver, sightFrame, CFrame.new(0, stats.ModelScale.Y * 0.5 + 0.14, 0.1))

		local sightGlass = createPart(
			"HoloGlass",
			Vector3.new(stats.ModelScale.X * 0.52, 0.16, 0.04),
			neonColor,
			Enum.Material.Glass,
			model
		)
		sightGlass.Transparency = 0.45
		weldParts(receiver, sightGlass, CFrame.new(0, stats.ModelScale.Y * 0.5 + 0.15, 0.1))
	end

	-- Magazine (for non-shotgun)
	if stats.Id ~= "Shotgun" and stats.Id ~= "Pistol" then
		local mag = createPart(
			"Magazine",
			Vector3.new(stats.ModelScale.X * 0.62, 0.62, 0.32),
			Color3.fromRGB(24, 28, 38),
			Enum.Material.Metal,
			model
		)
		weldParts(receiver, mag, CFrame.new(0, -0.38, -0.25) * CFrame.Angles(math.rad(10), 0, 0))

		local magNeon = createPart(
			"MagNeon",
			Vector3.new(stats.ModelScale.X * 0.66, 0.45, 0.06),
			neonColor,
			Enum.Material.Neon,
			model
		)
		weldParts(mag, magNeon, CFrame.new(0, 0, -0.14))
	end

	-- Barrel & Muzzle Point
	local barrel = createPart(
		"Barrel",
		Vector3.new(0.12, 0.12, stats.BarrelLength),
		Color3.fromRGB(36, 40, 54),
		Enum.Material.Metal,
		model
	)
	local barrelZ = -(stats.ModelScale.Z * 0.5 + stats.BarrelLength * 0.35)
	weldParts(receiver, barrel, CFrame.new(0, 0.06, barrelZ))

	local muzzle = createPart(
		"Muzzle",
		Vector3.new(0.15, 0.15, 0.15),
		neonColor,
		Enum.Material.Neon,
		model
	)
	local muzzleZ = barrelZ - (stats.BarrelLength * 0.5)
	weldParts(receiver, muzzle, CFrame.new(0, 0.06, muzzleZ))

	local muzzleLight = Instance.new("PointLight")
	muzzleLight.Name = "MuzzleFlashLight"
	muzzleLight.Color = neonColor
	muzzleLight.Brightness = 3
	muzzleLight.Range = 9
	muzzleLight.Enabled = false
	muzzleLight.Parent = muzzle

	return model, receiver, muzzle
end

return WeaponConfig

