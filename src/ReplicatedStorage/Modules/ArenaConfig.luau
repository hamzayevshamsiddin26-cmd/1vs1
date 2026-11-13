--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ReplicatedStorage.Modules.ArenaConfig
	Description: Configuration for the 5 unique futuristic cyberpunk arenas and the
	mandatory 120-second (2-minute) arena rotation cycle.
]]

local ArenaConfig = {}

-- IMPORTANT REQUIREMENT: Arena rotation happens every 2 MINUTES (120 seconds), NOT 30 seconds.
ArenaConfig.ROTATION_INTERVAL = 120 -- Seconds per arena
ArenaConfig.TRANSITION_DURATION = 2.5 -- Smooth transition visual overlay duration
ArenaConfig.DEFAULT_WIN_KILLS = 10 -- Default kills needed to win a 1v1 match

export type ArenaDefinition = {
	Index: number,
	Id: string,
	Name: string,
	Subtitle: string,
	ThemeDescription: string,
	Origin: Vector3,
	Size: Vector3,
	PrimaryNeon: Color3,
	SecondaryNeon: Color3,
	FloorColor: Color3,
	AmbientColor: Color3,
	FogColor: Color3,
	Spawn1Offset: Vector3,
	Spawn2Offset: Vector3,
}

ArenaConfig.Arenas = {
	{
		Index = 1,
		Id = "CybercityStreet",
		Name = "DE_DUST2 (LONG & MID DOORS)",
		Subtitle = "SECTOR 01 // SANDSTONE COURTYARD & WOODEN CRATES",
		ThemeDescription = "Classic Dust II sandstone courtyard with wooden double doors and tactical crates.",
		Origin = Vector3.new(0, 50, 0),
		Size = Vector3.new(130, 60, 190),
		PrimaryNeon = Color3.fromRGB(196, 171, 124),
		SecondaryNeon = Color3.fromRGB(156, 112, 64),
		FloorColor = Color3.fromRGB(196, 171, 124),
		AmbientColor = Color3.fromRGB(95, 88, 72),
		FogColor = Color3.fromRGB(185, 168, 136),
		Spawn1Offset = Vector3.new(0, 4, 72),
		Spawn2Offset = Vector3.new(0, 4, -72),
	},
	{
		Index = 2,
		Id = "QuantumReactor",
		Name = "FY_POOL_DAY / AIM_MAP",
		Subtitle = "SECTOR 02 // SYMMETRICAL TACTICAL AIM ARENA",
		ThemeDescription = "Classic symmetrical CS 1.6 1v1 arena with brick divider walls and wooden cover boxes.",
		Origin = Vector3.new(400, 50, 0),
		Size = Vector3.new(150, 65, 150),
		PrimaryNeon = Color3.fromRGB(143, 75, 60),
		SecondaryNeon = Color3.fromRGB(153, 110, 63),
		FloorColor = Color3.fromRGB(141, 150, 158),
		AmbientColor = Color3.fromRGB(85, 92, 98),
		FogColor = Color3.fromRGB(155, 168, 178),
		Spawn1Offset = Vector3.new(0, 4, 58),
		Spawn2Offset = Vector3.new(0, 4, -58),
	},
	{
		Index = 3,
		Id = "SynthwaveRooftop",
		Name = "DE_INFERNO (COURTYARD)",
		Subtitle = "SECTOR 03 // COBBLESTONE PLAZA & TERRACOTTA WALLS",
		ThemeDescription = "European cobblestone courtyard with stucco walls, archways, and dark oak crates.",
		Origin = Vector3.new(800, 50, 0),
		Size = Vector3.new(145, 70, 175),
		PrimaryNeon = Color3.fromRGB(196, 178, 146),
		SecondaryNeon = Color3.fromRGB(120, 82, 46),
		FloorColor = Color3.fromRGB(122, 115, 104),
		AmbientColor = Color3.fromRGB(88, 82, 74),
		FogColor = Color3.fromRGB(168, 158, 142),
		Spawn1Offset = Vector3.new(0, 4, 68),
		Spawn2Offset = Vector3.new(0, 4, -68),
	},
	{
		Index = 4,
		Id = "VoidCitadel",
		Name = "DE_NUKE (WAREHOUSE YARD)",
		Subtitle = "SECTOR 04 // INDUSTRIAL CONCRETE & CONTAINERS",
		ThemeDescription = "Industrial concrete yard featuring steel shipping containers and tactical bunkers.",
		Origin = Vector3.new(1200, 50, 0),
		Size = Vector3.new(140, 60, 165),
		PrimaryNeon = Color3.fromRGB(104, 112, 120),
		SecondaryNeon = Color3.fromRGB(73, 89, 68),
		FloorColor = Color3.fromRGB(92, 98, 104),
		AmbientColor = Color3.fromRGB(72, 78, 84),
		FogColor = Color3.fromRGB(128, 136, 144),
		Spawn1Offset = Vector3.new(0, 4, 64),
		Spawn2Offset = Vector3.new(0, 4, -64),
	},
	{
		Index = 5,
		Id = "HyperloopTerminal",
		Name = "DE_TRAIN (RAIL TERMINAL)",
		Subtitle = "SECTOR 05 // FREIGHT YARD & ARMORED TRAIN CARS",
		ThemeDescription = "Concrete transit platforms divided by olive and rust freight train cars.",
		Origin = Vector3.new(1600, 50, 0),
		Size = Vector3.new(135, 58, 185),
		PrimaryNeon = Color3.fromRGB(70, 84, 64),
		SecondaryNeon = Color3.fromRGB(110, 84, 72),
		FloorColor = Color3.fromRGB(82, 86, 90),
		AmbientColor = Color3.fromRGB(68, 72, 76),
		FogColor = Color3.fromRGB(118, 124, 130),
		Spawn1Offset = Vector3.new(0, 4, 70),
		Spawn2Offset = Vector3.new(0, 4, -70),
	},
}

-- Menu Background Camera CFrame (looks down the Cybercity Neon Street like Image 1)
ArenaConfig.MenuCameraCFrame = CFrame.lookAt(
	Vector3.new(0, 58.5, 62),
	Vector3.new(0, 57.5, -60)
)

function ArenaConfig.GetArenaByIndex(index: number): ArenaDefinition
	local wrapped = ((index - 1) % #ArenaConfig.Arenas) + 1
	return ArenaConfig.Arenas[wrapped]
end

function ArenaConfig.GetArenaById(arenaId: string): ArenaDefinition?
	for _, arena in ipairs(ArenaConfig.Arenas) do
		if arena.Id == arenaId then
			return arena
		end
	end
	return nil
end

function ArenaConfig.GetNextArenaIndex(currentIndex: number): number
	return (currentIndex % #ArenaConfig.Arenas) + 1
end

return ArenaConfig

