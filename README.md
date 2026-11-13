# NEON DUEL — Edition 2.0 (1VS1 Cyberpunk FPS Shooter)

A complete, competitive 1v1 multiplayer First-Person Shooter built for **Roblox Studio (Luau)** (`NeonDuel.rbxlx` + modular `src/` architecture), accompanied by an instant standalone **3D Web Playable Preview** (`index.html`).

---

## 1. Project Structure

```text
1vs1/
├── NeonDuel.rbxlx                                # Ready-to-open Roblox Studio Place file
├── default.project.json                          # Rojo project configuration
├── src/
│   ├── ReplicatedStorage/
│   │   └── Modules/
│   │       ├── WeaponConfig.luau                 # 5 weapon classes + procedural 3D cyber weapon builder
│   │       ├── ArenaConfig.luau                  # 5 cyberpunk arenas + 120s (2-min) rotation config
│   │       ├── ShopConfig.luau                   # Weapon skins, Character skins, XP/Level & Coin rewards
│   │       └── SoundManager.luau                 # Centralized weapon, hitmarker, UI & arena audio
│   ├── ServerScriptService/
│   │   ├── MainServer.server.luau                # Server bootstrapper & RemoteEvent network wiring
│   │   ├── DataManager.luau                      # DataStoreService + OrderedDataStore leaderboards
│   │   ├── ArenaBuilder.luau                     # Procedural 3D builder for all 5 cyberpunk arenas & lighting
│   │   ├── CombatServer.luau                     # Server-authoritative ammo, reload & raycast validation
│   │   ├── MatchManager.luau                     # 1v1 matchmaking, 100 HP logic & 120s arena rotation
│   │   └── ShopServer.luau                       # Server-validated skin shop & 3D cyber armor attachment
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           ├── ClientMain.client.luau            # Client bootstrapper & RemoteEvent listeners
│           ├── MainMenuUI.luau                   # Cybercity Edition 2.0 Main Menu UI (Image 1 design)
│           ├── HUDController.luau                # Both players' 100 HP bars, 02:00 timer, scoreboard & scope
│           └── FPSController.luau                # 1st-person camera, 3D viewmodel, ADS, recoil & tracers
├── index.html                                    # Instant playable 3D browser preview
└── web/
    ├── styles.css                                # Cyberpunk Edition 2.0 UI & HUD styling
    └── game.js                                   # 3D cyberpunk street/arena renderer & FPS engine
```

---

## 2. Key Systems Implemented

### Main Menu (`MainMenuUI.luau` / `index.html`)
- Designed after the **Cybercity Edition 2.0** reference layout:
  - Live 3D rain-slicked neon street background vista with purple, blue, and cyan reflections.
  - Left-aligned translucent dark glass sidebar with metallic **NEON DUEL** logo and slanted cursive *Edition 2.0* badge.
  - Glowing cyan menu items (`PLAY 1VS1`, `FRIEND MATCH`, `SHOP`, `PLAYER PROFILE`, `SETTINGS`) featuring the purple highlight box and white corner targeting brackets (`[ ]`) on hover/selection.
  - Bottom-right `+ NAVIGATE` and `✕ SELECT` control legend.

### 120-Second (2-Minute) Arena Rotation System (`ArenaConfig.luau` & `MatchManager.luau`)
- **`ArenaConfig.ROTATION_INTERVAL = 120`** (2 minutes per arena).
- 5 unique procedural 3D futuristic cyberpunk arenas built by `ArenaBuilder.luau`:
  1. **Cybercity Neon Street** — Wet reflective downtown boulevard with neon skyscrapers, tram tracks, and cyber sports cars.
  2. **Quantum Core Reactor** — Suspended hexagonal dark-metal platform over a glowing plasma fusion core.
  3. **Synthwave Sky Matrix** — High-altitude rooftops connected by translucent neon skybridges.
  4. **Void Citadel Lab** — Sleek obsidian facility with glowing purple cryo-stasis pods and monoliths.
  5. **Hyperloop Station Zero** — Futuristic maglev transit hub with central bullet train cover.
- **Health Preservation**: When switching arenas at `00:00`, `MatchManager.luau` records and preserves **both players' exact current HP**, kills, and ammo while playing the smooth **ARENA CHANGING** transition overlay.

### 5 Futuristic Weapons (`WeaponConfig.luau` & `CombatServer.luau`)
| Slot | Weapon Name | Class | Mode | Base / Head Damage | Fire Rate | Mag / Reserve | Reload |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `[1]` | **PULSE RIFLE VX-4** | Assault Rifle | Auto | `22` / `35` | `0.11s` | `30 / 150` | `2.0s` |
| `[2]` | **ION RAILGUN SR-9** | Sniper Rifle | Semi (Scope) | `85` / `153` | `1.25s` | `5 / 30` | `2.8s` |
| `[3]` | **PLASMA BREACHER SG-8** | Shotgun | Semi (8 Pellets) | `14×8` / `19×8` | `0.82s` | `6 / 36` | `2.4s` |
| `[4]` | **VECTOR NEON X9** | SMG | Auto | `15` / `23` | `0.072s` | `36 / 180` | `1.6s` |
| `[5]` | **CYBER TALON P2** | Pistol | Semi | `28` / `50` | `0.20s` | `12 / 72` | `1.25s` |

---

## 3. How to Run & Test

1. **In Roblox Studio**:
   - Double-click [NeonDuel.rbxlx](file:///c:/Users/Noutbukcom/Desktop/1vs1/NeonDuel.rbxlx) to open the complete place directly in Roblox Studio (or sync the `src/` folder using Rojo with [default.project.json](file:///c:/Users/Noutbukcom/Desktop/1vs1/default.project.json)).
   - Press **F5 (Play)** to test solo against the Cyber Bot / Training Dummy, or use the **Test -> 2 Players Local Server** mode in Roblox Studio to test 2-player multiplayer matchmaking.
2. **Instant 3D Web Preview**:
   - Open [index.html](file:///c:/Users/Noutbukcom/Desktop/1vs1/index.html) in any browser to test the Cybercity Edition 2.0 Main Menu, 5 weapons, Shop, Profile, and 120-second Arena Rotation immediately.

