--!strict
--[[
	NEON DUEL — 1VS1 FPS SHOOTER
	Module: ReplicatedStorage.Modules.SoundManager
	Description: Centralized sound controller for weapons, hitmarkers, UI, and arena rotation events.
]]

local SoundService = game:GetService("SoundService")

local SoundManager = {}

SoundManager.SfxVolume = 0.8
SoundManager.MusicVolume = 0.45

SoundManager.Presets = {
	UIClick = { Id = "rbxassetid://6895079853", Pitch = 1.15, Volume = 0.5 },
	UIHover = { Id = "rbxassetid://6895079853", Pitch = 1.45, Volume = 0.25 },
	Hitmarker = { Id = "rbxassetid://160432334", Pitch = 1.2, Volume = 0.65 },
	Headshot = { Id = "rbxassetid://160432334", Pitch = 0.85, Volume = 0.95 },
	Reload = { Id = "rbxassetid://9114221580", Pitch = 1.0, Volume = 0.6 },
	WeaponSwitch = { Id = "rbxassetid://9114221580", Pitch = 1.35, Volume = 0.45 },
	ArenaWarning = { Id = "rbxassetid://9114074725", Pitch = 0.95, Volume = 0.7 },
	ArenaSwitch = { Id = "rbxassetid://9114074725", Pitch = 1.25, Volume = 0.85 },
	MatchVictory = { Id = "rbxassetid://1843529634", Pitch = 1.0, Volume = 0.8 },
}

function SoundManager.Play2D(presetName: string, customPitch: number?, customVolume: number?)
	local preset = SoundManager.Presets[presetName]
	if not preset then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "SFX_" .. presetName
	sound.SoundId = preset.Id
	sound.PlaybackSpeed = customPitch or preset.Pitch
	sound.Volume = (customVolume or preset.Volume) * SoundManager.SfxVolume
	sound.Parent = SoundService
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(4, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function SoundManager.PlayWeaponFire(soundId: string, pitch: number, parentPart: Instance?)
	local sound = Instance.new("Sound")
	sound.Name = "WeaponFireSFX"
	sound.SoundId = soundId
	sound.PlaybackSpeed = pitch + (math.random(-4, 4) * 0.01)
	sound.Volume = 0.75 * SoundManager.SfxVolume
	sound.RollOffMaxDistance = 180
	sound.RollOffMinDistance = 12
	sound.Parent = parentPart or SoundService
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(3, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function SoundManager.SetVolumes(sfxVolume: number, musicVolume: number)
	SoundManager.SfxVolume = math.clamp(sfxVolume, 0, 1)
	SoundManager.MusicVolume = math.clamp(musicVolume, 0, 1)
end

return SoundManager

