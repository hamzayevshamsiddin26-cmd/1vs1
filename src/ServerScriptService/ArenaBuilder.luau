--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ServerScriptService.ArenaBuilder
	Description: Procedurally constructs all 5 unique futuristic cyberpunk 3D arenas
	and configures Roblox Lighting (Bloom, ColorCorrection, Atmosphere) for a dark
	neon blue, purple, and cyan aesthetic.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ArenaConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ArenaConfig"))

local ArenaBuilder = {}

local ArenasFolder: Folder? = nil

local function makePart(props: {
	Name: string?,
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3,
	Material: Enum.Material?,
	Transparency: number?,
	Reflectance: number?,
	CanCollide: boolean?,
	Shape: Enum.PartType?,
	Parent: Instance,
}): Part
	local part = Instance.new("Part")
	part.Name = props.Name or "CyberPart"
	part.Anchored = true
	part.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	part.Size = props.Size
	part.CFrame = props.CFrame
	part.Color = props.Color
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Transparency = props.Transparency or 0
	part.Reflectance = props.Reflectance or 0
	if props.Shape then
		part.Shape = props.Shape
	end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.Parent
	return part
end

local function addPointLight(parent: Instance, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = true
	light.Parent = parent
end

local function addNeonSignText(parent: BasePart, face: Enum.NormalId, text: string, textColor: Color3)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 24
	sg.LightInfluence = 0
	sg.Brightness = 3
	sg.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.Font = Enum.Font.Michroma
	label.TextScaled = true
	label.Parent = sg
end

local function buildPerimeterWalls(folder: Instance, origin: Vector3, size: Vector3, primaryNeon: Color3, secondaryNeon: Color3)
	local halfX = size.X * 0.5
	local halfZ = size.Z * 0.5
	local wallHeight = 32
	local wallColor = Color3.fromRGB(10, 12, 22)

	-- Boundary walls (semi-transparent dark cyber barriers with neon grid trim)
	local walls = {
		{ Pos = Vector3.new(0, wallHeight * 0.5, halfZ), Size = Vector3.new(size.X, wallHeight, 2) },
		{ Pos = Vector3.new(0, wallHeight * 0.5, -halfZ), Size = Vector3.new(size.X, wallHeight, 2) },
		{ Pos = Vector3.new(halfX, wallHeight * 0.5, 0), Size = Vector3.new(2, wallHeight, size.Z) },
		{ Pos = Vector3.new(-halfX, wallHeight * 0.5, 0), Size = Vector3.new(2, wallHeight, size.Z) },
	}

	for i, w in ipairs(walls) do
		makePart({
			Name = "BoundaryWall_" .. i,
			Size = w.Size,
			CFrame = CFrame.new(origin + w.Pos),
			Color = wallColor,
			Material = Enum.Material.Metal,
			Transparency = 0.25,
			Parent = folder,
		})

		-- Bottom & Mid Neon Trim
		local trimSize = Vector3.new(
			if w.Size.X > 4 then w.Size.X else 2.3,
			0.45,
			if w.Size.Z > 4 then w.Size.Z else 2.3
		)
		makePart({
			Name = "NeonTrimBottom_" .. i,
			Size = trimSize,
			CFrame = CFrame.new(origin + Vector3.new(w.Pos.X, 0.5, w.Pos.Z)),
			Color = primaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
		makePart({
			Name = "NeonTrimTop_" .. i,
			Size = trimSize,
			CFrame = CFrame.new(origin + Vector3.new(w.Pos.X, 14, w.Pos.Z)),
			Color = secondaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- Invisible ceiling to prevent escaping
	makePart({
		Name = "CeilingBarrier",
		Size = Vector3.new(size.X, 2, size.Z),
		CFrame = CFrame.new(origin + Vector3.new(0, wallHeight + 1, 0)),
		Color = wallColor,
		Transparency = 1,
		Parent = folder,
	})
end

local function buildSpawnPad(folder: Instance, pos: Vector3, neonColor: Color3, label: string)
	local base = makePart({
		Name = label,
		Size = Vector3.new(10, 0.5, 10),
		CFrame = CFrame.new(pos - Vector3.new(0, 3.6, 0)),
		Color = Color3.fromRGB(18, 22, 34),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	makePart({
		Name = label .. "_NeonRing",
		Size = Vector3.new(10.6, 0.3, 10.6),
		CFrame = base.CFrame,
		Color = neonColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	-- Spawn Cover Shield in front of spawn to prevent instant spawn-sniping
	local zDir = if pos.Z > 0 then -1 else 1
	local shieldPos = pos + Vector3.new(0, -0.5, zDir * 11)
	makePart({
		Name = label .. "_SpawnCover",
		Size = Vector3.new(12, 7.5, 1.5),
		CFrame = CFrame.new(shieldPos),
		Color = Color3.fromRGB(20, 24, 38),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	makePart({
		Name = label .. "_SpawnCoverNeon",
		Size = Vector3.new(12.3, 0.4, 1.7),
		CFrame = CFrame.new(shieldPos + Vector3.new(0, 3.6, 0)),
		Color = neonColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
end

local function buildCyberCar(folder: Instance, cframe: CFrame, neonColor: Color3, bodyColor: Color3)
	-- Futuristic Cyber Sports Car (like Image 1 street cars, doubles as tactical waist/chest cover)
	makePart({
		Name = "CyberCarChassis",
		Size = Vector3.new(7.5, 2.6, 15.5),
		CFrame = cframe * CFrame.new(0, 1.8, 0),
		Color = bodyColor,
		Material = Enum.Material.Metal,
		Reflectance = 0.25,
		Parent = folder,
	})
	makePart({
		Name = "CyberCarCabin",
		Size = Vector3.new(6.4, 2.0, 8.2),
		CFrame = cframe * CFrame.new(0, 3.8, -0.5),
		Color = Color3.fromRGB(12, 16, 26),
		Material = Enum.Material.Glass,
		Reflectance = 0.35,
		Parent = folder,
	})
	-- Tail & Headlight Neon Bars
	local tailLight = makePart({
		Name = "CyberCarTailNeon",
		Size = Vector3.new(7.2, 0.45, 0.3),
		CFrame = cframe * CFrame.new(0, 2.3, 7.75),
		Color = Color3.fromRGB(255, 35, 110),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	addPointLight(tailLight, Color3.fromRGB(255, 35, 110), 2.2, 18)

	local headLight = makePart({
		Name = "CyberCarHeadNeon",
		Size = Vector3.new(7.2, 0.4, 0.3),
		CFrame = cframe * CFrame.new(0, 2.1, -7.75),
		Color = neonColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	addPointLight(headLight, neonColor, 2.2, 20)
end

-- ============================================================================
-- ARENA 1: CYBERCITY NEON STREET (Matches Image 1 Aesthetic & Vista)
-- ============================================================================
local function buildArena1_CybercityStreet(folder: Instance, def: ArenaConfig.ArenaDefinition)
	local o = def.Origin
	-- Wet reflective dark asphalt floor
	makePart({
		Name = "WetAsphaltRoad",
		Size = Vector3.new(def.Size.X, 2, def.Size.Z),
		CFrame = CFrame.new(o - Vector3.new(0, 1, 0)),
		Color = def.FloorColor,
		Material = Enum.Material.Metal,
		Reflectance = 0.32,
		Parent = folder,
	})

	-- Reflective puddle strips & tram rails down the center street (just like Image 1)
	for _, xOff in ipairs({ -6, -2, 2, 6 }) do
		makePart({
			Name = "StreetTramRail",
			Size = Vector3.new(0.35, 0.12, def.Size.Z - 10),
			CFrame = CFrame.new(o + Vector3.new(xOff, 0.06, 0)),
			Color = Color3.fromRGB(45, 55, 85),
			Material = Enum.Material.Metal,
			Reflectance = 0.55,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- Glowing Neon Sidewalk Curbs Left & Right
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "Sidewalk",
			Size = Vector3.new(26, 1.2, def.Size.Z),
			CFrame = CFrame.new(o + Vector3.new(side * 50, 0.6, 0)),
			Color = Color3.fromRGB(18, 20, 34),
			Material = Enum.Material.Concrete,
			Parent = folder,
		})
		makePart({
			Name = "CurbNeon",
			Size = Vector3.new(0.45, 0.45, def.Size.Z - 6),
			CFrame = CFrame.new(o + Vector3.new(side * 36.8, 0.9, 0)),
			Color = if side == -1 then def.PrimaryNeon else def.SecondaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- Cyberpunk Storefronts, Skyscrapers, and Glowing Billboards along both sides
	local signTexts = { "CYBER // 2099", "NEON DUEL", "SYNTH CORP", "PULSE ARMS", "VOID TECH", "NEXUS BAR" }
	for zIdx = -3, 3 do
		local zPos = zIdx * 24
		for _, side in ipairs({ -1, 1 }) do
			local bHeight = 34 + (math.abs(zIdx * 7 + side * 3) % 24)
			local building = makePart({
				Name = "CyberBuilding",
				Size = Vector3.new(18, bHeight, 20),
				CFrame = CFrame.new(o + Vector3.new(side * 55, bHeight * 0.5, zPos)),
				Color = Color3.fromRGB(12, 14, 26),
				Material = Enum.Material.Metal,
				Parent = folder,
			})

			local signColor = if (zIdx + side) % 2 == 0 then def.PrimaryNeon else def.SecondaryNeon
			local billboard = makePart({
				Name = "NeonBillboard",
				Size = Vector3.new(0.6, 5.5, 13),
				CFrame = CFrame.new(o + Vector3.new(side * 45.2, 12 + (math.abs(zIdx) % 2) * 5, zPos)),
				Color = signColor,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = folder,
			})
			addPointLight(billboard, signColor, 1.8, 28)

			local face = if side == -1 then Enum.NormalId.Right else Enum.NormalId.Left
			addNeonSignText(
				building,
				face,
				signTexts[((math.abs(zIdx) + (if side == 1 then 2 else 0)) % #signTexts) + 1],
				signColor
			)
		end
	end

	-- Distant Center Skyline Towers (visible behind the north/south ends like Image 1)
	for i = -2, 2 do
		local towerH = 85 + (2 - math.abs(i)) * 22
		local tower = makePart({
			Name = "SkylineTower_" .. i,
			Size = Vector3.new(22, towerH, 22),
			CFrame = CFrame.new(o + Vector3.new(i * 26, towerH * 0.5 - 10, -125)),
			Color = Color3.fromRGB(10, 16, 32),
			Material = Enum.Material.Metal,
			CanCollide = false,
			Parent = folder,
		})
		makePart({
			Name = "TowerCrownNeon_" .. i,
			Size = Vector3.new(22.6, 2.5, 22.6),
			CFrame = tower.CFrame * CFrame.new(0, towerH * 0.42, 0),
			Color = if i % 2 == 0 then def.PrimaryNeon else def.SecondaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- Parked Cyber Sports Cars & Tactical Cover Crates in the street
	buildCyberCar(folder, CFrame.new(o + Vector3.new(-16, 0, 26)), def.PrimaryNeon, Color3.fromRGB(22, 18, 36))
	buildCyberCar(folder, CFrame.new(o + Vector3.new(16, 0, 26)) * CFrame.Angles(0, math.pi, 0), def.SecondaryNeon, Color3.fromRGB(18, 22, 38))
	buildCyberCar(folder, CFrame.new(o + Vector3.new(-16, 0, -26)), def.SecondaryNeon, Color3.fromRGB(22, 18, 36))
	buildCyberCar(folder, CFrame.new(o + Vector3.new(16, 0, -26)) * CFrame.Angles(0, math.pi, 0), def.PrimaryNeon, Color3.fromRGB(18, 22, 38))

	-- Central Holo-Kiosk Hub for Mid-Map Duels
	local centerKiosk = makePart({
		Name = "CenterHoloKiosk",
		Size = Vector3.new(10, 9, 10),
		CFrame = CFrame.new(o + Vector3.new(0, 4.5, 0)),
		Color = Color3.fromRGB(18, 20, 34),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	local holoRing = makePart({
		Name = "CenterHoloRing",
		Size = Vector3.new(11, 1.2, 11),
		CFrame = centerKiosk.CFrame * CFrame.new(0, 3.8, 0),
		Color = def.PrimaryNeon,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	addPointLight(holoRing, def.PrimaryNeon, 2.5, 32)

	-- Side Tactical Barriers
	for _, coords in ipairs({
		Vector3.new(-26, 3, 0),
		Vector3.new(26, 3, 0),
		Vector3.new(0, 3, 42),
		Vector3.new(0, 3, -42),
	}) do
		makePart({
			Name = "TacticalBarrier",
			Size = Vector3.new(11, 6, 2.5),
			CFrame = CFrame.new(o + coords),
			Color = Color3.fromRGB(24, 28, 44),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		makePart({
			Name = "BarrierNeon",
			Size = Vector3.new(11.3, 0.4, 2.7),
			CFrame = CFrame.new(o + coords + Vector3.new(0, 2.8, 0)),
			Color = def.SecondaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end
end

-- ============================================================================
-- ARENA 2: QUANTUM CORE REACTOR
-- ============================================================================
local function buildArena2_QuantumReactor(folder: Instance, def: ArenaConfig.ArenaDefinition)
	local o = def.Origin
	makePart({
		Name = "ReactorFloor",
		Size = Vector3.new(def.Size.X, 2, def.Size.Z),
		CFrame = CFrame.new(o - Vector3.new(0, 1, 0)),
		Color = def.FloorColor,
		Material = Enum.Material.Metal,
		Reflectance = 0.25,
		Parent = folder,
	})

	-- Central Towering Quantum Plasma Core
	local coreCylinder = makePart({
		Name = "QuantumCoreColumn",
		Size = Vector3.new(28, 14, 14),
		CFrame = CFrame.new(o + Vector3.new(0, 14, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = def.PrimaryNeon,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Cylinder,
		Parent = folder,
	})
	addPointLight(coreCylinder, def.PrimaryNeon, 3.2, 48)

	-- Outer Ring Pillars around Core
	for angleDeg = 0, 315, 45 do
		local rad = math.rad(angleDeg)
		local pPos = Vector3.new(math.cos(rad) * 26, 6, math.sin(rad) * 26)
		makePart({
			Name = "ReactorPillar",
			Size = Vector3.new(5, 12, 5),
			CFrame = CFrame.new(o + pPos) * CFrame.Angles(0, -rad, 0),
			Color = Color3.fromRGB(20, 26, 42),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		makePart({
			Name = "PillarNeon",
			Size = Vector3.new(5.3, 1.2, 5.3),
			CFrame = CFrame.new(o + pPos + Vector3.new(0, 4, 0)) * CFrame.Angles(0, -rad, 0),
			Color = if angleDeg % 90 == 0 then def.PrimaryNeon else def.SecondaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- Elevated Sniper Platforms Left & Right with Ramps
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "OverwatchDeck",
			Size = Vector3.new(20, 1.5, 46),
			CFrame = CFrame.new(o + Vector3.new(side * 48, 8, 0)),
			Color = Color3.fromRGB(18, 24, 38),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		makePart({
			Name = "DeckCoverWall",
			Size = Vector3.new(1.2, 4.2, 30),
			CFrame = CFrame.new(o + Vector3.new(side * 38.5, 10.5, 0)),
			Color = def.SecondaryNeon,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			Parent = folder,
		})
		-- Access Ramps North & South
		for _, zDir in ipairs({ -1, 1 }) do
			makePart({
				Name = "DeckRamp",
				Size = Vector3.new(10, 1, 22),
				CFrame = CFrame.new(o + Vector3.new(side * 48, 4, zDir * 32))
					* CFrame.Angles(math.rad(zDir * 22), 0, 0),
				Color = Color3.fromRGB(26, 32, 48),
				Material = Enum.Material.Metal,
				Parent = folder,
			})
		end
	end
end

-- ============================================================================
-- ARENA 3: SYNTHWAVE SKY MATRIX
-- ============================================================================
local function buildArena3_SynthwaveRooftop(folder: Instance, def: ArenaConfig.ArenaDefinition)
	local o = def.Origin
	makePart({
		Name = "RooftopDeck",
		Size = Vector3.new(def.Size.X, 2, def.Size.Z),
		CFrame = CFrame.new(o - Vector3.new(0, 1, 0)),
		Color = def.FloorColor,
		Material = Enum.Material.Metal,
		Reflectance = 0.28,
		Parent = folder,
	})

	-- Neon Grid Lines across the floor
	for z = -70, 70, 20 do
		makePart({
			Name = "GridLineZ",
			Size = Vector3.new(def.Size.X - 6, 0.1, 0.35),
			CFrame = CFrame.new(o + Vector3.new(0, 0.05, z)),
			Color = def.PrimaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- Central Elevated Skybridge + Holographic Arches
	makePart({
		Name = "CenterSkybridge",
		Size = Vector3.new(28, 1.2, 56),
		CFrame = CFrame.new(o + Vector3.new(0, 7.5, 0)),
		Color = Color3.fromRGB(24, 16, 38),
		Material = Enum.Material.Glass,
		Transparency = 0.2,
		Parent = folder,
	})
	for _, zDir in ipairs({ -1, 1 }) do
		makePart({
			Name = "CenterRamp",
			Size = Vector3.new(14, 1, 20),
			CFrame = CFrame.new(o + Vector3.new(0, 3.8, zDir * 36)) * CFrame.Angles(math.rad(zDir * 22), 0, 0),
			Color = def.SecondaryNeon,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end

	-- Rooftop HVAC / Cyber Server Cover Blocks
	local blocks = {
		Vector3.new(-32, 3.5, 32),
		Vector3.new(32, 3.5, 32),
		Vector3.new(-32, 3.5, -32),
		Vector3.new(32, 3.5, -32),
		Vector3.new(-22, 3.5, 0),
		Vector3.new(22, 3.5, 0),
	}
	for i, bPos in ipairs(blocks) do
		makePart({
			Name = "CyberServerUnit_" .. i,
			Size = Vector3.new(10, 7, 10),
			CFrame = CFrame.new(o + bPos),
			Color = Color3.fromRGB(22, 18, 34),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		makePart({
			Name = "ServerNeon_" .. i,
			Size = Vector3.new(10.4, 0.6, 10.4),
			CFrame = CFrame.new(o + bPos + Vector3.new(0, 2.8, 0)),
			Color = if i % 2 == 0 then def.PrimaryNeon else def.SecondaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end
end

-- ============================================================================
-- ARENA 4: VOID CITADEL LAB
-- ============================================================================
local function buildArena4_VoidCitadel(folder: Instance, def: ArenaConfig.ArenaDefinition)
	local o = def.Origin
	makePart({
		Name = "ObsidianFloor",
		Size = Vector3.new(def.Size.X, 2, def.Size.Z),
		CFrame = CFrame.new(o - Vector3.new(0, 1, 0)),
		Color = def.FloorColor,
		Material = Enum.Material.Metal,
		Reflectance = 0.35,
		Parent = folder,
	})

	-- 6 Glowing Stasis Cryo-Pods for Tactical Pillar Cover
	local podCoords = {
		Vector3.new(-24, 7, 28),
		Vector3.new(24, 7, 28),
		Vector3.new(-24, 7, -28),
		Vector3.new(24, 7, -28),
		Vector3.new(-16, 7, 0),
		Vector3.new(16, 7, 0),
	}
	for i, cPos in ipairs(podCoords) do
		local pod = makePart({
			Name = "CryoStasisPod_" .. i,
			Size = Vector3.new(14, 7.5, 7.5),
			CFrame = CFrame.new(o + cPos) * CFrame.Angles(0, 0, math.rad(90)),
			Color = if i % 2 == 0 then def.PrimaryNeon else def.SecondaryNeon,
			Material = Enum.Material.Neon,
			Shape = Enum.PartType.Cylinder,
			Parent = folder,
		})
		addPointLight(pod, pod.Color, 2.0, 24)

		-- Metal Caps
		makePart({
			Name = "PodBase_" .. i,
			Size = Vector3.new(9, 1.5, 9),
			CFrame = CFrame.new(o + Vector3.new(cPos.X, 0.75, cPos.Z)),
			Color = Color3.fromRGB(18, 18, 30),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end

	-- Central Obsidian Monolith & Cover Bunkers
	makePart({
		Name = "VoidMonolith",
		Size = Vector3.new(7, 18, 7),
		CFrame = CFrame.new(o + Vector3.new(0, 9, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Color = Color3.fromRGB(14, 12, 24),
		Material = Enum.Material.Metal,
		Reflectance = 0.4,
		Parent = folder,
	})
end

-- ============================================================================
-- ARENA 5: HYPERLOOP STATION ZERO
-- ============================================================================
local function buildArena5_HyperloopTerminal(folder: Instance, def: ArenaConfig.ArenaDefinition)
	local o = def.Origin
	makePart({
		Name = "TerminalFloor",
		Size = Vector3.new(def.Size.X, 2, def.Size.Z),
		CFrame = CFrame.new(o - Vector3.new(0, 1, 0)),
		Color = def.FloorColor,
		Material = Enum.Material.Metal,
		Reflectance = 0.25,
		Parent = folder,
	})

	-- Central Maglev Train Car Segments (with pass-through gaps between cars for flanking)
	for _, zCenter in ipairs({ -34, 0, 34 }) do
		local car = makePart({
			Name = "MaglevTrainCar",
			Size = Vector3.new(11, 8.5, 22),
			CFrame = CFrame.new(o + Vector3.new(0, 4.5, zCenter)),
			Color = Color3.fromRGB(20, 26, 38),
			Material = Enum.Material.Metal,
			Reflectance = 0.2,
			Parent = folder,
		})
		makePart({
			Name = "TrainStripeNeon",
			Size = Vector3.new(11.3, 0.7, 22.2),
			CFrame = car.CFrame * CFrame.new(0, 1.2, 0),
			Color = def.PrimaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- Twin Passenger Platforms Left & Right with Ticket Kiosk Cover
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "PassengerPlatform",
			Size = Vector3.new(26, 2.2, 130),
			CFrame = CFrame.new(o + Vector3.new(side * 36, 1.1, 0)),
			Color = Color3.fromRGB(18, 22, 32),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		makePart({
			Name = "PlatformEdgeNeon",
			Size = Vector3.new(0.5, 0.4, 130),
			CFrame = CFrame.new(o + Vector3.new(side * 23, 2.2, 0)),
			Color = def.PrimaryNeon,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})

		for _, zKiosk in ipairs({ -40, 0, 40 }) do
			makePart({
				Name = "PlatformCoverKiosk",
				Size = Vector3.new(8, 6.5, 3),
				CFrame = CFrame.new(o + Vector3.new(side * 32, 5.2, zKiosk)),
				Color = Color3.fromRGB(24, 30, 44),
				Material = Enum.Material.Metal,
				Parent = folder,
			})
			makePart({
				Name = "KioskHolo",
				Size = Vector3.new(7.4, 4.5, 3.2),
				CFrame = CFrame.new(o + Vector3.new(side * 32, 5.4, zKiosk)),
				Color = def.SecondaryNeon,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = folder,
			})
		end
	end
end

function ArenaBuilder.ConfigureCyberpunkLighting()
	Lighting.Ambient = Color3.fromRGB(18, 20, 38)
	Lighting.OutdoorAmbient = Color3.fromRGB(24, 26, 48)
	Lighting.Brightness = 2.2
	Lighting.ClockTime = 0 -- Midnight cyberpunk atmosphere
	Lighting.ColorShift_Top = Color3.fromRGB(40, 175, 255)
	Lighting.ColorShift_Bottom = Color3.fromRGB(145, 35, 220)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.85

	-- Clear existing post effects before adding clean cyberpunk suite
	for _, child in ipairs(Lighting:GetChildren()) do
		if
			child:IsA("BloomEffect")
			or child:IsA("ColorCorrectionEffect")
			or child:IsA("Atmosphere")
		then
			child:Destroy()
		end
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "CyberNeonBloom"
	bloom.Intensity = 1.35
	bloom.Size = 28
	bloom.Threshold = 0.82
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "CyberColorGrading"
	cc.Brightness = 0.03
	cc.Contrast = 0.18
	cc.Saturation = 0.25
	cc.TintColor = Color3.fromRGB(235, 240, 255)
	cc.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "CyberAtmosphere"
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(18, 14, 36)
	atmosphere.Decay = Color3.fromRGB(10, 18, 38)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.6
	atmosphere.Parent = Lighting
end

local function buildJumpPad(folder: Instance, pos: Vector3, neonColor: Color3, name: string)
	makePart({
		Name = name,
		Size = Vector3.new(6, 0.4, 6),
		CFrame = CFrame.new(pos),
		Color = Color3.fromRGB(22, 26, 40),
		Material = Enum.Material.Metal,
		Parent = folder,
	})

	local ring = makePart({
		Name = name .. "_Glow",
		Size = Vector3.new(5.2, 0.5, 5.2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)),
		Color = neonColor,
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	addPointLight(ring, neonColor, 2.2, 16)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(neonColor)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.6, 1.0)
	emitter.Rate = 18
	emitter.Speed = NumberRange.new(14, 22)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = ring

	ring.Touched:Connect(function(hit: BasePart)
		local model = hit.Parent
		if not model then
			return
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hum and root and hum.Health > 0 then
			local vel = root.AssemblyLinearVelocity
			if vel.Y < 45 then
				root.AssemblyLinearVelocity = Vector3.new(vel.X * 1.15, 76, vel.Z * 1.15)
			end
		end
	end)
end

local function buildCyberRainCanopy(folder: Instance, origin: Vector3, size: Vector3, neonColor: Color3)
	local canopy = makePart({
		Name = "NeonRainEmitterCanopy",
		Size = Vector3.new(size.X * 0.85, 1, size.Z * 0.85),
		CFrame = CFrame.new(origin + Vector3.new(0, 29, 0)),
		Color = neonColor,
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})

	local rain = Instance.new("ParticleEmitter")
	rain.Name = "CyberNeonRain"
	rain.Color = ColorSequence.new(neonColor, Color3.fromRGB(210, 140, 255))
	rain.LightEmission = 0.85
	rain.Transparency = NumberSequence.new(0.45, 0.9)
	rain.Size = NumberSequence.new(0.15)
	rain.Lifetime = NumberRange.new(1.1, 1.5)
	rain.Rate = 65
	rain.Speed = NumberRange.new(38, 48)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Parent = canopy
end

function ArenaBuilder.BuildAllArenas(): Folder
	ArenaBuilder.ConfigureCyberpunkLighting()

	local existing = Workspace:FindFirstChild("NeonDuelArenas")
	if existing then
		existing:Destroy()
	end

	local rootFolder = Instance.new("Folder")
	rootFolder.Name = "NeonDuelArenas"
	rootFolder.Parent = Workspace
	ArenasFolder = rootFolder

	for _, def in ipairs(ArenaConfig.Arenas) do
		local arenaFolder = Instance.new("Folder")
		arenaFolder.Name = def.Id
		arenaFolder.Parent = rootFolder

		buildPerimeterWalls(arenaFolder, def.Origin, def.Size, def.PrimaryNeon, def.SecondaryNeon)
		buildSpawnPad(arenaFolder, def.Origin + def.Spawn1Offset, def.PrimaryNeon, "SpawnPoint1")
		buildSpawnPad(arenaFolder, def.Origin + def.Spawn2Offset, def.SecondaryNeon, "SpawnPoint2")
		buildJumpPad(arenaFolder, def.Origin + Vector3.new(-32, 0.2, 0), def.PrimaryNeon, "JumpPad_West")
		buildJumpPad(arenaFolder, def.Origin + Vector3.new(32, 0.2, 0), def.SecondaryNeon, "JumpPad_East")
		buildCyberRainCanopy(arenaFolder, def.Origin, def.Size, def.PrimaryNeon)

		if def.Id == "CybercityStreet" then
			buildArena1_CybercityStreet(arenaFolder, def)
		elseif def.Id == "QuantumReactor" then
			buildArena2_QuantumReactor(arenaFolder, def)
		elseif def.Id == "SynthwaveRooftop" then
			buildArena3_SynthwaveRooftop(arenaFolder, def)
		elseif def.Id == "VoidCitadel" then
			buildArena4_VoidCitadel(arenaFolder, def)
		elseif def.Id == "HyperloopTerminal" then
			buildArena5_HyperloopTerminal(arenaFolder, def)
		end
	end

	-- Create Lobby Safe Box far away so menu players never fall into the void
	local lobbyBox = Instance.new("Folder")
	lobbyBox.Name = "LobbySafeZone"
	lobbyBox.Parent = rootFolder
	makePart({
		Name = "LobbyFloor",
		Size = Vector3.new(60, 2, 60),
		CFrame = CFrame.new(0, 500, 0),
		Color = Color3.fromRGB(10, 12, 20),
		Material = Enum.Material.Metal,
		Parent = lobbyBox,
	})

	return rootFolder
end

function ArenaBuilder.GetSpawnCFrames(arenaIndex: number): (CFrame, CFrame)
	local def = ArenaConfig.GetArenaByIndex(arenaIndex)
	local pos1 = def.Origin + def.Spawn1Offset
	local pos2 = def.Origin + def.Spawn2Offset
	return CFrame.lookAt(pos1, Vector3.new(pos2.X, pos1.Y, pos2.Z)),
		CFrame.lookAt(pos2, Vector3.new(pos1.X, pos2.Y, pos1.Z))
end

return ArenaBuilder

