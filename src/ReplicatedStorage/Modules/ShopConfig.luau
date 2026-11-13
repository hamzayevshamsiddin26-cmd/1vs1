--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ReplicatedStorage.Modules.ShopConfig
	Description: Weapon skins, Player character skins, rarities, prices, and XP/Level progression formulas.
]]

local ShopConfig = {}

export type SkinItem = {
	Id: string,
	Name: string,
	Category: "WeaponSkin" | "CharacterSkin",
	Rarity: "Common" | "Rare" | "Epic" | "Legendary" | "Mythic",
	Price: number,
	Description: string,
	PrimaryNeon: Color3,
	SecondaryColor: Color3,
}

ShopConfig.RarityColors = {
	Common = Color3.fromRGB(0, 225, 255),
	Rare = Color3.fromRGB(85, 130, 255),
	Epic = Color3.fromRGB(190, 55, 255),
	Legendary = Color3.fromRGB(255, 50, 175),
	Mythic = Color3.fromRGB(255, 210, 55),
}

ShopConfig.WeaponSkins = {
	{
		Id = "DefaultCyan",
		Name = "CYBER CYAN MK-I",
		Category = "WeaponSkin",
		Rarity = "Common",
		Price = 0,
		Description = "Standard-issue Cybercity tactical neon cyan energy core.",
		PrimaryNeon = Color3.fromRGB(0, 240, 255),
		SecondaryColor = Color3.fromRGB(22, 26, 38),
	},
	{
		Id = "SynthMagenta",
		Name = "SYNTHWAVE OVERDRIVE",
		Category = "WeaponSkin",
		Rarity = "Rare",
		Price = 250,
		Description = "High-voltage magenta plasma conduits with obsidian alloy casing.",
		PrimaryNeon = Color3.fromRGB(255, 40, 185),
		SecondaryColor = Color3.fromRGB(24, 14, 34),
	},
	{
		Id = "VoidPurple",
		Name = "VOID SINGULARITY",
		Category = "WeaponSkin",
		Rarity = "Epic",
		Price = 500,
		Description = "Dark matter violet core harvested from the Void Citadel reactor.",
		PrimaryNeon = Color3.fromRGB(170, 45, 255),
		SecondaryColor = Color3.fromRGB(14, 12, 24),
	},
	{
		Id = "EmeraldMatrix",
		Name = "NEURAL MATRIX",
		Category = "WeaponSkin",
		Rarity = "Epic",
		Price = 650,
		Description = "Encrypted bio-luminescent emerald circuitry with carbon frame.",
		PrimaryNeon = Color3.fromRGB(0, 255, 165),
		SecondaryColor = Color3.fromRGB(15, 28, 24),
	},
	{
		Id = "CrimsonProtocol",
		Name = "REDLINE PROTOCOL",
		Category = "WeaponSkin",
		Rarity = "Legendary",
		Price = 1000,
		Description = "Overclocked crimson laser core built for elite cyber assassins.",
		PrimaryNeon = Color3.fromRGB(255, 35, 65),
		SecondaryColor = Color3.fromRGB(28, 12, 16),
	},
	{
		Id = "SolarArchon",
		Name = "AURELIA PRIME",
		Category = "WeaponSkin",
		Rarity = "Mythic",
		Price = 1800,
		Description = "Prestige gold-plated titanium chassis with radiant solar plasma.",
		PrimaryNeon = Color3.fromRGB(255, 215, 50),
		SecondaryColor = Color3.fromRGB(36, 30, 18),
	},
}

ShopConfig.CharacterSkins = {
	{
		Id = "CyberOperative",
		Name = "CYBER OPERATIVE",
		Category = "CharacterSkin",
		Rarity = "Common",
		Price = 0,
		Description = "Standard neon-visor tactical exosuit for Sector 01 duelists.",
		PrimaryNeon = Color3.fromRGB(0, 235, 255),
		SecondaryColor = Color3.fromRGB(20, 25, 38),
	},
	{
		Id = "PhantomStriker",
		Name = "PHANTOM STRIKER",
		Category = "CharacterSkin",
		Rarity = "Rare",
		Price = 350,
		Description = "Stealth infiltrate armor infused with ultraviolet stealth emitters.",
		PrimaryNeon = Color3.fromRGB(165, 55, 255),
		SecondaryColor = Color3.fromRGB(18, 14, 28),
	},
	{
		Id = "NeonSamurai",
		Name = "RONIN ZERO-X",
		Category = "CharacterSkin",
		Rarity = "Epic",
		Price = 750,
		Description = "Cybernetic street samurai plating with magenta plasma pauldrons.",
		PrimaryNeon = Color3.fromRGB(255, 40, 165),
		SecondaryColor = Color3.fromRGB(28, 16, 26),
	},
	{
		Id = "HyperVanguard",
		Name = "HYPERION VANGUARD",
		Category = "CharacterSkin",
		Rarity = "Legendary",
		Price = 1200,
		Description = "Heavy quantum-shielded combat rig with turquoise reactor core.",
		PrimaryNeon = Color3.fromRGB(0, 255, 200),
		SecondaryColor = Color3.fromRGB(14, 26, 32),
	},
	{
		Id = "ArchonOverlord",
		Name = "ARCHON CELESTIAL",
		Category = "CharacterSkin",
		Rarity = "Mythic",
		Price = 2200,
		Description = "Supreme champion cyber-armor radiating golden sovereign energy.",
		PrimaryNeon = Color3.fromRGB(255, 210, 50),
		SecondaryColor = Color3.fromRGB(30, 26, 16),
	},
}

ShopConfig.Rewards = {
	CoinsPerKill = 25,
	CoinsPerWin = 150,
	CoinsPerLoss = 50,
	CoinsPerLevelUp = 100,
	XPPerKill = 40,
	XPPerWin = 200,
	XPPerLoss = 75,
}

function ShopConfig.GetXPRequiredForLevel(level: number): number
	return math.max(100, level * 150)
end

function ShopConfig.GetWeaponSkin(skinId: string): SkinItem
	for _, item in ipairs(ShopConfig.WeaponSkins) do
		if item.Id == skinId then
			return item
		end
	end
	return ShopConfig.WeaponSkins[1]
end

function ShopConfig.GetCharacterSkin(skinId: string): SkinItem
	for _, item in ipairs(ShopConfig.CharacterSkins) do
		if item.Id == skinId then
			return item
		end
	end
	return ShopConfig.CharacterSkins[1]
end

return ShopConfig

