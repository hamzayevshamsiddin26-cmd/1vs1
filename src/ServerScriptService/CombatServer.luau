--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ServerScriptService.CombatServer
	Description: Server-authoritative weapon state, ammo & reload validation,
	anti-cheat raycast verification, headshot detection, and 3rd-person weapon rigging.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeaponConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ShopConfig"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

local CombatServer = {}

export type WeaponAmmoState = {
	Mag: number,
	Reserve: number,
}

export type PlayerCombatState = {
	EquippedWeapon: string,
	IsReloading: boolean,
	ReloadToken: number,
	IsAiming: boolean,
	LastShotClock: number,
	Ammo: { [string]: WeaponAmmoState },
}

local PlayerStates: { [Player]: PlayerCombatState } = {}

-- Hooked by MatchManager to process damage, health updates, kills, and win condition
CombatServer.CanPlayerAttack = nil :: ((player: Player) -> boolean)?
CombatServer.OnValidatedHit = nil :: ((
	attacker: Player,
	victimModel: Model,
	damage: number,
	isHeadshot: boolean,
	weaponId: string,
	hitPosition: Vector3
) -> ())?

local function createFreshAmmoTable(): { [string]: WeaponAmmoState }
	local ammoTable: { [string]: WeaponAmmoState } = {}
	for _, weaponId in ipairs(WeaponConfig.SlotOrder) do
		local w = WeaponConfig.GetWeapon(weaponId)
		if w then
			ammoTable[weaponId] = {
				Mag = w.MagazineSize,
				Reserve = w.ReserveAmmo,
			}
		end
	end
	return ammoTable
end

function CombatServer.GetOrCreateState(player: Player): PlayerCombatState
	local state = PlayerStates[player]
	if not state then
		state = {
			EquippedWeapon = "AssaultRifle",
			IsReloading = false,
			ReloadToken = 0,
			IsAiming = false,
			LastShotClock = 0,
			Ammo = createFreshAmmoTable(),
		}
		PlayerStates[player] = state
	end
	return state
end

function CombatServer.ResetLoadout(player: Player)
	local state = CombatServer.GetOrCreateState(player)
	state.IsReloading = false
	state.ReloadToken += 1
	state.IsAiming = false
	state.Ammo = createFreshAmmoTable()
	CombatServer.SyncWeaponState(player)
	CombatServer.AttachThirdPersonWeapon(player)
end

function CombatServer.SyncWeaponState(player: Player)
	local state = PlayerStates[player]
	if not state then
		return
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		return
	end
	local weaponUpdate = remotes:FindFirstChild("WeaponStateUpdate") :: RemoteEvent?
	if weaponUpdate then
		weaponUpdate:FireClient(player, {
			EquippedWeapon = state.EquippedWeapon,
			IsReloading = state.IsReloading,
			Ammo = state.Ammo,
		})
	end
end

function CombatServer.AttachThirdPersonWeapon(player: Player)
	local char = player.Character
	if not char then
		return
	end

	local existing = char:FindFirstChild("EquippedCyberWeapon")
	if existing then
		existing:Destroy()
	end

	local state = CombatServer.GetOrCreateState(player)
	local profile = DataManager.GetProfile(player)
	local skin = ShopConfig.GetWeaponSkin(profile.EquippedWeaponSkin)

	local handPart = (
		char:FindFirstChild("RightHand")
		or char:FindFirstChild("Right Arm")
		or char:FindFirstChild("HumanoidRootPart")
	) :: BasePart?

	if not handPart then
		return
	end

	local model, handle = WeaponConfig.BuildWeaponModel(
		state.EquippedWeapon,
		skin.PrimaryNeon,
		skin.SecondaryColor
	)
	model.Name = "EquippedCyberWeapon"
	model.Parent = char

	handle.CFrame = handPart.CFrame * CFrame.new(0, -0.25, -0.65)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handPart
	weld.Part1 = handle
	weld.Parent = handle
end

function CombatServer.SwitchWeapon(player: Player, weaponId: string)
	if type(weaponId) ~= "string" then
		return
	end
	local stats = WeaponConfig.GetWeapon(weaponId)
	if not stats then
		return
	end

	local state = CombatServer.GetOrCreateState(player)
	if state.EquippedWeapon == weaponId then
		return
	end

	state.EquippedWeapon = weaponId
	state.IsReloading = false
	state.ReloadToken += 1
	state.IsAiming = false
	state.LastShotClock = os.clock() - stats.FireRate + stats.EquipTime

	CombatServer.AttachThirdPersonWeapon(player)
	CombatServer.SyncWeaponState(player)
end

function CombatServer.ReloadWeapon(player: Player)
	local state = CombatServer.GetOrCreateState(player)
	if state.IsReloading then
		return
	end

	local stats = WeaponConfig.GetWeapon(state.EquippedWeapon)
	if not stats then
		return
	end

	local ammoInfo = state.Ammo[state.EquippedWeapon]
	if not ammoInfo or ammoInfo.Mag >= stats.MagazineSize or ammoInfo.Reserve <= 0 then
		return
	end

	state.IsReloading = true
	state.ReloadToken += 1
	local currentToken = state.ReloadToken
	local reloadingWeapon = state.EquippedWeapon
	CombatServer.SyncWeaponState(player)

	task.delay(stats.ReloadTime, function()
		local latestState = PlayerStates[player]
		if not latestState then
			return
		end
		if latestState.ReloadToken ~= currentToken or latestState.EquippedWeapon ~= reloadingWeapon then
			return
		end

		local currentAmmo = latestState.Ammo[reloadingWeapon]
		if currentAmmo then
			local needed = stats.MagazineSize - currentAmmo.Mag
			local transfer = math.min(needed, currentAmmo.Reserve)
			currentAmmo.Mag += transfer
			currentAmmo.Reserve -= transfer
		end

		latestState.IsReloading = false
		CombatServer.SyncWeaponState(player)
	end)
end

function CombatServer.SetAimState(player: Player, isAiming: boolean)
	local state = CombatServer.GetOrCreateState(player)
	state.IsAiming = (isAiming == true)
end

local function findCharacterModel(instance: Instance?): (Model?, Humanoid?)
	local curr = instance
	while curr and curr ~= Workspace do
		if curr:IsA("Model") then
			local hum = curr:FindFirstChildOfClass("Humanoid")
			if hum then
				return curr, hum
			end
		end
		curr = curr.Parent
	end
	return nil, nil
end

function CombatServer.HandleFireWeapon(
	player: Player,
	clientOrigin: Vector3,
	clientDirections: { Vector3 }
)
	if typeof(clientOrigin) ~= "Vector3" or type(clientDirections) ~= "table" then
		return
	end

	if CombatServer.CanPlayerAttack and not CombatServer.CanPlayerAttack(player) then
		return
	end

	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")) :: BasePart?
	if not hum or hum.Health <= 0 or not head then
		return
	end

	local state = CombatServer.GetOrCreateState(player)
	if state.IsReloading then
		return
	end

	local stats = WeaponConfig.GetWeapon(state.EquippedWeapon)
	if not stats then
		return
	end

	local ammoInfo = state.Ammo[state.EquippedWeapon]
	if not ammoInfo or ammoInfo.Mag <= 0 then
		CombatServer.ReloadWeapon(player)
		return
	end

	-- Server-side fire rate anti-cheat check (allow 15% network jitter tolerance)
	local now = os.clock()
	if (now - state.LastShotClock) < (stats.FireRate * 0.85) then
		return
	end

	-- Validate ray origin is near the player's head/camera (prevent wallhack origin spoofing)
	local validatedOrigin = clientOrigin
	if (clientOrigin - head.Position).Magnitude > 14 then
		validatedOrigin = head.Position
	end

	-- Consume 1 round
	ammoInfo.Mag -= 1
	state.LastShotClock = now
	CombatServer.SyncWeaponState(player)

	-- Auto-reload if magazine hits 0
	if ammoInfo.Mag <= 0 and ammoInfo.Reserve > 0 then
		task.defer(function()
			CombatServer.ReloadWeapon(player)
		end)
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { char }
	rayParams.IgnoreWater = true

	local profile = DataManager.GetProfile(player)
	local skin = ShopConfig.GetWeaponSkin(profile.EquippedWeaponSkin)

	local pelletCount = math.min(stats.Pellets, math.max(1, #clientDirections))
	local tracerEndpoints: { Vector3 } = {}
	local hitEffects: { { Pos: Vector3, IsCharacter: boolean, IsHeadshot: boolean } } = {}

	-- Track aggregated damage per victim model for multi-pellet weapons like Shotgun
	local aggregatedHits: {
		[Model]: {
			TotalDamage: number,
			AnyHeadshot: boolean,
			LastHitPos: Vector3,
		},
	} = {}

	for i = 1, pelletCount do
		local rawDir = clientDirections[i]
		if typeof(rawDir) == "Vector3" and rawDir.Magnitude > 0.001 then
			local unitDir = rawDir.Unit
			local result = Workspace:Raycast(validatedOrigin, unitDir * stats.MaxRange, rayParams)

			if result then
				table.insert(tracerEndpoints, result.Position)
				local hitModel, hitHum = findCharacterModel(result.Instance)

				if hitModel and hitHum and hitHum.Health > 0 and hitModel ~= char then
					local partName = result.Instance.Name
					local isHeadshot = (partName == "Head" or partName == "CyberArmor_Visor")
					local pelletDamage = stats.BaseDamage * (if isHeadshot then stats.HeadshotMultiplier else 1)

					-- Distance falloff for Shotgun & SMG
					local dist = (result.Position - validatedOrigin).Magnitude
					if stats.Id == "Shotgun" and dist > 45 then
						local falloff = math.clamp(1 - ((dist - 45) / (stats.MaxRange - 45)), 0.35, 1)
						pelletDamage *= falloff
					end

					local entry = aggregatedHits[hitModel]
					if not entry then
						entry = {
							TotalDamage = 0,
							AnyHeadshot = false,
							LastHitPos = result.Position,
						}
						aggregatedHits[hitModel] = entry
					end
					entry.TotalDamage += pelletDamage
					if isHeadshot then
						entry.AnyHeadshot = true
					end
					entry.LastHitPos = result.Position

					table.insert(hitEffects, {
						Pos = result.Position,
						IsCharacter = true,
						IsHeadshot = isHeadshot,
					})
				else
					table.insert(hitEffects, {
						Pos = result.Position,
						IsCharacter = false,
						IsHeadshot = false,
					})
				end
			else
				table.insert(tracerEndpoints, validatedOrigin + unitDir * stats.MaxRange)
			end
		end
	end

	-- Apply server-validated damage to each hit victim
	if CombatServer.OnValidatedHit then
		for victimModel, hitData in pairs(aggregatedHits) do
			local finalDamage = math.max(1, math.floor(hitData.TotalDamage + 0.5))
			CombatServer.OnValidatedHit(
				player,
				victimModel,
				finalDamage,
				hitData.AnyHeadshot,
				stats.Id,
				hitData.LastHitPos
			)
		end
	end

	-- Broadcast weapon fire visuals (tracers, sounds, impact sparks) to clients
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local visualRemote = remotes:FindFirstChild("WeaponFiredVisual") :: RemoteEvent?
		if visualRemote then
			visualRemote:FireAllClients(
				player,
				state.EquippedWeapon,
				validatedOrigin,
				tracerEndpoints,
				hitEffects,
				skin.PrimaryNeon
			)
		end
	end
end

function CombatServer.CleanupPlayer(player: Player)
	PlayerStates[player] = nil
end

return CombatServer

