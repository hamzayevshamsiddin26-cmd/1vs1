--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ServerScriptService.ShopServer
	Description: Server-authoritative Shop handler for purchasing and equipping
	Weapon Skins and Player Character Skins, plus applying 3D cyber armor cosmetics.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

local ShopServer = {}

local function attachArmorPiece(
	character: Model,
	targetPartName: string,
	pieceName: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material
)
	local targetPart = character:FindFirstChild(targetPartName) :: BasePart?
	if not targetPart then
		return
	end

	local part = Instance.new("Part")
	part.Name = pieceName
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = targetPart.CFrame * offset
	part.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = targetPart
	weld.Part1 = part
	weld.Parent = part
end

function ShopServer.ApplyCharacterSkin(player: Player, character: Model?)
	local char = character or player.Character
	if not char then
		return
	end

	local profile = DataManager.GetProfile(player)
	local skin = ShopConfig.GetCharacterSkin(profile.EquippedCharacterSkin)

	-- Clean previous armor pieces
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 10) == "CyberArmor" then
			child:Destroy()
		end
	end

	-- Recolor body parts to sleek cyber suit colors
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			if part.Name == "Head" then
				part.Color = Color3.fromRGB(22, 24, 34)
			else
				part.Color = skin.SecondaryColor
			end
		end
	end

	-- Attach glowing neon visor to Head
	attachArmorPiece(
		char,
		"Head",
		"CyberArmor_Visor",
		Vector3.new(1.18, 0.34, 0.65),
		CFrame.new(0, 0.12, -0.32),
		skin.PrimaryNeon,
		Enum.Material.Neon
	)

	-- Attach glowing chest reactor core to UpperTorso or Torso
	local torsoName = if char:FindFirstChild("UpperTorso") then "UpperTorso" else "Torso"
	attachArmorPiece(
		char,
		torsoName,
		"CyberArmor_ChestCore",
		Vector3.new(0.85, 0.85, 0.25),
		CFrame.new(0, 0.15, -0.52) * CFrame.Angles(0, 0, math.rad(45)),
		skin.PrimaryNeon,
		Enum.Material.Neon
	)
end

function ShopServer.HandleShopAction(
	player: Player,
	action: string,
	category: string,
	itemId: string
): (boolean, string)
	local profile = DataManager.GetProfile(player)

	if category == "WeaponSkin" then
		local skin = ShopConfig.GetWeaponSkin(itemId)
		if not skin or skin.Id ~= itemId then
			return false, "Invalid weapon skin."
		end

		if action == "Buy" then
			if profile.OwnedWeaponSkins[itemId] then
				profile.EquippedWeaponSkin = itemId
				DataManager.SyncToClient(player)
				return true, "Equipped " .. skin.Name
			end
			if profile.Coins < skin.Price then
				return false, "Insufficient Coins (" .. tostring(skin.Price) .. " required)."
			end
			profile.Coins -= skin.Price
			profile.OwnedWeaponSkins[itemId] = true
			profile.EquippedWeaponSkin = itemId
			DataManager.SaveProfile(player)
			DataManager.SyncToClient(player)
			return true, "Purchased & Equipped " .. skin.Name
		elseif action == "Equip" then
			if not profile.OwnedWeaponSkins[itemId] then
				return false, "You do not own this weapon skin yet."
			end
			profile.EquippedWeaponSkin = itemId
			DataManager.SaveProfile(player)
			DataManager.SyncToClient(player)
			return true, "Equipped " .. skin.Name
		end
	elseif category == "CharacterSkin" then
		local skin = ShopConfig.GetCharacterSkin(itemId)
		if not skin or skin.Id ~= itemId then
			return false, "Invalid character skin."
		end

		if action == "Buy" then
			if profile.OwnedCharacterSkins[itemId] then
				profile.EquippedCharacterSkin = itemId
				ShopServer.ApplyCharacterSkin(player)
				DataManager.SyncToClient(player)
				return true, "Equipped " .. skin.Name
			end
			if profile.Coins < skin.Price then
				return false, "Insufficient Coins (" .. tostring(skin.Price) .. " required)."
			end
			profile.Coins -= skin.Price
			profile.OwnedCharacterSkins[itemId] = true
			profile.EquippedCharacterSkin = itemId
			ShopServer.ApplyCharacterSkin(player)
			DataManager.SaveProfile(player)
			DataManager.SyncToClient(player)
			return true, "Purchased & Equipped " .. skin.Name
		elseif action == "Equip" then
			if not profile.OwnedCharacterSkins[itemId] then
				return false, "You do not own this character skin yet."
			end
			profile.EquippedCharacterSkin = itemId
			ShopServer.ApplyCharacterSkin(player)
			DataManager.SaveProfile(player)
			DataManager.SyncToClient(player)
			return true, "Equipped " .. skin.Name
		end
	end

	return false, "Unknown shop action."
end

return ShopServer

