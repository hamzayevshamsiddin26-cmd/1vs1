/**
 * ============================================================================
 * CS 1.6 TACTICAL DUEL — 1VS1 FPS SHOOTER
 * Authentic Counter-Strike 1.6 3D Shaded Polygon Engine, AABB Collision,
 * Raycast Wall/Crate Occlusion, 5 Classic CS Maps & 120s Map Rotation
 * ============================================================================
 */

(() => {
  'use strict';

  // IMPORTANT REQUIREMENT: Map/Arena rotation happens every 2 MINUTES (120 seconds), NOT 30 seconds.
  const ARENA_ROTATION_SECONDS = 120;

  // --------------------------------------------------------------------------
  // 1. 5 CLASSIC COUNTER-STRIKE 1.6 WEAPONS
  // --------------------------------------------------------------------------
  const WEAPONS = [
    {
      id: 'AssaultRifle',
      slot: 1,
      name: 'CV-47 (AK-47)',
      short: 'AK-47',
      fireMode: 'Auto',
      baseDamage: 27,
      headMultiplier: 3.25, // 88 headshot
      fireRate: 0.105,
      magSize: 30,
      reserveAmmo: 90,
      reloadTime: 2.3,
      pellets: 1,
      hipSpread: 1.8,
      adsSpread: 0.35,
      adsFov: 55,
      useScope: false,
      recoilKick: 0.24,
      soundPitch: 135,
      bodyColor: '#26292c',
      accentColor: '#7a4924', // Wood handguard & stock
    },
    {
      id: 'SniperRifle',
      slot: 2,
      name: 'MAGNUM SNIPER (AWP)',
      short: 'AWP',
      fireMode: 'Semi',
      baseDamage: 95,
      headMultiplier: 2.0, // 190 lethal headshot
      fireRate: 1.35,
      magSize: 10,
      reserveAmmo: 30,
      reloadTime: 2.9,
      pellets: 1,
      hipSpread: 4.8,
      adsSpread: 0.02,
      adsFov: 22,
      useScope: true,
      recoilKick: 0.62,
      soundPitch: 75,
      bodyColor: '#3f5238', // Classic CS 1.6 Olive Green AWP chassis
      accentColor: '#1b1d1f',
    },
    {
      id: 'Shotgun',
      slot: 3,
      name: 'LEONE 12 GAUGE (M3)',
      short: 'M3',
      fireMode: 'Semi',
      baseDamage: 16, // 16 x 8 = 128 max close-range damage
      headMultiplier: 1.5,
      fireRate: 0.88,
      magSize: 8,
      reserveAmmo: 32,
      reloadTime: 2.5,
      pellets: 8,
      hipSpread: 4.6,
      adsSpread: 2.8,
      adsFov: 62,
      useScope: false,
      recoilKick: 0.50,
      soundPitch: 95,
      bodyColor: '#222528',
      accentColor: '#3b4045',
    },
    {
      id: 'SMG',
      slot: 4,
      name: 'KM SUB-MACHINE (MP5)',
      short: 'MP5',
      fireMode: 'Auto',
      baseDamage: 18,
      headMultiplier: 1.85, // 33 headshot
      fireRate: 0.075,
      magSize: 30,
      reserveAmmo: 120,
      reloadTime: 1.8,
      pellets: 1,
      hipSpread: 2.2,
      adsSpread: 0.65,
      adsFov: 60,
      useScope: false,
      recoilKick: 0.14,
      soundPitch: 185,
      bodyColor: '#1f2326',
      accentColor: '#32373c',
    },
    {
      id: 'Pistol',
      slot: 5,
      name: 'NIGHT HAWK .50C (DEAGLE)',
      short: 'DEAGLE',
      fireMode: 'Semi',
      baseDamage: 38,
      headMultiplier: 2.75, // 104 lethal headshot
      fireRate: 0.24,
      magSize: 7,
      reserveAmmo: 35,
      reloadTime: 1.6,
      pellets: 1,
      hipSpread: 1.4,
      adsSpread: 0.25,
      adsFov: 64,
      useScope: false,
      recoilKick: 0.36,
      soundPitch: 110,
      bodyColor: '#a8b0b8', // Brushed silver/steel Desert Eagle
      accentColor: '#232629',
    },
  ];

  // --------------------------------------------------------------------------
  // 2. 5 CLASSIC COUNTER-STRIKE 1.6 ARENAS (EXPANSIVE 190x260 TACTICAL MAPS)
  // --------------------------------------------------------------------------
  function buildSegmentedPerimeter(halfW, halfD, wallH, colNS, colEW, pillarCol) {
    const segs = [];
    // Subdivide North (-Z) and South (+Z) walls into 5 segments for accurate 3D depth sorting
    const nx = 5;
    const segW = (halfW * 2) / nx;
    for (let i = 0; i < nx; i++) {
      const cx = -halfW + segW * (i + 0.5);
      segs.push({ x: cx, y: 0, z: -halfD, w: segW + 0.2, h: wallH, d: 4.5, type: 'wall', color: colNS });
      segs.push({ x: cx, y: 0, z: halfD, w: segW + 0.2, h: wallH, d: 4.5, type: 'wall', color: colNS });
      if (i > 0) {
        const px = -halfW + segW * i;
        segs.push({ x: px, y: 0, z: -halfD + 2.2, w: 3.2, h: wallH + 1.5, d: 3.2, type: 'wall', color: pillarCol });
        segs.push({ x: px, y: 0, z: halfD - 2.2, w: 3.2, h: wallH + 1.5, d: 3.2, type: 'wall', color: pillarCol });
      }
    }
    // Subdivide West (-X) and East (+X) walls into 7 segments
    const nz = 7;
    const segD = (halfD * 2) / nz;
    for (let i = 0; i < nz; i++) {
      const cz = -halfD + segD * (i + 0.5);
      segs.push({ x: -halfW, y: 0, z: cz, w: 4.5, h: wallH, d: segD + 0.2, type: 'wall', color: colEW });
      segs.push({ x: halfW, y: 0, z: cz, w: 4.5, h: wallH, d: segD + 0.2, type: 'wall', color: colEW });
      if (i > 0) {
        const pz = -halfD + segD * i;
        segs.push({ x: -halfW + 2.2, y: 0, z: pz, w: 3.2, h: wallH + 1.5, d: 3.2, type: 'wall', color: pillarCol });
        segs.push({ x: halfW - 2.2, y: 0, z: pz, w: 3.2, h: wallH + 1.5, d: 3.2, type: 'wall', color: pillarCol });
      }
    }
    return segs;
  }

  const ARENAS = [
    {
      index: 1,
      id: 'de_dust2',
      name: 'DE_DUST2 (LONG, CATWALK & MID DOORS)',
      subtitle: 'EXPANSIVE SANDSTONE SECTOR // DOUBLE DOORS, PIT & ORDNANCE CRATES',
      skyTop: '#3e6d9c',
      skyMid: '#7ea4c4',
      skyBottom: '#dfd0b2',
      fogColor: [208, 190, 154],
      floorColor: '#c2a778',
      floorGridColor: 'rgba(110, 88, 54, 0.32)',
      wallColor: '#cdb486',
      crateColor: '#9e7242',
      doorColor: '#734d2b',
      blocks: [
        ...buildSegmentedPerimeter(95, 130, 26, '#c7ad7e', '#baa070', '#a68b5b'),
        // Iconic Dust2 Mid Double Doors (Center divider wall with peek gap)
        { x: -24, y: 0, z: 0, w: 36, h: 19, d: 4.2, type: 'wall', color: '#c2a676' },
        { x: 24, y: 0, z: 0, w: 36, h: 19, d: 4.2, type: 'wall', color: '#c2a676' },
        { x: -4.2, y: 0, z: 0, w: 3.8, h: 15, d: 1.8, type: 'crate', color: '#6b4423' },
        { x: 4.2, y: 0, z: 0, w: 3.8, h: 15, d: 1.8, type: 'crate', color: '#6b4423' },
        // Long A / B Side Wing Walls & Pillars
        { x: -64, y: 0, z: -36, w: 22, h: 18, d: 5, type: 'wall', color: '#bfa372' },
        { x: 64, y: 0, z: 36, w: 22, h: 18, d: 5, type: 'wall', color: '#bfa372' },
        { x: -64, y: 0, z: 36, w: 22, h: 18, d: 5, type: 'wall', color: '#bfa372' },
        { x: 64, y: 0, z: -36, w: 22, h: 18, d: 5, type: 'wall', color: '#bfa372' },
        // Tactical Wooden Cover Crates & Double-Stacked Sniper Crates
        { x: -28, y: 0, z: 42, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#9c7040' },
        { x: -21, y: 0, z: 42, w: 5.5, h: 3.8, d: 5.5, type: 'crate', color: '#ab7e4c' },
        { x: 28, y: 0, z: 38, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#9c7040' },
        { x: 28, y: 7, z: 38, w: 6.5, h: 6, d: 6.5, type: 'crate', color: '#8c6234' },
        { x: -28, y: 0, z: -42, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#9c7040' },
        { x: -28, y: 7, z: -42, w: 6.5, h: 6, d: 6.5, type: 'crate', color: '#8c6234' },
        { x: 28, y: 0, z: -38, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#9c7040' },
        // Mid & Spawn Bunker Crates
        { x: 0, y: 0, z: 64, w: 12, h: 5.8, d: 5.5, type: 'crate', color: '#a37846' },
        { x: 0, y: 0, z: -64, w: 12, h: 5.8, d: 5.5, type: 'crate', color: '#a37846' },
        { x: -52, y: 0, z: 0, w: 9, h: 7.5, d: 9, type: 'crate', color: '#94683a' },
        { x: 52, y: 0, z: 0, w: 9, h: 7.5, d: 9, type: 'crate', color: '#94683a' },
        { x: -38, y: 0, z: 78, w: 8, h: 6.5, d: 8, type: 'crate', color: '#9c7040' },
        { x: 38, y: 0, z: 78, w: 8, h: 6.5, d: 8, type: 'crate', color: '#9c7040' },
        { x: -38, y: 0, z: -78, w: 8, h: 6.5, d: 8, type: 'crate', color: '#9c7040' },
        { x: 38, y: 0, z: -78, w: 8, h: 6.5, d: 8, type: 'crate', color: '#9c7040' },
      ],
    },
    {
      index: 2,
      id: 'fy_pool_day',
      name: 'FY_POOL_DAY / AIM_MAP XL',
      subtitle: 'CLASSIC CS 1.6 SYMMETRICAL 1VS1 TACTICAL ARENA // EXPANDED SECTOR',
      skyTop: '#3d6996',
      skyMid: '#789ec2',
      skyBottom: '#c8d6e2',
      fogColor: [182, 198, 212],
      floorColor: '#8a949e',
      floorGridColor: 'rgba(50, 60, 70, 0.35)',
      wallColor: '#8f4b3c',
      crateColor: '#8c663b',
      blocks: [
        ...buildSegmentedPerimeter(95, 130, 25, '#8c4c3e', '#7d4235', '#693529'),
        // Center Pool Ceramic Divider Pillars & Diving Platform
        { x: -32, y: 0, z: 0, w: 11, h: 17, d: 11, type: 'wall', color: '#cfd6dc' },
        { x: 32, y: 0, z: 0, w: 11, h: 17, d: 11, type: 'wall', color: '#cfd6dc' },
        { x: 0, y: 0, z: 0, w: 15, h: 6.2, d: 15, type: 'crate', color: '#467296' },
        { x: -62, y: 0, z: -28, w: 10, h: 15, d: 10, type: 'wall', color: '#c4ccd4' },
        { x: 62, y: 0, z: 28, w: 10, h: 15, d: 10, type: 'wall', color: '#c4ccd4' },
        { x: -62, y: 0, z: 28, w: 10, h: 15, d: 10, type: 'wall', color: '#c4ccd4' },
        { x: 62, y: 0, z: -28, w: 10, h: 15, d: 10, type: 'wall', color: '#c4ccd4' },
        // Aim_map wooden crates
        { x: -36, y: 0, z: 48, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#996e3f' },
        { x: 36, y: 0, z: 48, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#996e3f' },
        { x: -36, y: 0, z: -48, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#996e3f' },
        { x: 36, y: 0, z: -48, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#996e3f' },
        { x: 0, y: 0, z: 68, w: 12, h: 6, d: 6, type: 'crate', color: '#8f6436' },
        { x: 0, y: 0, z: -68, w: 12, h: 6, d: 6, type: 'crate', color: '#8f6436' },
      ],
    },
    {
      index: 3,
      id: 'de_inferno',
      name: 'DE_INFERNO (COURTYARD & BANANA)',
      subtitle: 'ITALIAN COBBLESTONE PLAZA // BELL TOWER, TERRACOTTA WALLS & OAK CRATES',
      skyTop: '#45688a',
      skyMid: '#829cb3',
      skyBottom: '#d6c8ae',
      fogColor: [198, 184, 160],
      floorColor: '#7a7368',
      floorGridColor: 'rgba(42, 38, 32, 0.4)',
      wallColor: '#c9b898',
      crateColor: '#734f2c',
      blocks: [
        ...buildSegmentedPerimeter(95, 130, 26, '#c4b292', '#b5a382', '#96523e'),
        // Courtyard Bell Tower / Fountain Monument & Side Colonnades
        { x: 0, y: 0, z: 0, w: 13, h: 20, d: 13, type: 'wall', color: '#9c5440' },
        { x: -48, y: 0, z: -18, w: 18, h: 16, d: 5, type: 'wall', color: '#bfa984' },
        { x: 48, y: 0, z: 18, w: 18, h: 16, d: 5, type: 'wall', color: '#bfa984' },
        { x: -28, y: 0, z: 32, w: 9, h: 7, d: 9, type: 'crate', color: '#78522e' },
        { x: 28, y: 0, z: 32, w: 9, h: 7, d: 9, type: 'crate', color: '#78522e' },
        { x: -28, y: 0, z: -32, w: 9, h: 7, d: 9, type: 'crate', color: '#78522e' },
        { x: 28, y: 0, z: -32, w: 9, h: 7, d: 9, type: 'crate', color: '#78522e' },
        { x: 0, y: 0, z: 62, w: 11, h: 6, d: 6, type: 'crate', color: '#875e36' },
        { x: 0, y: 0, z: -62, w: 11, h: 6, d: 6, type: 'crate', color: '#875e36' },
        { x: -54, y: 0, z: 58, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#78522e' },
        { x: 54, y: 0, z: -58, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#78522e' },
      ],
    },
    {
      index: 4,
      id: 'de_nuke',
      name: 'DE_NUKE (OUTSIDE WAREHOUSE YARD)',
      subtitle: 'INDUSTRIAL NUCLEAR YARD // SHIPPING CONTAINERS, SILO & BUNKERS',
      skyTop: '#3e4d5c',
      skyMid: '#687888',
      skyBottom: '#a6b2be',
      fogColor: [152, 164, 176],
      floorColor: '#5c6268',
      floorGridColor: 'rgba(28, 32, 36, 0.45)',
      wallColor: '#6c757e',
      crateColor: '#3d5a73',
      blocks: [
        ...buildSegmentedPerimeter(95, 130, 26, '#687078', '#5c646c', '#495057'),
        // Industrial Shipping Containers & Yellow/Olive Crates
        { x: -24, y: 0, z: 0, w: 11, h: 10.5, d: 28, type: 'crate', color: '#345068' },
        { x: 24, y: 0, z: 0, w: 11, h: 10.5, d: 28, type: 'crate', color: '#45573f' },
        { x: -56, y: 0, z: -38, w: 11, h: 10.5, d: 24, type: 'crate', color: '#6b3832' },
        { x: 56, y: 0, z: 38, w: 11, h: 10.5, d: 24, type: 'crate', color: '#6b3832' },
        { x: 0, y: 0, z: 48, w: 10, h: 6.5, d: 7, type: 'crate', color: '#9c8234' },
        { x: 0, y: 0, z: -48, w: 10, h: 6.5, d: 7, type: 'crate', color: '#9c8234' },
        { x: -34, y: 0, z: 68, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#39556e' },
        { x: 34, y: 0, z: 68, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#495944' },
        { x: -34, y: 0, z: -68, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#495944' },
        { x: 34, y: 0, z: -68, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#39556e' },
      ],
    },
    {
      index: 5,
      id: 'de_train',
      name: 'DE_TRAIN (SOVIET RAIL TERMINAL)',
      subtitle: 'SOVIET FREIGHT YARD // ARMORED TRAIN CARS & LOADING DOCKS',
      skyTop: '#384654',
      skyMid: '#5e6c7a',
      skyBottom: '#98a2ac',
      fogColor: [142, 152, 162],
      floorColor: '#52565a',
      floorGridColor: 'rgba(26, 28, 30, 0.45)',
      wallColor: '#70564a',
      crateColor: '#485442',
      blocks: [
        ...buildSegmentedPerimeter(95, 130, 26, '#6e5448', '#624a3e', '#4d3a30'),
        // Freight Train Cars along center and side tracks
        { x: 0, y: 0, z: -32, w: 11, h: 10.5, d: 28, type: 'crate', color: '#44543e' },
        { x: 0, y: 0, z: 32, w: 11, h: 10.5, d: 28, type: 'crate', color: '#5c3a32' },
        { x: -46, y: 0, z: 0, w: 11, h: 10.5, d: 28, type: 'crate', color: '#3e4e5c' },
        { x: 46, y: 0, z: 0, w: 11, h: 10.5, d: 28, type: 'crate', color: '#44543e' },
        { x: -26, y: 0, z: 58, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#8c663b' },
        { x: 26, y: 0, z: 58, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#8c663b' },
        { x: -26, y: 0, z: -58, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#8c663b' },
        { x: 26, y: 0, z: -58, w: 8.5, h: 7, d: 8.5, type: 'crate', color: '#8c663b' },
      ],
    },
  ];

  // --------------------------------------------------------------------------
  // 3. TACTICAL FINISHES / SKINS (Realistic Military Finishes — No Rainbow)
  // --------------------------------------------------------------------------
  const WEAPON_SKINS = [
    { id: 'DefaultCyan', name: 'STANDARD ISSUE', rarity: 'Military', price: 0, body: '#26292c', accent: '#7a4924', desc: 'Factory Russian & NATO ordnance finish with oiled walnut stock.' },
    { id: 'SynthMagenta', name: 'OLIVE DRAB CAMO', rarity: 'Tactical', price: 250, body: '#3b4735', accent: '#222620', desc: 'Matte olive drab field camouflage for woodland operations.' },
    { id: 'VoidPurple', name: 'DESERT STORM TAN', rarity: 'Tactical', price: 500, body: '#b5996e', accent: '#453b2c', desc: 'Dust II arid sand-resistant cerakote finish.' },
    { id: 'EmeraldMatrix', name: 'URBAN GRAPHITE', rarity: 'Spec-Ops', price: 650, body: '#3c4248', accent: '#181a1c', desc: 'Subdued charcoal grey finish for night counter-terrorist raids.' },
    { id: 'CrimsonProtocol', name: 'CARBON STEEL MK-II', rarity: 'Classified', price: 1000, body: '#1a1c1e', accent: '#5c2424', desc: 'Heavy blued steel receiver with dark mahogany grip.' },
    { id: 'SolarArchon', name: 'BRUSHED TITANIUM', rarity: 'Commander', price: 1800, body: '#9aa2aa', accent: '#2c3034', desc: 'Precision CNC-machined brushed stainless & titanium finish.' },
  ];

  const CHARACTER_SKINS = [
    { id: 'CyberOperative', name: 'SAS COUNTER-TERRORIST', rarity: 'Standard', price: 0, vest: '#28323c', uniform: '#3c4c5c', desc: 'British SAS tactical gas-mask & navy assault rig.' },
    { id: 'PhantomStriker', name: 'GSG-9 TACTICAL', rarity: 'Tactical', price: 350, vest: '#384034', uniform: '#4f5948', desc: 'German border police olive helmet & heavy kevlar.' },
    { id: 'NeonSamurai', name: 'GIGN INTERVENTION', rarity: 'Spec-Ops', price: 750, vest: '#222830', uniform: '#303a48', desc: 'French GIGN polycarbonate visor & ballistic vest.' },
    { id: 'HyperVanguard', name: 'SEAL TEAM SIX', rarity: 'Classified', price: 1200, vest: '#4c4436', uniform: '#6e624c', desc: 'Desert digital camo combat uniform with plate carrier.' },
    { id: 'ArchonOverlord', name: 'SPETSNAZ ALPHA', rarity: 'Commander', price: 2200, vest: '#2a2e28', uniform: '#3f463c', desc: 'Heavy Altyn titanium helmet & assault body armor.' },
  ];

  // --------------------------------------------------------------------------
  // 4. PLAYER PROFILE & DATASTORE PERSISTENCE
  // --------------------------------------------------------------------------
  const STORAGE_KEY = 'NEON_DUEL_PROFILE_V2';

  function getDefaultProfile() {
    return {
      name: 'PLAYER_1',
      coins: 350,
      xp: 0,
      level: 1,
      wins: 0,
      losses: 0,
      kills: 0,
      deaths: 0,
      winStreak: 0,
      ownedWeaponSkins: { DefaultCyan: true },
      equippedWeaponSkin: 'DefaultCyan',
      ownedCharacterSkins: { CyberOperative: true },
      equippedCharacterSkin: 'CyberOperative',
      settings: {
        fov: 78,
        sensitivity: 0.5,
        aimSensitivity: 0.35,
        sfxVolume: 0.8,
        highQualityNeon: true,
      },
    };
  }

  function loadProfile() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) return Object.assign(getDefaultProfile(), JSON.parse(raw));
    } catch (_) {}
    return getDefaultProfile();
  }

  let profile = loadProfile();

  function saveProfile() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(profile));
    } catch (_) {}
    updateProfileStrip();
  }

  function addXP(amount) {
    profile.xp += amount;
    let req = profile.level * 150;
    while (profile.xp >= req) {
      profile.xp -= req;
      profile.level += 1;
      profile.coins += 100;
      req = profile.level * 150;
    }
    saveProfile();
  }

  // --------------------------------------------------------------------------
  // 5. AUTHENTIC CS 1.6 ACOUSTIC GUNSHOT & FOLEY SYNTHESIS (WebAudio)
  // --------------------------------------------------------------------------
  let audioCtx = null;
  let noiseBuffer = null;

  function ensureAudio() {
    if (!audioCtx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (AC) {
        audioCtx = new AC();
        const bufSize = audioCtx.sampleRate * 0.5;
        noiseBuffer = audioCtx.createBuffer(1, bufSize, audioCtx.sampleRate);
        const data = noiseBuffer.getChannelData(0);
        for (let i = 0; i < bufSize; i++) {
          data[i] = Math.random() * 2 - 1;
        }
      }
    }
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume();
    }
  }

  function playSound(type, pitchFreq = 130) {
    const vol = (profile.settings.sfxVolume ?? 0.8) * 0.38;
    if (vol <= 0.01) return;
    ensureAudio();
    if (!audioCtx) return;

    const now = audioCtx.currentTime;

    if (type === 'shoot') {
      // Realistic CS 1.6 firearm crack (filtered white-noise burst + low-frequency thump)
      if (noiseBuffer) {
        const noise = audioCtx.createBufferSource();
        noise.buffer = noiseBuffer;
        const filter = audioCtx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(pitchFreq * 8, now);
        filter.Q.setValueAtTime(0.8, now);

        const nGain = audioCtx.createGain();
        nGain.gain.setValueAtTime(vol * 1.3, now);
        nGain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);

        noise.connect(filter);
        filter.connect(nGain);
        nGain.connect(audioCtx.destination);
        noise.start(now);
        noise.stop(now + 0.17);
      }

      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(pitchFreq, now);
      osc.frequency.exponentialRampToValueAtTime(32, now + 0.12);
      gain.gain.setValueAtTime(vol, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.13);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.13);
    } else if (type === 'hit' || type === 'headshot') {
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = type === 'headshot' ? 'square' : 'triangle';
      osc.frequency.setValueAtTime(type === 'headshot' ? 780 : 420, now);
      osc.frequency.exponentialRampToValueAtTime(140, now + 0.08);
      gain.gain.setValueAtTime(vol * 0.9, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.09);
    } else if (type === 'reload' || type === 'reload_magout') {
      // Metallic magazine release catch + slide out
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(240, now);
      osc.frequency.exponentialRampToValueAtTime(135, now + 0.085);
      gain.gain.setValueAtTime(vol * 0.55, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.095);
    } else if (type === 'reload_magin') {
      // Heavy metallic magazine lock-in CLACK
      [0, 0.055].forEach((offset, idx) => {
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = idx === 0 ? 'square' : 'triangle';
        osc.frequency.setValueAtTime(idx === 0 ? 310 : 620, now + offset);
        osc.frequency.exponentialRampToValueAtTime(idx === 0 ? 190 : 390, now + offset + 0.05);
        gain.gain.setValueAtTime(vol * 0.65, now + offset);
        gain.gain.exponentialRampToValueAtTime(0.001, now + offset + 0.055);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now + offset);
        osc.stop(now + offset + 0.06);
      });
    } else if (type === 'reload_bolt') {
      // Iconic CS 1.6 charging handle / bolt rack CHK-CHK
      [0, 0.11].forEach((offset, idx) => {
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(idx === 0 ? 440 : 560, now + offset);
        osc.frequency.exponentialRampToValueAtTime(idx === 0 ? 260 : 340, now + offset + 0.06);
        gain.gain.setValueAtTime(vol * 0.7, now + offset);
        gain.gain.exponentialRampToValueAtTime(0.001, now + offset + 0.065);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now + offset);
        osc.stop(now + offset + 0.07);
      });
    } else if (type === 'shell_drop') {
      // Brass casing hitting floor metallic ping
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1850 + Math.random() * 350, now);
      gain.gain.setValueAtTime(vol * 0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.045);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.05);
    } else if (type === 'ui') {
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(420, now);
      gain.gain.setValueAtTime(vol * 0.35, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.04);
    } else if (type === 'arenaSwitch') {
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(220, now);
      osc.frequency.linearRampToValueAtTime(330, now + 0.35);
      gain.gain.setValueAtTime(vol * 0.7, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.4);
    }
  }

  // --------------------------------------------------------------------------
  // 6. MATCH, PLAYER & TACTICAL AI STATE
  // --------------------------------------------------------------------------
  const match = {
    active: false,
    ended: false,
    mode: 'Quick1v1',
    winCondition: 10,
    arenaIndex: 1,
    arenaTimeRemaining: ARENA_ROTATION_SECONDS, // 120 seconds (2 minutes)
    p1Name: 'CT // OPERATIVE (YOU)',
    p2Name: 'T // PHOENIX CONNEXION',
    p1Health: 100,
    p2Health: 100,
    p1Kills: 0,
    p2Kills: 0,
    botFiresBack: true,
    privateRoomCode: null,
  };

  const player = {
    x: 0,
    y: 6.2,
    z: 94,
    vy: 0,
    grounded: true,
    crouching: false,
    yaw: 0,
    pitch: 0,
    weaponIndex: 0,
    isAiming: false,
    isFiring: false,
    isReloading: false,
    reloadStartTime: 0,
    reloadDuration: 2000,
    reloadStageAudio: 0,
    lastShotClock: 0,
    lastShotMs: 0,
    boltCycleStart: 0,
    recoilKick: 0,
    recoilRoll: 0,
    recoilPitchAccum: 0,
    recoilYawAccum: 0,
    recoilSprayShots: 0,
    recoilMuzzleFlip: 0,
    screenShakeX: 0,
    screenShakeY: 0,
    muzzleFlashUntil: 0,
    muzzleFlashAngle: 0,
    hurtAlpha: 0,
    ammo: {},
  };

  const enemy = {
    x: 0,
    y: 0,
    z: -92,
    yaw: 0, // 0 faces +Z (toward player)
    targetX: 24,
    targetZ: -64,
    walkCycle: 0,
    isMoving: false,
    crouching: false,
    nextMoveChange: 0,
    nextFireTime: 0,
    burstRemaining: 0,
    nextBurstShotMs: 0,
    muzzleFlashUntil: 0,
    hitFlinchUntil: 0,
    dead: false,
    deathTime: 0,
    fallAngle: 0,
    fallVelocity: 0,
    fallDirX: 0,
    fallDirZ: -1,
    fallSideRoll: 0,
    bloodPoolSpawned: false,
  };

  const bulletImpacts = []; // 3D bullet holes & scorch marks strictly on static walls/crates
  const debrisSparks = [];  // 3D flying concrete dust, wood splinters, & crimson blood droplets
  const bloodPools = [];    // 3D crimson blood pools & splatters on the arena floor
  const bloodMists = [];    // 3D volumetric blood spray puffs at wound impact points
  const tracers = [];       // 3D supersonic brass bullet streaks (both player & enemy)
  const shellCasings = [];  // First-person ejected spinning brass casings & shotgun hulls
  const muzzleSmoke = [];   // First-person rising gunsmoke puffs from hot barrel & chamber
  const keys = {};
  const touchState = {
    moveX: 0,
    moveY: 0,
    crouchToggle: false,
    joyTouchId: null,
    joyOriginX: 0,
    joyOriginY: 0,
    lookTouchId: null,
    lookLastX: 0,
    lookLastY: 0,
    fireTouchId: null,
    fireLastX: 0,
    fireLastY: 0,
  };

  if ('ontouchstart' in window || navigator.maxTouchPoints > 0) {
    document.body.classList.add('touch-enabled');
  }

  function resetAllAmmo() {
    player.ammo = {};
    WEAPONS.forEach((w) => {
      player.ammo[w.id] = { mag: w.magSize, reserve: w.reserveAmmo };
    });
  }
  resetAllAmmo();

  // --------------------------------------------------------------------------
  // 7. DOM REFERENCES & MAIN MENU PANELS
  // --------------------------------------------------------------------------
  const canvas = document.getElementById('gameCanvas');
  const ctx = canvas.getContext('2d');
  const mainMenuScreen = document.getElementById('mainMenuScreen');
  const hudScreen = document.getElementById('hudScreen');
  const rightModalContent = document.getElementById('rightModalContent');
  const profileMiniStrip = document.getElementById('profileMiniStrip');
  const menuStatusBanner = document.getElementById('menuStatusBanner');

  let activeMenuPanel = 'play1v1';
  let currentShopTab = 'WeaponSkin';
  let customWinCondition = 10;
  let customStartArena = 1;

  function updateProfileStrip() {
    profileMiniStrip.textContent = `LVL ${profile.level} // $${profile.coins} // ${profile.wins}W - ${profile.losses}L // KILLS: ${profile.kills}`;
  }
  updateProfileStrip();

  function setStatusBanner(msg, color = '#ffb000') {
    menuStatusBanner.textContent = msg;
    menuStatusBanner.style.color = color;
  }

  function renderActiveMenuPanel() {
    if (activeMenuPanel === 'play1v1') renderPlay1v1Panel();
    else if (activeMenuPanel === 'friendMatch') renderFriendMatchPanel();
    else if (activeMenuPanel === 'shop') renderShopPanel();
    else if (activeMenuPanel === 'profile') renderProfilePanel();
    else if (activeMenuPanel === 'settings') renderSettingsPanel();
  }

  function renderPlay1v1Panel() {
    rightModalContent.innerHTML = `
      <div class="panel-header">
        <div class="panel-title">COUNTER-STRIKE 1.6 // 1VS1 TACTICAL DUEL</div>
        <div class="panel-subtitle">2 PLAYERS // 100 HP & KEVLAR // 5 CLASSIC WEAPONS // 120s MAP ROTATION</div>
      </div>
      <div class="cyber-card" style="margin-bottom:14px; line-height:1.65; font-family:Consolas,monospace; font-size:0.84rem; color:#d4dcd2;">
        <div>• <b>AUTHENTIC CS 1.6 DESIGN:</b> Realistic 3D sandstone walls, wooden crates, double doors & tactical cover.</div>
        <div>• <b>120-SECOND MAP ROTATION:</b> Automatically rotates across 5 CS maps every <b>2 MINUTES (02:00)</b> while keeping both players' exact HP.</div>
        <div>• <b>ARSENAL:</b> [1] AK-47 | [2] AWP Sniper | [3] M3 Shotgun | [4] MP5-Navy | [5] Desert Eagle .50 AE.</div>
        <div>• <b>CONTROLS:</b> <b>WASD</b> Move | <b>SPACE</b> Jump on Crates | <b>CTRL/C</b> Crouch | <b>L-Click</b> Shoot | <b>R-Click</b> Scope/Aim | <b>R</b> Reload.</div>
      </div>
      <div style="display:flex; gap:10px; flex-wrap:wrap; margin-bottom:16px;">
        <button class="cyber-btn" id="btnStartQuick1v1" style="flex:1; padding:14px;">
          ▶ PLAY 1VS1 MATCH (DE_DUST2 — FIRST TO 10 KILLS)
        </button>
        <button class="cyber-btn magenta" id="btnStartPracticeQuick" style="flex:1; padding:14px;">
          ▶ PRACTICE MODE (PASSIVE TARGET BOT)
        </button>
      </div>
      <div style="font-weight:700; font-size:0.82rem; color:#ffb000; margin-bottom:6px;">
        SELECT STARTING MAP (ROTATES EVERY 02:00 / 120 SECONDS):
      </div>
      <div class="cards-grid">
        ${ARENAS.map((a) => `
          <div class="cyber-card">
            <div style="font-weight:800; color:#ffb000; font-size:0.86rem;">${a.index}. ${a.name}</div>
            <div style="font-family:Consolas,monospace; font-size:0.71rem; color:#a4aea2;">${a.subtitle}</div>
            <button class="cyber-btn" data-deploy-arena="${a.index}" style="margin-top:6px; padding:7px 10px; font-size:0.75rem;">
              DEPLOY ON MAP 0${a.index}
            </button>
          </div>
        `).join('')}
      </div>
    `;

    document.getElementById('btnStartQuick1v1').onclick = () => {
      playSound('ui');
      startMatch('Quick1v1', 10, 1, true, 'T // PHOENIX CONNEXION');
    };
    document.getElementById('btnStartPracticeQuick').onclick = () => {
      playSound('ui');
      startMatch('PracticeMode', 10, 1, false, 'T // TRAINING DUMMY');
    };
    rightModalContent.querySelectorAll('[data-deploy-arena]').forEach((btn) => {
      btn.onclick = () => {
        playSound('ui');
        const idx = parseInt(btn.getAttribute('data-deploy-arena'), 10) || 1;
        startMatch('Quick1v1', 10, idx, true, 'T // PHOENIX CONNEXION');
      };
    });
  }

  function renderFriendMatchPanel() {
    const startArenaObj = ARENAS[(customStartArena - 1) % ARENAS.length];
    rightModalContent.innerHTML = `
      <div class="panel-header">
        <div class="panel-title">FRIEND MATCH // PRIVATE SERVER & PRACTICE</div>
        <div class="panel-subtitle">CREATE PRIVATE SERVER CODES, CHALLENGE FRIENDS, OR TRAIN SOLO</div>
      </div>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:14px;">
        <button class="cyber-btn" id="btnCycleWinCond">
          WIN LIMIT: ${customWinCondition} KILLS (CLICK TO CHANGE)
        </button>
        <button class="cyber-btn" id="btnCycleArena">
          START MAP: ${startArenaObj.index}. ${startArenaObj.name}
        </button>
      </div>

      <div class="cyber-card" style="margin-bottom:14px;">
        <div style="font-weight:800; color:#ffb000; font-size:0.86rem;">PRIVATE SERVER ROOM CODE</div>
        <div style="display:flex; gap:10px; margin-top:8px; flex-wrap:wrap;">
          <button class="cyber-btn" id="btnCreateRoomCode">GENERATE SERVER CODE</button>
          <input id="inputRoomCode" type="text" placeholder="ENTER CODE (E.G. CS1642)" value="${match.privateRoomCode || ''}"
            style="background:#141714; border:1px solid #6c7666; color:#ffb000; padding:9px 12px; font-family:Consolas,monospace; font-weight:700; flex:1;" />
          <button class="cyber-btn" id="btnJoinRoomCode">CONNECT TO SERVER</button>
        </div>
      </div>

      <div class="cyber-card">
        <div style="font-weight:800; color:#ffb000; font-size:0.86rem;">TRAINING & BOT DIFFICULTY</div>
        <div style="display:flex; gap:10px; margin-top:8px; flex-wrap:wrap;">
          <button class="cyber-btn" id="btnStartPassiveDummy" style="flex:1;">
            PRACTICE: PASSIVE TARGET DUMMY
          </button>
          <button class="cyber-btn" id="btnStartActiveFriendSim" style="flex:1;">
            1VS1 DUEL: ACTIVE TACTICAL BOT
          </button>
        </div>
      </div>
    `;

    document.getElementById('btnCycleWinCond').onclick = () => {
      playSound('ui');
      const opts = [5, 10, 15, 20];
      customWinCondition = opts[(opts.indexOf(customWinCondition) + 1) % opts.length];
      renderFriendMatchPanel();
    };
    document.getElementById('btnCycleArena').onclick = () => {
      playSound('ui');
      customStartArena = (customStartArena % ARENAS.length) + 1;
      renderFriendMatchPanel();
    };
    document.getElementById('btnCreateRoomCode').onclick = () => {
      playSound('ui');
      match.privateRoomCode = 'CS16-' + Math.floor(10 + Math.random() * 89);
      setStatusBanner(`SERVER CREATED: ${match.privateRoomCode} // CLICK CONNECT TO LAUNCH`, '#42e642');
      renderFriendMatchPanel();
    };
    document.getElementById('btnJoinRoomCode').onclick = () => {
      playSound('ui');
      const code = document.getElementById('inputRoomCode').value.trim().toUpperCase() || 'CS16-01';
      startMatch('PrivateMatch', customWinCondition, customStartArena, true, `T // RIVAL [${code}]`);
    };
    document.getElementById('btnStartPassiveDummy').onclick = () => {
      playSound('ui');
      startMatch('PracticeMode', customWinCondition, customStartArena, false, 'T // TARGET DUMMY');
    };
    document.getElementById('btnStartActiveFriendSim').onclick = () => {
      playSound('ui');
      startMatch('FriendMatch', customWinCondition, customStartArena, true, 'T // PHOENIX ELITE');
    };
  }

  function renderShopPanel() {
    const items = currentShopTab === 'WeaponSkin' ? WEAPON_SKINS : CHARACTER_SKINS;
    const ownedMap = currentShopTab === 'WeaponSkin' ? profile.ownedWeaponSkins : profile.ownedCharacterSkins;
    const equippedId = currentShopTab === 'WeaponSkin' ? profile.equippedWeaponSkin : profile.equippedCharacterSkin;

    rightModalContent.innerHTML = `
      <div class="panel-header">
        <div class="panel-title">TACTICAL ARMORY & FINISHES</div>
        <div class="panel-subtitle">FUNDS: $${profile.coins} // MILITARY WEAPON CAMOS & SPECIAL FORCES UNIFORMS</div>
      </div>
      <div style="display:flex; gap:10px; margin-bottom:12px;">
        <button class="cyber-btn" id="tabWeaponSkins" style="flex:1; border-color:${currentShopTab === 'WeaponSkin' ? '#ffb000' : '#5c6458'};">
          WEAPON FINISHES (${WEAPON_SKINS.length})
        </button>
        <button class="cyber-btn" id="tabCharSkins" style="flex:1; border-color:${currentShopTab === 'CharacterSkin' ? '#ffb000' : '#5c6458'};">
          OPERATOR UNIFORMS (${CHARACTER_SKINS.length})
        </button>
      </div>
      <div class="cards-grid">
        ${items.map((item) => {
          const isOwned = !!ownedMap[item.id];
          const isEquipped = equippedId === item.id;
          const btnText = isEquipped ? '✓ EQUIPPED' : isOwned ? 'EQUIP' : `BUY — $${item.price}`;
          return `
            <div class="cyber-card" style="border-color:${isEquipped ? '#ffb000' : '#4e564a'};">
              <div style="display:flex; justify-content:space-between; align-items:center;">
                <span style="font-weight:800; color:#ffb000; font-size:0.86rem;">${item.name}</span>
                <span style="font-family:Consolas,monospace; font-size:0.7rem; color:#a8b2a6;">${item.rarity}</span>
              </div>
              <div style="font-family:Consolas,monospace; font-size:0.74rem; color:#b8c2b6; min-height:32px;">${item.desc}</div>
              <button class="cyber-btn" data-shop-item="${item.id}" style="padding:7px 10px; font-size:0.76rem;">
                ${btnText}
              </button>
            </div>
          `;
        }).join('')}
      </div>
    `;

    document.getElementById('tabWeaponSkins').onclick = () => {
      playSound('ui');
      currentShopTab = 'WeaponSkin';
      renderShopPanel();
    };
    document.getElementById('tabCharSkins').onclick = () => {
      playSound('ui');
      currentShopTab = 'CharacterSkin';
      renderShopPanel();
    };
    rightModalContent.querySelectorAll('[data-shop-item]').forEach((btn) => {
      btn.onclick = () => {
        playSound('ui');
        const id = btn.getAttribute('data-shop-item');
        const item = items.find((i) => i.id === id);
        if (!item) return;

        if (ownedMap[item.id]) {
          if (currentShopTab === 'WeaponSkin') profile.equippedWeaponSkin = item.id;
          else profile.equippedCharacterSkin = item.id;
          saveProfile();
          setStatusBanner(`EQUIPPED ${item.name}`, '#42e642');
          renderShopPanel();
        } else if (profile.coins >= item.price) {
          profile.coins -= item.price;
          ownedMap[item.id] = true;
          if (currentShopTab === 'WeaponSkin') profile.equippedWeaponSkin = item.id;
          else profile.equippedCharacterSkin = item.id;
          saveProfile();
          setStatusBanner(`PURCHASED & EQUIPPED ${item.name}!`, '#42e642');
          renderShopPanel();
        } else {
          setStatusBanner(`INSUFFICIENT FUNDS ($${item.price} REQUIRED)`, '#e05252');
        }
      };
    });
  }

  function renderProfilePanel() {
    const reqXP = profile.level * 150;
    const totalMatches = profile.wins + profile.losses;
    const winRate = totalMatches > 0 ? Math.round((profile.wins / totalMatches) * 100) : 0;
    const kd = profile.deaths > 0 ? (profile.kills / profile.deaths).toFixed(2) : profile.kills.toString();

    const leaderboard = [
      { name: 'f0rest_CS16', wins: 48, level: 19 },
      { name: 'Neo_Pl', wins: 39, level: 16 },
      { name: 'markeloff_AWP', wins: 31, level: 14 },
      { name: profile.name + ' (YOU)', wins: profile.wins, level: profile.level },
      { name: 'Edward_AK', wins: 24, level: 11 },
      { name: 'HeatoN_SE', wins: 18, level: 9 },
    ].sort((a, b) => b.wins - a.wins);

    rightModalContent.innerHTML = `
      <div class="panel-header">
        <div class="panel-title">SERVICE RECORD // ${profile.name}</div>
        <div class="panel-subtitle">RANK LEVEL ${profile.level} (${profile.xp} / ${reqXP} XP) // FUNDS: $${profile.coins}</div>
      </div>
      <div class="stat-grid">
        <div class="stat-box"><div class="stat-val" style="color:#42e642;">${profile.wins}</div><div class="stat-lbl">MATCHES WON</div></div>
        <div class="stat-box"><div class="stat-val" style="color:#e06c5a;">${profile.losses}</div><div class="stat-lbl">LOSSES</div></div>
        <div class="stat-box"><div class="stat-val">${winRate}%</div><div class="stat-lbl">WIN RATE</div></div>
        <div class="stat-box"><div class="stat-val">${profile.kills}</div><div class="stat-lbl">TOTAL FRAGS</div></div>
        <div class="stat-box"><div class="stat-val">${kd}</div><div class="stat-lbl">K/D RATIO</div></div>
        <div class="stat-box"><div class="stat-val">${profile.winStreak}</div><div class="stat-lbl">WIN STREAK</div></div>
      </div>
      <div style="font-weight:800; font-size:0.84rem; color:#ffb000; margin:10px 0 8px 0;">
        TOP 1VS1 DUELISTS LEADERBOARD:
      </div>
      <div style="display:flex; flex-direction:column; gap:5px; font-family:Consolas,monospace; font-size:0.82rem;">
        ${leaderboard.map((row, idx) => `
          <div style="display:flex; justify-content:space-between; padding:7px 12px; background:#161916; border:1px solid #444a42; border-left:3px solid ${idx === 0 ? '#ffb000' : '#6c7666'};">
            <span>#${idx + 1}  ${row.name}</span>
            <span>WINS: ${row.wins}  |  LVL: ${row.level}</span>
          </div>
        `).join('')}
      </div>
    `;
  }

  function renderSettingsPanel() {
    const s = profile.settings;
    rightModalContent.innerHTML = `
      <div class="panel-header">
        <div class="panel-title">CONFIGURATION // CS 1.6 OPTIONS</div>
        <div class="panel-subtitle">FIELD OF VIEW, MOUSE SENSITIVITY & AUDIO SETTINGS</div>
      </div>
      <div style="display:flex; flex-direction:column; gap:10px;">
        <div class="cyber-card" style="flex-direction:row; justify-content:space-between; align-items:center;">
          <span>CAMERA FIELD OF VIEW (FOV): <b>${s.fov}°</b></span>
          <div style="display:flex; gap:8px;">
            <button class="cyber-btn" id="fovMinus">-</button>
            <button class="cyber-btn" id="fovPlus">+</button>
          </div>
        </div>
        <div class="cyber-card" style="flex-direction:row; justify-content:space-between; align-items:center;">
          <span>MOUSE SENSITIVITY: <b>${s.sensitivity.toFixed(2)}</b></span>
          <div style="display:flex; gap:8px;">
            <button class="cyber-btn" id="sensMinus">-</button>
            <button class="cyber-btn" id="sensPlus">+</button>
          </div>
        </div>
        <div class="cyber-card" style="flex-direction:row; justify-content:space-between; align-items:center;">
          <span>SOUND EFFECTS VOLUME: <b>${Math.round(s.sfxVolume * 100)}%</b></span>
          <div style="display:flex; gap:8px;">
            <button class="cyber-btn" id="volMinus">-</button>
            <button class="cyber-btn" id="volPlus">+</button>
          </div>
        </div>
      </div>
    `;

    document.getElementById('fovMinus').onclick = () => { s.fov = Math.max(65, s.fov - 4); saveProfile(); renderSettingsPanel(); };
    document.getElementById('fovPlus').onclick = () => { s.fov = Math.min(100, s.fov + 4); saveProfile(); renderSettingsPanel(); };
    document.getElementById('sensMinus').onclick = () => { s.sensitivity = Math.max(0.15, +(s.sensitivity - 0.1).toFixed(2)); saveProfile(); renderSettingsPanel(); };
    document.getElementById('sensPlus').onclick = () => { s.sensitivity = Math.min(1.8, +(s.sensitivity + 0.1).toFixed(2)); saveProfile(); renderSettingsPanel(); };
    document.getElementById('volMinus').onclick = () => { s.sfxVolume = Math.max(0, +(s.sfxVolume - 0.1).toFixed(2)); saveProfile(); renderSettingsPanel(); };
    document.getElementById('volPlus').onclick = () => { s.sfxVolume = Math.min(1, +(s.sfxVolume + 0.1).toFixed(2)); saveProfile(); renderSettingsPanel(); };
  }

  document.querySelectorAll('#cyberMenuNav .cyber-nav-item').forEach((btn) => {
    btn.addEventListener('mouseenter', () => playSound('ui'));
    btn.addEventListener('click', () => {
      playSound('ui');
      document.querySelectorAll('#cyberMenuNav .cyber-nav-item').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      activeMenuPanel = btn.getAttribute('data-panel');
      renderActiveMenuPanel();
    });
  });

  renderActiveMenuPanel();

  // --------------------------------------------------------------------------
  // 8. 3D COLLISION & RAYCAST OCCLUSION ENGINE (Walls & Crates Block Bullets!)
  // --------------------------------------------------------------------------
  function getActiveBlocks() {
    const arena = ARENAS[(match.arenaIndex - 1) % ARENAS.length] || ARENAS[0];
    return arena.blocks;
  }

  function resolvePlayerCollision(nextX, nextZ, playerFootY) {
    const radius = 1.75;
    let x = Math.max(-89, Math.min(89, nextX));
    let z = Math.max(-124, Math.min(124, nextZ));
    let floorHeight = 0;

    const blocks = getActiveBlocks();
    for (let i = 0; i < blocks.length; i++) {
      const b = blocks[i];
      const minX = b.x - b.w * 0.5 - radius;
      const maxX = b.x + b.w * 0.5 + radius;
      const minZ = b.z - b.d * 0.5 - radius;
      const maxZ = b.z + b.d * 0.5 + radius;

      if (x > minX && x < maxX && z > minZ && z < maxZ) {
        const blockTop = b.y + b.h;
        // Allow stepping/jumping on top of crates if player's feet are above or near the top
        if (playerFootY >= blockTop - 1.8) {
          floorHeight = Math.max(floorHeight, blockTop);
        } else {
          // Push out along shallowest axis
          const penLeft = x - minX;
          const penRight = maxX - x;
          const penFront = z - minZ;
          const penBack = maxZ - z;
          const minPen = Math.min(penLeft, penRight, penFront, penBack);
          if (minPen === penLeft) x = minX;
          else if (minPen === penRight) x = maxX;
          else if (minPen === penFront) z = minZ;
          else z = maxZ;
        }
      }
    }
    return { x, z, floorHeight };
  }

  // Slab method 3D Ray-AABB intersection
  function rayIntersectsAABB(ox, oy, oz, dx, dy, dz, box) {
    const minX = box.x - box.w * 0.5;
    const maxX = box.x + box.w * 0.5;
    const minY = box.y;
    const maxY = box.y + box.h;
    const minZ = box.z - box.d * 0.5;
    const maxZ = box.z + box.d * 0.5;

    let tmin = 0.01;
    let tmax = 500;

    const checks = [
      [ox, dx, minX, maxX],
      [oy, dy, minY, maxY],
      [oz, dz, minZ, maxZ],
    ];

    for (let i = 0; i < 3; i++) {
      const [orig, dir, bmin, bmax] = checks[i];
      if (Math.abs(dir) < 1e-6) {
        if (orig < bmin || orig > bmax) return null;
      } else {
        let t1 = (bmin - orig) / dir;
        let t2 = (bmax - orig) / dir;
        if (t1 > t2) { const tmp = t1; t1 = t2; t2 = tmp; }
        tmin = Math.max(tmin, t1);
        tmax = Math.min(tmax, t2);
        if (tmin > tmax) return null;
      }
    }
    return tmin;
  }

  function raycastWorldBlocks(ox, oy, oz, dx, dy, dz) {
    let closestT = Infinity;
    let hitBlock = null;
    const blocks = getActiveBlocks();
    for (let i = 0; i < blocks.length; i++) {
      const t = rayIntersectsAABB(ox, oy, oz, dx, dy, dz, blocks[i]);
      if (t !== null && t < closestT) {
        closestT = t;
        hitBlock = blocks[i];
      }
    }
    let nx = 0, ny = 0, nz = 1;
    if (hitBlock && closestT < Infinity) {
      const hx = ox + dx * closestT;
      const hy = oy + dy * closestT;
      const hz = oz + dz * closestT;
      const eps = 0.12;
      if (Math.abs(hx - (hitBlock.x - hitBlock.w * 0.5)) < eps) { nx = -1; ny = 0; nz = 0; }
      else if (Math.abs(hx - (hitBlock.x + hitBlock.w * 0.5)) < eps) { nx = 1; ny = 0; nz = 0; }
      else if (Math.abs(hy - (hitBlock.y + hitBlock.h)) < eps) { nx = 0; ny = 1; nz = 0; }
      else if (Math.abs(hz - (hitBlock.z - hitBlock.d * 0.5)) < eps) { nx = 0; ny = 0; nz = -1; }
      else { nx = 0; ny = 0; nz = 1; }
    }
    return { distance: closestT, block: hitBlock, nx, ny, nz };
  }

  function spawnFloorBloodPool(x, z, maxRadius, growSpeed, nowMs) {
    if (bloodPools.length > 36) bloodPools.shift();
    bloodPools.push({
      x,
      z,
      radius: Math.min(0.25, maxRadius * 0.3),
      maxRadius,
      growSpeed: growSpeed || 2.2,
      born: nowMs,
      seed: Math.random() * Math.PI * 2,
    });
  }

  function spawnBloodBurst(hx, hy, hz, dirX, dirY, dirZ, isHeadshot, nowMs) {
    // 1. Expanding volumetric blood mist cloud at impact wound
    bloodMists.push({
      x: hx,
      y: hy,
      z: hz,
      radius: isHeadshot ? 0.55 : 0.38,
      maxRadius: isHeadshot ? 1.85 : 1.25,
      born: nowMs,
      life: isHeadshot ? 340 : 250,
    });

    // 2. High-velocity crimson blood droplets & arterial spray
    const count = isHeadshot ? 24 : 14;
    const bloodPalette = ['#590303', '#8a0808', '#b51010', '#d91818', '#420202'];
    for (let s = 0; s < count; s++) {
      const spread = isHeadshot ? 16 : 11;
      debrisSparks.push({
        x: hx + (Math.random() - 0.5) * 0.25,
        y: hy + (Math.random() - 0.5) * 0.25,
        z: hz + (Math.random() - 0.5) * 0.25,
        vx: dirX * (4 + Math.random() * 8) + (Math.random() - 0.5) * spread,
        vy: 2.5 + Math.random() * (isHeadshot ? 10 : 6.5),
        vz: dirZ * (4 + Math.random() * 8) + (Math.random() - 0.5) * spread,
        color: bloodPalette[s % bloodPalette.length],
        size: isHeadshot ? 0.24 : 0.19,
        isBlood: true,
        born: nowMs,
        life: 620 + Math.random() * 260,
      });
    }

    // 3. Immediate blood splatter on the floor beneath the wound
    spawnFloorBloodPool(
      hx + (Math.random() - 0.5) * 1.4,
      hz + (Math.random() - 0.5) * 1.4,
      isHeadshot ? 1.35 : 0.85,
      3.4,
      nowMs
    );
  }

  // --------------------------------------------------------------------------
  // 9. MATCH LIFECYCLE & 120-SECOND (2-MINUTE) MAP ROTATION
  // --------------------------------------------------------------------------
  const hudWeaponSlots = document.getElementById('hudWeaponSlots');
  function renderWeaponSlotBar() {
    hudWeaponSlots.innerHTML = WEAPONS.map((w, idx) => `
      <div class="weapon-slot-pill ${idx === player.weaponIndex ? 'active' : ''}" data-slot="${idx}">
        [${w.slot}]<br/>${w.short}
      </div>
    `).join('');
    hudWeaponSlots.querySelectorAll('[data-slot]').forEach((el) => {
      const idx = parseInt(el.getAttribute('data-slot'), 10);
      el.onclick = () => switchWeapon(idx);
      el.addEventListener(
        'touchstart',
        (e) => {
          e.preventDefault();
          e.stopPropagation();
          switchWeapon(idx);
        },
        { passive: false }
      );
    });
  }

  function resetEnemyState(spawnX, spawnZ, nowMs) {
    enemy.x = spawnX;
    enemy.y = 0;
    enemy.z = spawnZ;
    enemy.yaw = 0;
    // Choose an assault lane (-46 left wing, 0 mid doors, +46 right wing) to push out of spawn zone immediately!
    const lanes = [-46, 0, 46];
    enemy.assaultLane = lanes[Math.floor(Math.random() * lanes.length)];
    enemy.strafeDir = Math.random() > 0.5 ? 1 : -1;
    enemy.targetX = enemy.assaultLane;
    enemy.targetZ = -16;
    enemy.nextMoveChange = nowMs + 900;
    enemy.dead = false;
    enemy.deathTime = 0;
    enemy.fallAngle = 0;
    enemy.fallVelocity = 0;
    enemy.bloodPoolSpawned = false;
    enemy.burstRemaining = 0;
    enemy.nextFireTime = nowMs + 700;
  }

  function startMatch(mode, winCond, startArenaIdx, botFires, opponentName) {
    match.active = true;
    match.ended = false;
    match.mode = mode;
    match.winCondition = winCond || 10;
    match.arenaIndex = startArenaIdx || 1;
    match.arenaTimeRemaining = ARENA_ROTATION_SECONDS; // 120 seconds (2 minutes)
    match.p1Health = 100;
    match.p2Health = 100;
    match.p1Kills = 0;
    match.p2Kills = 0;
    match.botFiresBack = botFires;
    match.p2Name = opponentName || 'T // PHOENIX CONNEXION';

    player.x = 0;
    player.y = 6.2;
    player.z = 94;
    player.vy = 0;
    player.grounded = true;
    player.crouching = false;
    player.yaw = 0;
    player.pitch = 0;
    player.weaponIndex = 0;
    player.isAiming = false;
    player.isReloading = false;
    player.isFiring = false;
    player.hurtAlpha = 0;
    touchState.moveX = 0;
    touchState.moveY = 0;
    touchState.crouchToggle = false;
    touchState.joyTouchId = null;
    touchState.lookTouchId = null;
    touchState.fireTouchId = null;
    const crouchBtn = document.getElementById('btnMobileCrouch');
    if (crouchBtn) crouchBtn.classList.remove('active');
    const scopeBtn = document.getElementById('btnMobileScope');
    if (scopeBtn) scopeBtn.classList.remove('active');
    const joyKnob = document.getElementById('mobileJoystickKnob');
    if (joyKnob) joyKnob.style.transform = 'translate(0px, 0px)';
    resetAllAmmo();

    resetEnemyState(0, -92, performance.now());
    bulletImpacts.length = 0;
    bloodPools.length = 0;
    bloodMists.length = 0;
    debrisSparks.length = 0;

    mainMenuScreen.classList.add('hidden');
    hudScreen.classList.remove('hidden');
    document.getElementById('matchEndOverlay').classList.add('hidden');
    document.getElementById('arenaRotationOverlay').classList.add('hidden');
    document.getElementById('sniperScopeOverlay').classList.add('hidden');
    document.getElementById('hitmarkerOverlay').classList.add('hidden');
    renderWeaponSlotBar();
    updateHUD();

    if (!document.body.classList.contains('touch-enabled') && canvas.requestPointerLock) {
      try {
        canvas.requestPointerLock();
      } catch (_) {}
    }
  }

  function leaveMatchToMenu() {
    match.active = false;
    match.ended = false;
    player.isFiring = false;
    touchState.moveX = 0;
    touchState.moveY = 0;
    if (document.exitPointerLock) {
      try {
        document.exitPointerLock();
      } catch (_) {}
    }
    hudScreen.classList.add('hidden');
    mainMenuScreen.classList.remove('hidden');
    renderActiveMenuPanel();
  }

  document.getElementById('btnLeaveMatch').onclick = leaveMatchToMenu;
  document.getElementById('btnMatchEndReturn').onclick = leaveMatchToMenu;

  const btnMobileFullscreen = document.getElementById('btnMobileFullscreen');
  if (btnMobileFullscreen) {
    btnMobileFullscreen.onclick = () => {
      playSound('ui');
      const docEl = document.documentElement;
      if (!document.fullscreenElement) {
        if (docEl.requestFullscreen) {
          docEl.requestFullscreen().catch(() => {});
        }
        if (screen.orientation && screen.orientation.lock) {
          screen.orientation.lock('landscape').catch(() => {});
        }
      } else if (document.exitFullscreen) {
        document.exitFullscreen().catch(() => {});
      }
    };
  }

  /**
   * MANDATORY 120-SECOND (2-MINUTE) ARENA ROTATION:
   * Switches to the next CS 1.6 map every 120 seconds while preserving BOTH players' exact HP!
   */
  function rotateArenaEvery120Seconds() {
    if (!match.active || match.ended) return;

    const preservedP1HP = match.p1Health;
    const preservedP2HP = match.p2Health;

    match.arenaIndex = (match.arenaIndex % ARENAS.length) + 1;
    match.arenaTimeRemaining = ARENA_ROTATION_SECONDS; // Reset to 120 seconds

    const nextArena = ARENAS[match.arenaIndex - 1];
    playSound('arenaSwitch');

    player.x = 0;
    player.y = 6.2;
    player.z = 94;
    player.yaw = 0;
    resetEnemyState(0, -92, performance.now());
    bulletImpacts.length = 0;
    bloodPools.length = 0;
    bloodMists.length = 0;

    match.p1Health = preservedP1HP;
    match.p2Health = preservedP2HP > 0 ? preservedP2HP : 100;

    const overlay = document.getElementById('arenaRotationOverlay');
    document.getElementById('rotOverlayTitle').textContent = `MAP CHANGING // ${nextArena.name}`;
    document.getElementById('rotOverlaySub').textContent = nextArena.subtitle;
    document.getElementById('rotOverlayHp').textContent =
      `HP PRESERVED — CT (YOU): ${preservedP1HP} HP  |  ${match.p2Name}: ${match.p2Health} HP`;

    overlay.classList.remove('hidden');
    setTimeout(() => {
      overlay.classList.add('hidden');
    }, 2000);

    updateHUD();
  }

  setInterval(() => {
    if (!match.active || match.ended) return;
    match.arenaTimeRemaining = Math.max(0, match.arenaTimeRemaining - 1);
    if (match.arenaTimeRemaining <= 0) {
      rotateArenaEvery120Seconds();
    } else {
      updateHUD();
    }
  }, 1000);

  function formatMMSS(sec) {
    const s = Math.max(0, Math.floor(sec));
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${String(m).padStart(2, '0')}:${String(r).padStart(2, '0')}`;
  }

  function updateHUD() {
    const arena = ARENAS[match.arenaIndex - 1];
    const w = WEAPONS[player.weaponIndex];
    const wAmmo = player.ammo[w.id];

    document.getElementById('hudP1Name').textContent = match.p1Name;
    document.getElementById('hudP2Name').textContent = match.p2Name;
    document.getElementById('hudP1Kills').textContent = match.p1Kills;
    document.getElementById('hudP2Kills').textContent = match.p2Kills;

    document.getElementById('hudP1HpBar').style.width = `${match.p1Health}%`;
    document.getElementById('hudP2HpBar').style.width = `${match.p2Health}%`;
    document.getElementById('hudP1HpText').textContent = `${match.p1Health} / 100 HP`;
    document.getElementById('hudP2HpText').textContent = `${match.p2Health} / 100 HP`;

    document.getElementById('hudLocalHpBig').textContent = match.p1Health;
    document.getElementById('hudLocalHpBar').style.width = `${match.p1Health}%`;

    document.getElementById('hudArenaTimer').textContent = formatMMSS(match.arenaTimeRemaining);
    document.getElementById('hudArenaName').textContent = arena.name;
    document.getElementById('hudWinGoal').textContent = `FIRST TO ${match.winCondition} KILLS`;

    document.getElementById('hudWeaponName').textContent = w.name;
    document.getElementById('hudAmmoMag').textContent = wAmmo.mag;
    document.getElementById('hudAmmoReserve').textContent = `| ${wAmmo.reserve}`;
    document.getElementById('hudReloadStatus').textContent = player.isReloading ? 'RELOADING...' : '[R] RELOAD';
  }

  function pushKillFeed(killer, victim, weaponName, isHeadshot) {
    const list = document.getElementById('killFeedList');
    const div = document.createElement('div');
    div.className = 'kill-feed-item';
    div.textContent = `${killer}  [${weaponName}${isHeadshot ? ' (HEADSHOT)' : ''}]  ${victim}`;
    list.appendChild(div);
    setTimeout(() => div.remove(), 4200);
  }

  function endMatch(playerWon) {
    match.ended = true;
    if (document.exitPointerLock) document.exitPointerLock();

    if (playerWon) {
      profile.wins += 1;
      profile.winStreak += 1;
      profile.coins += 150;
      addXP(200);
    } else {
      profile.losses += 1;
      profile.winStreak = 0;
      profile.coins += 50;
      addXP(75);
    }
    saveProfile();

    const endOverlay = document.getElementById('matchEndOverlay');
    const title = document.getElementById('matchEndTitle');
    const sub = document.getElementById('matchEndSub');
    title.textContent = playerWon ? 'COUNTER-TERRORISTS WIN!' : 'TERRORISTS WIN!';
    title.style.color = playerWon ? '#ffb000' : '#d94838';
    sub.textContent = `FINAL SCORE: YOU (${match.p1Kills}) vs ${match.p2Name} (${match.p2Kills}) // REWARD: +$${playerWon ? 150 : 50}`;
    endOverlay.classList.remove('hidden');
  }

  // --------------------------------------------------------------------------
  // 10. SHOOTING, RELOADING, AIMING & WEAPON SWITCHING
  // --------------------------------------------------------------------------
  function spawnShellCasing(w) {
    const isShotgun = w.id === 'Shotgun';
    const isSniper = w.id === 'SniperRifle';
    const isRifle = w.id === 'AssaultRifle';
    shellCasings.push({
      // Screen-relative offset from 3D forward-aimed weapon receiver ejection port
      x: player.isAiming ? canvas.width * 0.54 : canvas.width * 0.69,
      y: player.isAiming ? canvas.height * 0.66 : canvas.height * 0.70,
      vx: 185 + Math.random() * 115,
      vy: -220 - Math.random() * 95,
      angle: Math.random() * Math.PI,
      vAngle: (Math.random() > 0.5 ? 1 : -1) * (14 + Math.random() * 12),
      length: isShotgun ? 22 : isSniper ? 24 : isRifle ? 19 : 13,
      thickness: isShotgun ? 8 : isSniper ? 6.5 : isRifle ? 5.5 : 5,
      isShotgunHull: isShotgun,
      born: performance.now(),
      pinged: false,
    });
  }

  function spawnMuzzleSmoke(x, y, count = 2) {
    const nowMs = performance.now();
    for (let i = 0; i < count; i++) {
      muzzleSmoke.push({
        x: x + (Math.random() - 0.5) * 14,
        y: y + (Math.random() - 0.5) * 10,
        vx: (Math.random() - 0.35) * 28,
        vy: -42 - Math.random() * 38,
        radius: 10 + Math.random() * 10,
        growRate: 28 + Math.random() * 18,
        alpha: 0.36 + Math.random() * 0.14,
        born: nowMs,
        life: 620 + Math.random() * 320,
      });
    }
  }

  function switchWeapon(newIndex) {
    if (!match.active || match.ended) return;
    const clamped = ((newIndex % WEAPONS.length) + WEAPONS.length) % WEAPONS.length;
    if (clamped === player.weaponIndex) return;
    player.weaponIndex = clamped;
    player.isReloading = false;
    player.reloadStageAudio = 0;
    player.isAiming = false;
    document.getElementById('sniperScopeOverlay').classList.add('hidden');
    playSound('reload_bolt');
    renderWeaponSlotBar();
    updateHUD();
  }

  function reloadWeapon() {
    if (!match.active || match.ended || player.isReloading) return;
    const w = WEAPONS[player.weaponIndex];
    const ammo = player.ammo[w.id];
    if (ammo.mag >= w.magSize || ammo.reserve <= 0) return;

    player.isReloading = true;
    player.isAiming = false;
    document.getElementById('sniperScopeOverlay').classList.add('hidden');
    player.reloadStartTime = performance.now();
    player.reloadDuration = w.reloadTime * 1000;
    player.reloadStageAudio = 0;
    playSound('reload_magout');
    updateHUD();

    const reloadingWeaponId = w.id;
    setTimeout(() => {
      if (!player.isReloading || WEAPONS[player.weaponIndex].id !== reloadingWeaponId) return;
      const needed = w.magSize - ammo.mag;
      const take = Math.min(needed, ammo.reserve);
      ammo.mag += take;
      ammo.reserve -= take;
      player.isReloading = false;
      player.reloadStageAudio = 0;
      updateHUD();
    }, w.reloadTime * 1000);
  }

  function attemptShoot() {
    if (!match.active || match.ended || player.isReloading) return;
    const w = WEAPONS[player.weaponIndex];
    const ammo = player.ammo[w.id];
    const nowMs = performance.now();
    const now = nowMs / 1000;
    if (now - player.lastShotClock < w.fireRate) return;

    if (ammo.mag <= 0) {
      reloadWeapon();
      return;
    }

    ammo.mag -= 1;
    player.lastShotClock = now;
    player.lastShotMs = nowMs;

    // --- AUTHENTIC CS 1.6 RECOIL (ADACHA / OTDACHA) — Recovers to horizontal level! ---
    const stanceMult = (player.crouching ? 0.68 : 1.0) * (player.isAiming ? 0.72 : 1.0);
    player.recoilSprayShots = Math.min(15, player.recoilSprayShots + 1);
    player.recoilKick = Math.min(1.4, player.recoilKick + w.recoilKick * 1.15);
    player.recoilMuzzleFlip = Math.min(0.08, player.recoilMuzzleFlip + w.recoilKick * 0.055);
    player.recoilRoll = (Math.random() - 0.5) * 0.04;

    // Camera temporary recoil kick (automatically recovers to 0 when you stop shooting!)
    const verticalKick = (0.012 + w.recoilKick * 0.032 + player.recoilSprayShots * 0.0018) * stanceMult;
    const horizPattern = player.recoilSprayShots > 3
      ? Math.sin(player.recoilSprayShots * 0.95) * (0.007 + w.recoilKick * 0.012)
      : (Math.random() - 0.5) * 0.005;
    const horizKick = horizPattern * stanceMult;

    player.recoilPitchAccum = Math.min(0.18, player.recoilPitchAccum + verticalKick);
    player.recoilYawAccum += horizKick;
    player.screenShakeX = (Math.random() - 0.5) * w.recoilKick * 12;
    player.screenShakeY = w.recoilKick * 10;

    player.muzzleFlashUntil = nowMs + 68;
    player.muzzleFlashAngle = Math.random() * Math.PI * 2;
    playSound('shoot', w.soundPitch);
    updateHUD();

    // Eject spinning brass casing (immediate for semi/auto; delayed bolt/pump cycle for AWP/M3)
    if (w.id === 'SniperRifle' || w.id === 'Shotgun') {
      player.boltCycleStart = nowMs + 160;
      setTimeout(() => {
        if (match.active && !match.ended) {
          playSound('reload_bolt');
          spawnShellCasing(w);
        }
      }, 220);
    } else {
      spawnShellCasing(w);
    }

    // Spawn rising gunsmoke from forward-aimed barrel muzzle tip
    const flashX = player.isAiming ? canvas.width * 0.5 : canvas.width * 0.57;
    const flashY = player.isAiming ? canvas.height * 0.54 : canvas.height * 0.58;
    spawnMuzzleSmoke(flashX, flashY, w.id === 'Shotgun' ? 4 : 2);

    if (ammo.mag <= 0 && ammo.reserve > 0) {
      setTimeout(reloadWeapon, 220);
    }

    let totalDamage = 0;
    let anyHeadshot = false;

    // 3D world-space muzzle origin (slightly right & below eye camera)
    const rightVecX = Math.cos(player.yaw);
    const rightVecZ = Math.sin(player.yaw);
    const fwdVecX = Math.sin(player.yaw);
    const fwdVecZ = -Math.cos(player.yaw);
    const muzzleWorldX = player.x + rightVecX * (player.isAiming ? 0.05 : 0.45) + fwdVecX * 1.1;
    const muzzleWorldY = player.y - 0.38;
    const muzzleWorldZ = player.z + rightVecZ * (player.isAiming ? 0.05 : 0.45) + fwdVecZ * 1.1;

    for (let p = 0; p < w.pellets; p++) {
      // Progressive CS 1.6 recoil spread penalty + upward bullet climb during continuous spray
      const sprayPenaltyDeg = Math.max(0, player.recoilSprayShots - 1) * (w.recoilKick * 2.4);
      const spreadDeg = ((player.isAiming ? w.adsSpread : w.hipSpread) + sprayPenaltyDeg) * (player.crouching ? 0.65 : 1.0);
      const spreadRad = (spreadDeg * Math.PI) / 180;
      const sprayClimbRad = Math.max(0, player.recoilSprayShots - 1) * w.recoilKick * 0.012 * stanceMult;
      const rayYaw = player.yaw + player.recoilYawAccum + (Math.random() - 0.5) * spreadRad;
      const rayPitch = player.pitch + player.recoilPitchAccum + sprayClimbRad + (Math.random() - 0.5) * spreadRad;

      // World-space unit ray vector
      const cosP = Math.cos(rayPitch);
      const sinP = Math.sin(rayPitch);
      const dirX = Math.sin(rayYaw) * cosP;
      const dirY = sinP;
      const dirZ = -Math.cos(rayYaw) * cosP;

      // 1. Check distance to closest solid 3D wall or crate
      const worldHit = raycastWorldBlocks(player.x, player.y, player.z, dirX, dirY, dirZ);

      // 2. Check ray intersection with Enemy Soldier Head & Body AABBs (only when standing/alive)
      const headBox = { x: enemy.x, y: enemy.y + 5.45, z: enemy.z, w: 1.8, h: 1.75, d: 1.8 };
      const bodyBox = { x: enemy.x, y: enemy.y + 0.0, z: enemy.z, w: 2.65, h: 5.45, d: 2.15 };

      const canHitEnemy = match.p2Health > 0 && !enemy.dead;
      const tHead = canHitEnemy ? rayIntersectsAABB(player.x, player.y, player.z, dirX, dirY, dirZ, headBox) : null;
      const tBody = canHitEnemy ? rayIntersectsAABB(player.x, player.y, player.z, dirX, dirY, dirZ, bodyBox) : null;

      let hitDist = Math.min(worldHit.distance, 260);

      if (tHead !== null && tHead < worldHit.distance) {
        anyHeadshot = true;
        hitDist = tHead;
        totalDamage += Math.round(w.baseDamage * w.headMultiplier);
        const hx = player.x + dirX * tHead;
        const hy = player.y + dirY * tHead;
        const hz = player.z + dirZ * tHead;
        enemy.hitFlinchUntil = nowMs + 160;
        spawnBloodBurst(hx, hy, hz, dirX, dirY, dirZ, true, nowMs);
      } else if (tBody !== null && tBody < worldHit.distance) {
        hitDist = tBody;
        totalDamage += w.baseDamage;
        const bx = player.x + dirX * tBody;
        const by = player.y + dirY * tBody;
        const bz = player.z + dirZ * tBody;
        enemy.hitFlinchUntil = nowMs + 120;
        spawnBloodBurst(bx, by, bz, dirX, dirY, dirZ, false, nowMs);
      } else if (worldHit.distance < 450) {
        // Bullet hit a solid wall or wooden crate — spawn surface-aligned 3D bullet hole & flying chips
        hitDist = worldHit.distance - 0.05;
        const wx = player.x + dirX * hitDist;
        const wy = player.y + dirY * hitDist;
        const wz = player.z + dirZ * hitDist;
        const isCrateHit = worldHit.block && worldHit.block.type === 'crate';
        if (bulletImpacts.length > 48) bulletImpacts.shift();
        bulletImpacts.push({
          x: wx,
          y: wy,
          z: wz,
          nx: worldHit.nx,
          ny: worldHit.ny,
          nz: worldHit.nz,
          color: '#171512',
          ringColor: isCrateHit ? '#9c6e3b' : '#b2a68e',
          born: nowMs,
        });
        for (let s = 0; s < 5; s++) {
          debrisSparks.push({
            x: wx, y: wy, z: wz,
            vx: -dirX * 5 + (Math.random() - 0.5) * 11,
            vy: 2 + Math.random() * 8,
            vz: -dirZ * 5 + (Math.random() - 0.5) * 11,
            color: isCrateHit ? '#b88648' : s === 0 ? '#ffd466' : '#c9bfa8',
            size: 0.17,
            isBlood: false,
            born: nowMs,
            life: 360,
          });
        }
      }

      tracers.push({
        startX: muzzleWorldX,
        startY: muzzleWorldY,
        startZ: muzzleWorldZ,
        endX: player.x + dirX * hitDist,
        endY: player.y + dirY * hitDist,
        endZ: player.z + dirZ * hitDist,
        isEnemy: false,
        born: nowMs,
      });
    }

    if (totalDamage > 0 && match.p2Health > 0 && !enemy.dead) {
      match.p2Health = Math.max(0, match.p2Health - totalDamage);
      playSound(anyHeadshot ? 'headshot' : 'hit');
      showHitmarker(anyHeadshot, totalDamage);

      if (match.p2Health <= 0) {
        // Trigger 3D Death Fall-to-Ground Ragdoll Animation!
        enemy.dead = true;
        enemy.deathTime = nowMs;
        enemy.fallAngle = 0.04;
        enemy.fallVelocity = anyHeadshot ? 3.6 : 2.2;
        const pushX = enemy.x - player.x;
        const pushZ = enemy.z - player.z;
        const pushLen = Math.hypot(pushX, pushZ) || 1;
        enemy.fallDirX = (pushX / pushLen) + (Math.random() - 0.5) * 0.35;
        enemy.fallDirZ = (pushZ / pushLen);
        const fNorm = Math.hypot(enemy.fallDirX, enemy.fallDirZ) || 1;
        enemy.fallDirX /= fNorm;
        enemy.fallDirZ /= fNorm;
        enemy.fallSideRoll = (Math.random() - 0.5) * 0.4;
        enemy.bloodPoolSpawned = false;
        enemy.burstRemaining = 0;

        match.p1Kills += 1;
        profile.kills += 1;
        profile.coins += 25;
        addXP(40);
        pushKillFeed('CT // YOU', match.p2Name, w.short, anyHeadshot);

        if (match.p1Kills >= match.winCondition) {
          updateHUD();
          setTimeout(() => {
            if (match.active) endMatch(true);
          }, 1200);
          return;
        }

        setTimeout(() => {
          if (match.active && !match.ended) {
            match.p2Health = 100;
            const spawns = [
              [-44, -94],
              [44, -94],
              [-22, -88],
              [22, -88],
              [0, -96],
            ];
            const sp = spawns[Math.floor(Math.random() * spawns.length)];
            resetEnemyState(sp[0], sp[1], performance.now());
            updateHUD();
          }
        }, 2200);
      }
      updateHUD();
    }
  }

  function showHitmarker(isHeadshot, dmg) {
    const hm = document.getElementById('hitmarkerOverlay');
    const pop = document.getElementById('headshotPopText');
    const col = isHeadshot ? '#ff3b30' : '#ffb000';
    ['hmLine1', 'hmLine2', 'hmLine3', 'hmLine4'].forEach((id) => {
      document.getElementById(id).setAttribute('stroke', col);
    });
    hm.classList.remove('hidden');
    pop.textContent = isHeadshot ? `HEADSHOT! -${dmg} HP` : `-${dmg} HP`;
    pop.style.color = col;

    setTimeout(() => hm.classList.add('hidden'), 150);
    setTimeout(() => { pop.textContent = ''; }, 550);
  }

  // --------------------------------------------------------------------------
  // 11. INPUT LISTENERS
  // --------------------------------------------------------------------------
  window.addEventListener('keydown', (e) => {
    keys[e.code] = true;
    if (!match.active) return;

    if (e.code === 'KeyR') reloadWeapon();
    else if (e.code === 'Digit1') switchWeapon(0);
    else if (e.code === 'Digit2') switchWeapon(1);
    else if (e.code === 'Digit3') switchWeapon(2);
    else if (e.code === 'Digit4') switchWeapon(3);
    else if (e.code === 'Digit5') switchWeapon(4);
    else if (e.code === 'KeyM') leaveMatchToMenu();
    else if (e.code === 'Space' && player.grounded) {
      player.vy = 21.5;
      player.grounded = false;
    }
  });

  window.addEventListener('keyup', (e) => {
    keys[e.code] = false;
  });

  canvas.addEventListener('mousedown', (e) => {
    if (!match.active || match.ended) return;
    if (document.pointerLockElement !== canvas && canvas.requestPointerLock) {
      canvas.requestPointerLock();
    }
    if (e.button === 0) {
      player.isFiring = true;
      attemptShoot();
    } else if (e.button === 2) {
      player.isAiming = !player.isAiming;
      const w = WEAPONS[player.weaponIndex];
      if (w.useScope && player.isAiming) {
        document.getElementById('sniperScopeOverlay').classList.remove('hidden');
      } else {
        document.getElementById('sniperScopeOverlay').classList.add('hidden');
      }
    }
  });

  window.addEventListener('mouseup', (e) => {
    if (e.button === 0) player.isFiring = false;
  });

  window.addEventListener('contextmenu', (e) => e.preventDefault());

  window.addEventListener('mousemove', (e) => {
    if (!match.active || match.ended || document.pointerLockElement !== canvas) return;
    const sens = (profile.settings.sensitivity || 0.5) * (player.isAiming ? 0.0012 : 0.0026);
    player.yaw += e.movementX * sens;
    player.pitch = Math.max(-0.62, Math.min(0.62, player.pitch - e.movementY * sens));
  });

  window.addEventListener('wheel', (e) => {
    if (!match.active || match.ended) return;
    switchWeapon(player.weaponIndex + (e.deltaY > 0 ? 1 : -1));
  });

  // --------------------------------------------------------------------------
  // 11B. MOBILE MULTI-TOUCH FPS CONTROLS (JOYSTICK, 360° AIM PAD & TRIGGERS)
  // --------------------------------------------------------------------------
  window.addEventListener(
    'touchstart',
    () => {
      document.body.classList.add('touch-enabled');
      ensureAudio();
    },
    { passive: true }
  );

  const joyZone = document.getElementById('mobileJoystickZone');
  const joyBase = document.getElementById('mobileJoystickBase');
  const joyKnob = document.getElementById('mobileJoystickKnob');
  const lookZone = document.getElementById('mobileLookZone');
  const btnMobileFire = document.getElementById('btnMobileFire');
  const btnMobileFireLeft = document.getElementById('btnMobileFireLeft');
  const btnMobileScope = document.getElementById('btnMobileScope');
  const btnMobileReload = document.getElementById('btnMobileReload');
  const btnMobileJump = document.getElementById('btnMobileJump');
  const btnMobileCrouch = document.getElementById('btnMobileCrouch');

  function updateJoystickFromTouch(clientX, clientY) {
    const dx = clientX - touchState.joyOriginX;
    const dy = clientY - touchState.joyOriginY;
    const maxR = 42;
    const dist = Math.hypot(dx, dy);
    const clampedDist = Math.min(maxR, dist);
    const angle = Math.atan2(dy, dx);
    const kx = Math.cos(angle) * clampedDist;
    const ky = Math.sin(angle) * clampedDist;

    touchState.moveX = kx / maxR;
    touchState.moveY = ky / maxR;
    if (joyKnob) {
      joyKnob.style.transform = `translate(${kx.toFixed(1)}px, ${ky.toFixed(1)}px)`;
    }
  }

  function resetJoystick() {
    touchState.joyTouchId = null;
    touchState.moveX = 0;
    touchState.moveY = 0;
    if (joyKnob) {
      joyKnob.style.transform = 'translate(0px, 0px)';
    }
  }

  if (joyZone) {
    joyZone.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        ensureAudio();
        const t = e.changedTouches[0];
        if (!t) return;
        touchState.joyTouchId = t.identifier;
        if (joyBase) {
          const rect = joyBase.getBoundingClientRect();
          touchState.joyOriginX = rect.left + rect.width * 0.5;
          touchState.joyOriginY = rect.top + rect.height * 0.5;
        } else {
          touchState.joyOriginX = t.clientX;
          touchState.joyOriginY = t.clientY;
        }
        updateJoystickFromTouch(t.clientX, t.clientY);
      },
      { passive: false }
    );

    joyZone.addEventListener(
      'touchmove',
      (e) => {
        if (touchState.joyTouchId === null) return;
        e.preventDefault();
        for (let i = 0; i < e.changedTouches.length; i++) {
          const t = e.changedTouches[i];
          if (t.identifier === touchState.joyTouchId) {
            updateJoystickFromTouch(t.clientX, t.clientY);
            break;
          }
        }
      },
      { passive: false }
    );

    const endJoy = (e) => {
      if (touchState.joyTouchId === null) return;
      for (let i = 0; i < e.changedTouches.length; i++) {
        if (e.changedTouches[i].identifier === touchState.joyTouchId) {
          resetJoystick();
          break;
        }
      }
    };
    joyZone.addEventListener('touchend', endJoy, { passive: false });
    joyZone.addEventListener('touchcancel', endJoy, { passive: false });
  }

  function applyTouchLookDelta(dx, dy) {
    const sens = (profile.settings.sensitivity || 0.5) * (player.isAiming ? 0.0042 : 0.0086);
    player.yaw += dx * sens;
    player.pitch = Math.max(-0.62, Math.min(0.62, player.pitch - dy * sens));
  }

  if (lookZone) {
    lookZone.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        ensureAudio();
        const t = e.changedTouches[0];
        if (!t) return;
        touchState.lookTouchId = t.identifier;
        touchState.lookLastX = t.clientX;
        touchState.lookLastY = t.clientY;
      },
      { passive: false }
    );

    lookZone.addEventListener(
      'touchmove',
      (e) => {
        if (touchState.lookTouchId === null || !match.active || match.ended) return;
        e.preventDefault();
        for (let i = 0; i < e.changedTouches.length; i++) {
          const t = e.changedTouches[i];
          if (t.identifier === touchState.lookTouchId) {
            const dx = t.clientX - touchState.lookLastX;
            const dy = t.clientY - touchState.lookLastY;
            touchState.lookLastX = t.clientX;
            touchState.lookLastY = t.clientY;
            applyTouchLookDelta(dx, dy);
            break;
          }
        }
      },
      { passive: false }
    );

    const endLook = (e) => {
      if (touchState.lookTouchId === null) return;
      for (let i = 0; i < e.changedTouches.length; i++) {
        if (e.changedTouches[i].identifier === touchState.lookTouchId) {
          touchState.lookTouchId = null;
          break;
        }
      }
    };
    lookZone.addEventListener('touchend', endLook, { passive: false });
    lookZone.addEventListener('touchcancel', endLook, { passive: false });
  }

  // Right Fire Button (Hold to Spray + Drag Thumb to Aim Simultaneously!)
  if (btnMobileFire) {
    btnMobileFire.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        e.stopPropagation();
        ensureAudio();
        btnMobileFire.classList.add('active');
        const t = e.changedTouches[0];
        if (t) {
          touchState.fireTouchId = t.identifier;
          touchState.fireLastX = t.clientX;
          touchState.fireLastY = t.clientY;
        }
        player.isFiring = true;
        attemptShoot();
      },
      { passive: false }
    );

    btnMobileFire.addEventListener(
      'touchmove',
      (e) => {
        if (touchState.fireTouchId === null || !match.active || match.ended) return;
        e.preventDefault();
        for (let i = 0; i < e.changedTouches.length; i++) {
          const t = e.changedTouches[i];
          if (t.identifier === touchState.fireTouchId) {
            const dx = t.clientX - touchState.fireLastX;
            const dy = t.clientY - touchState.fireLastY;
            touchState.fireLastX = t.clientX;
            touchState.fireLastY = t.clientY;
            applyTouchLookDelta(dx, dy);
            break;
          }
        }
      },
      { passive: false }
    );

    const endFireRight = (e) => {
      e.preventDefault();
      btnMobileFire.classList.remove('active');
      touchState.fireTouchId = null;
      player.isFiring = false;
    };
    btnMobileFire.addEventListener('touchend', endFireRight, { passive: false });
    btnMobileFire.addEventListener('touchcancel', endFireRight, { passive: false });
  }

  // Left Fire Button (Claw / Secondary Trigger)
  if (btnMobileFireLeft) {
    btnMobileFireLeft.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        e.stopPropagation();
        ensureAudio();
        btnMobileFireLeft.classList.add('active');
        player.isFiring = true;
        attemptShoot();
      },
      { passive: false }
    );
    const endFireLeft = (e) => {
      e.preventDefault();
      btnMobileFireLeft.classList.remove('active');
      player.isFiring = false;
    };
    btnMobileFireLeft.addEventListener('touchend', endFireLeft, { passive: false });
    btnMobileFireLeft.addEventListener('touchcancel', endFireLeft, { passive: false });
  }

  if (btnMobileScope) {
    btnMobileScope.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        e.stopPropagation();
        ensureAudio();
        player.isAiming = !player.isAiming;
        btnMobileScope.classList.toggle('active', player.isAiming);
        const w = WEAPONS[player.weaponIndex];
        if (w.useScope && player.isAiming) {
          document.getElementById('sniperScopeOverlay').classList.remove('hidden');
        } else {
          document.getElementById('sniperScopeOverlay').classList.add('hidden');
        }
      },
      { passive: false }
    );
  }

  if (btnMobileReload) {
    btnMobileReload.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        e.stopPropagation();
        ensureAudio();
        reloadWeapon();
      },
      { passive: false }
    );
  }

  if (btnMobileJump) {
    btnMobileJump.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        e.stopPropagation();
        ensureAudio();
        if (player.grounded) {
          player.vy = 21.5;
          player.grounded = false;
        }
      },
      { passive: false }
    );
  }

  if (btnMobileCrouch) {
    btnMobileCrouch.addEventListener(
      'touchstart',
      (e) => {
        if (!match.active || match.ended) return;
        e.preventDefault();
        e.stopPropagation();
        ensureAudio();
        touchState.crouchToggle = !touchState.crouchToggle;
        btnMobileCrouch.classList.toggle('active', touchState.crouchToggle);
      },
      { passive: false }
    );
  }

  // --------------------------------------------------------------------------
  // 12. TRUE 3D SHADED POLYGON & CS 1.6 BOX RENDERER
  // --------------------------------------------------------------------------
  function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }
  window.addEventListener('resize', resizeCanvas);
  resizeCanvas();

  function worldToCam(wx, wy, wz, camX, camY, camZ, cosY, sinY, cosP, sinP) {
    const dx = wx - camX;
    const dy = wy - camY;
    const dz = wz - camZ;

    const rx = dx * cosY + dz * sinY;
    const fz = dx * sinY - dz * cosY;

    const ry = dy * cosP - fz * sinP;
    const rz = fz * cosP + dy * sinP;
    return { x: rx, y: ry, z: rz };
  }

  // Clips a 3D polygon against the near camera plane (z >= NEAR) and projects to 2D
  function clipAndProjectPolygon(verts3D, camX, camY, camZ, cosY, sinY, cosP, sinP, focal) {
    const NEAR = 0.35;
    const camVerts = verts3D.map((v) => worldToCam(v[0], v[1], v[2], camX, camY, camZ, cosY, sinY, cosP, sinP));

    const clipped = [];
    for (let i = 0; i < camVerts.length; i++) {
      const curr = camVerts[i];
      const prev = camVerts[(i + camVerts.length - 1) % camVerts.length];
      const currInside = curr.z >= NEAR;
      const prevInside = prev.z >= NEAR;

      if (currInside !== prevInside) {
        const t = (NEAR - prev.z) / (curr.z - prev.z);
        clipped.push({
          x: prev.x + (curr.x - prev.x) * t,
          y: prev.y + (curr.y - prev.y) * t,
          z: NEAR,
        });
      }
      if (currInside) {
        clipped.push(curr);
      }
    }

    if (clipped.length < 3) return null;

    const halfW = canvas.width * 0.5;
    const halfH = canvas.height * 0.5;
    return clipped.map((c) => ({
      x: halfW + (c.x / c.z) * focal,
      y: halfH - (c.y / c.z) * focal,
    }));
  }

  function shadeHexColor(hex, factor, fogRGB = null, fogAmount = 0) {
    const clean = hex.replace('#', '');
    const num = parseInt(clean, 16);
    let r = Math.min(255, Math.max(0, Math.round(((num >> 16) & 255) * factor)));
    let g = Math.min(255, Math.max(0, Math.round(((num >> 8) & 255) * factor)));
    let b = Math.min(255, Math.max(0, Math.round((num & 255) * factor)));
    if (fogRGB && fogAmount > 0.01) {
      const f = Math.min(0.72, fogAmount);
      r = Math.round(r * (1 - f) + fogRGB[0] * f);
      g = Math.round(g * (1 - f) + fogRGB[1] * f);
      b = Math.round(b * (1 - f) + fogRGB[2] * f);
    }
    return `rgb(${r},${g},${b})`;
  }

  function buildBoxFaces(b, camX, camY, camZ, faceList, fogRGB) {
    const x0 = b.x - b.w * 0.5;
    const x1 = b.x + b.w * 0.5;
    const y0 = b.y;
    const y1 = b.y + b.h;
    const z0 = b.z - b.d * 0.5;
    const z1 = b.z + b.d * 0.5;

    const isCrate = b.type === 'crate';
    const isWall = b.type === 'wall';
    const strokeCol = isCrate ? '#2e1e0f' : 'rgba(24, 22, 18, 0.45)';

    // Front face (+Z)
    if (camZ > z1) {
      const dist = Math.hypot(b.x - camX, (y0 + y1) * 0.5 - camY, z1 - camZ);
      const fog = Math.max(0, (dist - 55) / 260);
      faceList.push({
        verts: [[x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]],
        fill: shadeHexColor(b.color, 0.98, fogRGB, fog),
        trimColor: shadeHexColor(b.color, 0.72, fogRGB, fog),
        stroke: strokeCol,
        isCrate,
        isWall,
        dist,
      });
    }
    // Back face (-Z)
    if (camZ < z0) {
      const dist = Math.hypot(b.x - camX, (y0 + y1) * 0.5 - camY, z0 - camZ);
      const fog = Math.max(0, (dist - 55) / 260);
      faceList.push({
        verts: [[x1, y0, z0], [x0, y0, z0], [x0, y1, z0], [x1, y1, z0]],
        fill: shadeHexColor(b.color, 0.80, fogRGB, fog),
        trimColor: shadeHexColor(b.color, 0.60, fogRGB, fog),
        stroke: strokeCol,
        isCrate,
        isWall,
        dist,
      });
    }
    // Left face (-X)
    if (camX < x0) {
      const dist = Math.hypot(x0 - camX, (y0 + y1) * 0.5 - camY, b.z - camZ);
      const fog = Math.max(0, (dist - 55) / 260);
      faceList.push({
        verts: [[x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0]],
        fill: shadeHexColor(b.color, 0.72, fogRGB, fog),
        trimColor: shadeHexColor(b.color, 0.54, fogRGB, fog),
        stroke: strokeCol,
        isCrate,
        isWall,
        dist,
      });
    }
    // Right face (+X)
    if (camX > x1) {
      const dist = Math.hypot(x1 - camX, (y0 + y1) * 0.5 - camY, b.z - camZ);
      const fog = Math.max(0, (dist - 55) / 260);
      faceList.push({
        verts: [[x1, y0, z1], [x1, y0, z0], [x1, y1, z0], [x1, y1, z1]],
        fill: shadeHexColor(b.color, 0.88, fogRGB, fog),
        trimColor: shadeHexColor(b.color, 0.65, fogRGB, fog),
        stroke: strokeCol,
        isCrate,
        isWall,
        dist,
      });
    }
    // Top face (+Y)
    if (camY > y1) {
      const dist = Math.hypot(b.x - camX, y1 - camY, b.z - camZ);
      const fog = Math.max(0, (dist - 55) / 260);
      faceList.push({
        verts: [[x0, y1, z1], [x1, y1, z1], [x1, y1, z0], [x0, y1, z0]],
        fill: shadeHexColor(b.color, 1.14, fogRGB, fog),
        trimColor: shadeHexColor(b.color, 0.88, fogRGB, fog),
        stroke: strokeCol,
        isCrate,
        isWall: false,
        dist,
      });
    }
  }

  /**
   * Builds a 3D oriented limb/part for the Enemy Soldier in local character space,
   * rotating by enemy.yaw AND tilting down to the ground by enemy.fallAngle when killed!
   */
  function addEnemyCharacterPart(
    faceList,
    camX,
    camY,
    camZ,
    fogRGB,
    lx,
    ly,
    lz,
    bw,
    bh,
    bd,
    hexCol,
    localPitch = 0,
    localRoll = 0,
    pivotY = null
  ) {
    const x0 = -bw * 0.5, x1 = bw * 0.5;
    const y0 = -bh * 0.5, y1 = bh * 0.5;
    const z0 = -bd * 0.5, z1 = bd * 0.5;

    const cp = Math.cos(localPitch), sp = Math.sin(localPitch);
    const cr = Math.cos(localRoll), sr = Math.sin(localRoll);
    const cy = Math.cos(enemy.yaw), sy = Math.sin(enemy.yaw);

    // Fall rotation matrix (pivots around feet y=0.22 along enemy.fallDirX, enemy.fallDirZ)
    const fallA = enemy.fallAngle;
    const cf = Math.cos(fallA), sf = Math.sin(fallA);
    // Axis of rotation is perpendicular to fallDir in XZ plane: (axisX, 0, axisZ)
    const axisX = -enemy.fallDirZ;
    const axisZ = enemy.fallDirX;

    function transformVert(vx, vy, vz) {
      // 1. Local roll & pitch around limb pivot
      let py = vy + (pivotY !== null ? bh * 0.5 - pivotY : 0);
      const rx = vx * cr - py * sr;
      const ry0 = vx * sr + py * cr;
      const ry = ry0 * cp - vz * sp - (pivotY !== null ? bh * 0.5 - pivotY : 0);
      const rz = ry0 * sp + vz * cp;

      let cx = lx + rx;
      let cyPos = ly + ry;
      let cz = lz + rz;

      // 2. Rotate character by enemy.yaw around Y axis
      let wx = cx * cy + cz * sy;
      let wy = cyPos;
      let wz = -cx * sy + cz * cy;

      // 3. Apply 3D Death Fall-to-Ground rotation around feet (0, 0.22, 0)
      if (fallA > 0.001) {
        const relY = wy - 0.22;
        // Rodrigues' rotation around horizontal unit vector (axisX, 0, axisZ)
        const dot = wx * axisX + wz * axisZ;
        const crossX = -axisZ * relY;
        const crossY = axisZ * wx - axisX * wz;
        const crossZ = axisX * relY;

        wx = wx * cf + crossX * sf + axisX * dot * (1 - cf);
        wy = 0.22 + relY * cf + crossY * sf;
        wz = wz * cf + crossZ * sf + axisZ * dot * (1 - cf);
      }

      // Clamp above floor so fallen corpse rests cleanly on the ground plane
      return [
        enemy.x + wx,
        Math.max(0.08, enemy.y + wy),
        enemy.z + wz,
      ];
    }

    const v000 = transformVert(x0, y0, z0);
    const v100 = transformVert(x1, y0, z0);
    const v010 = transformVert(x0, y1, z0);
    const v110 = transformVert(x1, y1, z0);
    const v001 = transformVert(x0, y0, z1);
    const v101 = transformVert(x1, y0, z1);
    const v011 = transformVert(x0, y1, z1);
    const v111 = transformVert(x1, y1, z1);

    const boxFaces = [
      { verts: [v001, v101, v111, v011], shade: 1.02 }, // Front (+Z)
      { verts: [v100, v000, v010, v110], shade: 0.76 }, // Back (-Z)
      { verts: [v000, v001, v011, v010], shade: 0.84 }, // Left (-X)
      { verts: [v101, v100, v110, v111], shade: 0.88 }, // Right (+X)
      { verts: [v011, v111, v110, v010], shade: 1.15 }, // Top (+Y)
      { verts: [v000, v100, v101, v001], shade: 0.58 }, // Bottom (-Y)
    ];

    for (let i = 0; i < boxFaces.length; i++) {
      const fv = boxFaces[i].verts;
      const fcx = (fv[0][0] + fv[1][0] + fv[2][0] + fv[3][0]) * 0.25;
      const fcy = (fv[0][1] + fv[1][1] + fv[2][1] + fv[3][1]) * 0.25;
      const fcz = (fv[0][2] + fv[1][2] + fv[2][2] + fv[3][2]) * 0.25;
      const dist = Math.hypot(fcx - camX, fcy - camY, fcz - camZ);
      const fog = Math.max(0, (dist - 65) / 260);
      faceList.push({
        verts: fv,
        fill: shadeHexColor(hexCol, boxFaces[i].shade, fogRGB, fog),
        stroke: 'rgba(15, 17, 15, 0.65)',
        isCrate: false,
        isWall: false,
        dist,
      });
    }
  }

  function buildEnemySoldierModel(camX, camY, camZ, faceList, fogRGB, nowMs) {
    const stride = enemy.dead
      ? 0.25
      : enemy.isMoving
      ? Math.sin(enemy.walkCycle) * 0.48
      : 0;
    const flinchPitch = nowMs < enemy.hitFlinchUntil ? -0.18 : 0;
    const fallProgress = Math.min(1, enemy.fallAngle / (Math.PI * 0.48));
    const deadArmSplay = fallProgress * 0.65;

    // 1. Left & Right Combat Boots (Dark Reinforced Leather)
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, -0.58, 0.32, Math.sin(stride) * 0.45, 0.72, 0.64, 1.05, '#181a1c', stride * 0.5, 0);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.58, 0.32, -Math.sin(stride) * 0.45, 0.72, 0.64, 1.05, '#181a1c', -stride * 0.5, 0);

    // 2. Left & Right Shins + Molded Tactical Knee Pads
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, -0.58, 1.25, Math.sin(stride) * 0.32, 0.76, 1.35, 0.82, '#3d4739', stride * 0.65, 0);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.58, 1.25, -Math.sin(stride) * 0.32, 0.76, 1.35, 0.82, '#3d4739', -stride * 0.65, 0);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, -0.58, 1.65, 0.44 + Math.sin(stride) * 0.3, 0.62, 0.42, 0.22, '#1c1f22', stride * 0.5, 0);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.58, 1.65, 0.44 - Math.sin(stride) * 0.3, 0.62, 0.42, 0.22, '#1c1f22', -stride * 0.5, 0);

    // 3. Left & Right Thighs + Pelvis + Tactical Utility Belt & Drop-Leg Holster
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, -0.58, 2.45, Math.sin(stride) * 0.16, 0.86, 1.30, 0.94, '#465242', stride * 0.4, -fallProgress * 0.12);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.58, 2.45, -Math.sin(stride) * 0.16, 0.86, 1.30, 0.94, '#465242', -stride * 0.4, fallProgress * 0.12);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 1.06, 2.48, 0.0, 0.22, 0.68, 0.52, '#1b1d1f', 0, 0); // Thigh pistol holster
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 3.05, 0.0, 2.05, 0.42, 1.18, '#1d201d', 0, 0);   // Heavy web belt

    // 4. Muscular Torso, Ballistic Kevlar Plate Carrier & 3 Front AK Magazine Pouches
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 4.25, 0.0, 2.18, 2.15, 1.24, '#5e4c3a', flinchPitch, 0);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 4.30, 0.04, 2.02, 1.75, 1.36, '#262b25', flinchPitch, 0); // Kevlar vest
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, -0.52, 3.92, 0.74, 0.42, 0.62, 0.26, '#383f34', flinchPitch, 0); // Left mag pouch
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 3.92, 0.74, 0.42, 0.62, 0.26, '#383f34', flinchPitch, 0);   // Center mag pouch
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.52, 3.92, 0.74, 0.42, 0.62, 0.26, '#383f34', flinchPitch, 0);  // Right mag pouch

    // 5. Strictly 2 Articulated Arms (Right Trigger Arm + Left Forend Support Arm)
    // Right Arm (Shoulder -> Forearm -> Gloved Hand on Grip)
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 1.36, 4.65, 0.28, 0.66, 1.15, 0.78, '#5e4c3a', -0.45 + deadArmSplay, -deadArmSplay);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 1.02, 4.18, 0.96, 0.56, 0.58, 1.05, '#786248', -0.15, 0);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.48, 4.12, 1.32, 0.48, 0.48, 0.54, '#1b1d1b', 0, 0);

    // Left Arm (Shoulder -> Extended Forearm -> Gloved Hand gripping AK-47 Handguard)
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, -1.36, 4.65, 0.35, 0.66, 1.15, 0.78, '#5e4c3a', -0.55 - deadArmSplay, deadArmSplay);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, -0.62, 4.15, 1.35, 0.88, 0.54, 1.10, '#786248', 0, 0.35);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.24, 4.12, 2.15, 0.50, 0.48, 0.56, '#1b1d1b', 0, 0);

    // 6. Enemy 3D AK-47 Assault Rifle (Drops beside body when dead!)
    const gunDropY = fallProgress * -1.4;
    const gunDropX = fallProgress * 1.1;
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.36 + gunDropX, 4.22 + gunDropY, 0.82, 0.30, 0.44, 0.95, '#7a4924', 0, fallProgress * 1.1); // Wood stock
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.36 + gunDropX, 4.28 + gunDropY, 1.65, 0.34, 0.46, 1.25, '#222528', 0, fallProgress * 1.1); // Steel receiver
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.36 + gunDropX, 3.78 + gunDropY, 1.75, 0.26, 0.68, 0.38, '#29231e', 0.35, fallProgress * 1.1); // Banana mag
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.36 + gunDropX, 4.28 + gunDropY, 2.52, 0.32, 0.38, 0.95, '#8c5327', 0, fallProgress * 1.1); // Wood handguard
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.36 + gunDropX, 4.34 + gunDropY, 3.38, 0.16, 0.18, 1.15, '#151719', 0, fallProgress * 1.1); // Rifle barrel

    // 7. Neck, Balaclava Head, Ballistic Goggles & Kevlar Helmet
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 5.42, 0.0, 0.78, 0.42, 0.78, '#252729', flinchPitch, 0);
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 6.12, 0.0, 1.32, 1.36, 1.34, '#242628', flinchPitch * 1.4, 0);
    // Tactical Crimson/Amber Ballistic Goggles
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 6.18, 0.68, 1.16, 0.36, 0.18, '#c93824', flinchPitch * 1.4, 0);
    // Molded Kevlar Helmet Dome & Visor Brim
    addEnemyCharacterPart(faceList, camX, camY, camZ, fogRGB, 0.0, 6.62, -0.02, 1.48, 0.66, 1.52, '#343c30', flinchPitch * 1.4, 0);
  }

  // --------------------------------------------------------------------------
  // 13. MAIN 60 FPS GAME & 3D RENDER LOOP
  // --------------------------------------------------------------------------
  let lastFrameTime = performance.now();

  function renderFrame(nowMs) {
    const dt = Math.min(0.05, (nowMs - lastFrameTime) / 1000);
    lastFrameTime = nowMs;

    const w = canvas.width;
    const h = canvas.height;
    const activeArena = match.active ? ARENAS[match.arenaIndex - 1] : ARENAS[0];
    const fogRGB = activeArena.fogColor || [195, 182, 156];

    // ------------------------------------------------------------------------
    // A. UPDATE PLAYER PHYSICS, COLLISION & ENEMY TACTICAL AI
    // ------------------------------------------------------------------------
    if (match.active && !match.ended) {
      const wep = WEAPONS[player.weaponIndex];
      if (player.isFiring && wep.fireMode === 'Auto') {
        attemptShoot();
      }

      // Smooth CS 1.6 Recoil (Adacha) & Damage Vignette Recovery
      player.recoilKick *= Math.pow(0.14, dt);
      player.recoilMuzzleFlip *= Math.pow(0.08, dt);
      player.recoilPitchAccum *= Math.pow(0.06, dt);
      player.recoilYawAccum *= Math.pow(0.05, dt);
      player.screenShakeX *= Math.pow(0.005, dt);
      player.screenShakeY *= Math.pow(0.005, dt);
      player.hurtAlpha = Math.max(0, player.hurtAlpha - dt * 1.6);
      if (!player.isFiring && nowMs - player.lastShotMs > 160) {
        player.recoilSprayShots = Math.max(0, player.recoilSprayShots - dt * 18);
      }

      player.crouching = !!(keys['ControlLeft'] || keys['KeyC'] || touchState.crouchToggle);
      const joyMag = Math.hypot(touchState.moveX, touchState.moveY);
      const isSprinting = keys['ShiftLeft'] || joyMag > 0.82;
      const moveSpeed = (player.crouching ? 15 : isSprinting ? 31 : 24) * dt;
      const forwardX = Math.sin(player.yaw);
      const forwardZ = -Math.cos(player.yaw);
      const rightX = Math.cos(player.yaw);
      const rightZ = Math.sin(player.yaw);

      let nextX = player.x;
      let nextZ = player.z;
      if (keys['KeyW']) { nextX += forwardX * moveSpeed; nextZ += forwardZ * moveSpeed; }
      if (keys['KeyS']) { nextX -= forwardX * moveSpeed; nextZ -= forwardZ * moveSpeed; }
      if (keys['KeyD']) { nextX += rightX * moveSpeed; nextZ += rightZ * moveSpeed; }
      if (keys['KeyA']) { nextX -= rightX * moveSpeed; nextZ -= rightZ * moveSpeed; }
      if (joyMag > 0.08) {
        nextX += (forwardX * (-touchState.moveY) + rightX * touchState.moveX) * moveSpeed;
        nextZ += (forwardZ * (-touchState.moveY) + rightZ * touchState.moveX) * moveSpeed;
      }

      const eyeOffset = player.crouching ? 3.8 : 6.2;
      const footY = player.y - eyeOffset;
      const col = resolvePlayerCollision(nextX, nextZ, footY);
      player.x = col.x;
      player.z = col.z;

      // Vertical Jump & Gravity onto Crates
      player.vy -= 52 * dt;
      let nextFootY = footY + player.vy * dt;
      if (nextFootY <= col.floorHeight) {
        nextFootY = col.floorHeight;
        player.vy = 0;
        player.grounded = true;
      } else {
        player.grounded = false;
      }
      player.y = nextFootY + eyeOffset;

      // Update Dynamic CS 1.6 Green Crosshair Gap (Expands with Recoil & Spray!)
      const chGap = Math.round(
        4 +
        (player.recoilKick * 28) +
        (player.recoilSprayShots * 2.4) +
        (player.isAiming ? 0 : 3) +
        (player.crouching ? -1 : 0)
      );
      document.getElementById('chTop').style.top = `${-(chGap + 8)}px`;
      document.getElementById('chBottom').style.top = `${chGap}px`;
      document.getElementById('chLeft').style.left = `${-(chGap + 8)}px`;
      document.getElementById('chRight').style.left = `${chGap}px`;

      // Update Enemy Death Fall Physics OR Active Tactical AI Combat
      if (enemy.dead) {
        // Accelerate falling body toward ground under gravity until lying flat (Math.PI * 0.485)
        const maxFall = Math.PI * 0.485;
        if (enemy.fallAngle < maxFall) {
          enemy.fallVelocity += 11.5 * dt;
          enemy.fallAngle = Math.min(maxFall, enemy.fallAngle + enemy.fallVelocity * dt);
          if (enemy.fallAngle >= maxFall && !enemy.bloodPoolSpawned) {
            enemy.bloodPoolSpawned = true;
            playSound('hit', 85);
            // Spawn large crimson blood pool beneath fallen torso & head!
            const corpseTorsoX = enemy.x + enemy.fallDirX * 4.2;
            const corpseTorsoZ = enemy.z + enemy.fallDirZ * 4.2;
            spawnFloorBloodPool(corpseTorsoX, corpseTorsoZ, 2.75, 1.8, nowMs);
            spawnFloorBloodPool(enemy.x + enemy.fallDirX * 5.8, enemy.z + enemy.fallDirZ * 5.8, 1.9, 2.2, nowMs);
          }
        }
      } else if (match.p2Health > 0) {
        // 1. Check 3D Line-of-Sight to Player & Smoothly Rotate Enemy Yaw
        const toPlrX = player.x - enemy.x;
        const toPlrZ = player.z - enemy.z;
        const dist2D = Math.hypot(toPlrX, toPlrZ) || 1;
        const eyeToPlrX = player.x - enemy.x;
        const eyeToPlrY = (player.y - 0.6) - (enemy.y + 5.8);
        const eyeToPlrZ = player.z - enemy.z;
        const distToPlr = Math.hypot(eyeToPlrX, eyeToPlrY, eyeToPlrZ) || 1;
        const losHit = raycastWorldBlocks(
          enemy.x,
          enemy.y + 5.8,
          enemy.z,
          eyeToPlrX / distToPlr,
          eyeToPlrY / distToPlr,
          eyeToPlrZ / distToPlr
        );
        const hasLineOfSight = losHit.distance > distToPlr;

        // Face player when in sight or close; otherwise face movement direction while sprinting
        const moveDx = enemy.targetX - enemy.x;
        const moveDz = enemy.targetZ - enemy.z;
        const desiredYaw = (hasLineOfSight || dist2D < 55)
          ? Math.atan2(toPlrX, toPlrZ)
          : Math.atan2(moveDx, moveDz);
        let yawDiff = desiredYaw - enemy.yaw;
        while (yawDiff > Math.PI) yawDiff -= Math.PI * 2;
        while (yawDiff < -Math.PI) yawDiff += Math.PI * 2;
        enemy.yaw += yawDiff * Math.min(1, dt * 9.5);

        // 2. Aggressive Tactical Assault AI — Leaves Spawn Zone & Hunts Player!
        if (nowMs >= enemy.nextMoveChange) {
          enemy.nextMoveChange = nowMs + 750 + Math.random() * 650;
          if (Math.random() < 0.45) enemy.strafeDir = -enemy.strafeDir;

          // If enemy is still in his spawn half (z < -8) and player is across mid (z > -4),
          // push aggressively through one of the open mid lanes (-46, 0, +46) into player's zone!
          if (enemy.z < -8 && player.z > -4) {
            const openLanes = [-46, 0, 46];
            if (enemy.assaultLane === undefined) {
              enemy.assaultLane = openLanes[Math.floor(Math.random() * openLanes.length)];
            }
            if (enemy.z < -22) {
              // Step 1: Rush out of spawn zone to the lane entrance
              enemy.targetX = enemy.assaultLane + (Math.random() - 0.5) * 6;
              enemy.targetZ = -12;
            } else {
              // Step 2: Cross the center line (z = 0) into the player's half!
              enemy.targetX = enemy.assaultLane + (Math.random() - 0.5) * 8;
              enemy.targetZ = 22;
            }
          } else {
            // Enemy is out of his zone -> Actively hunt, flank, and attack the player!
            const perpX = -toPlrZ / dist2D;
            const perpZ = toPlrX / dist2D;
            if (!hasLineOfSight) {
              // Push toward player with lateral flank offset to peek around cover crates/walls
              enemy.targetX = Math.max(-82, Math.min(82, player.x + perpX * enemy.strafeDir * 18));
              enemy.targetZ = Math.max(-115, Math.min(115, player.z - (toPlrZ / dist2D) * 12));
            } else if (dist2D > 30) {
              // Charge forward toward player while weaving left/right
              enemy.targetX = Math.max(-82, Math.min(82, enemy.x + (toPlrX / dist2D) * 26 + perpX * enemy.strafeDir * 14));
              enemy.targetZ = Math.max(-115, Math.min(115, enemy.z + (toPlrZ / dist2D) * 26 + perpZ * enemy.strafeDir * 14));
            } else {
              // Close-quarters combat strafing around the player (maintain 16-24 unit duel distance)
              const pushPull = dist2D < 15 ? -10 : 6;
              enemy.targetX = Math.max(-82, Math.min(82, enemy.x + perpX * enemy.strafeDir * 18 + (toPlrX / dist2D) * pushPull));
              enemy.targetZ = Math.max(-115, Math.min(115, enemy.z + perpZ * enemy.strafeDir * 18 + (toPlrZ / dist2D) * pushPull));
            }
          }
        }

        // Execute movement with smart obstacle avoidance so enemy never gets stuck on crates/walls
        const edx = enemy.targetX - enemy.x;
        const edz = enemy.targetZ - enemy.z;
        const edist = Math.hypot(edx, edz);
        if (edist > 0.8) {
          enemy.isMoving = true;
          enemy.walkCycle += dt * 9.2;
          const moveSpd = hasLineOfSight && dist2D < 35 ? 20.5 : 24.0;
          const step = Math.min(edist, moveSpd * dt);
          const dirX = edx / edist;
          const dirZ = edz / edist;
          const prevX = enemy.x;
          const prevZ = enemy.z;

          const eCol = resolvePlayerCollision(
            enemy.x + dirX * step,
            enemy.z + dirZ * step,
            0
          );
          enemy.x = eCol.x;
          enemy.z = eCol.z;

          // If blocked by a crate or wall, steer perpendicular around the obstacle immediately!
          const actualMoved = Math.hypot(enemy.x - prevX, enemy.z - prevZ);
          if (actualMoved < step * 0.45) {
            const sideCol = resolvePlayerCollision(
              prevX + (-dirZ * enemy.strafeDir) * step * 1.15,
              prevZ + (dirX * enemy.strafeDir) * step * 1.15,
              0
            );
            enemy.x = sideCol.x;
            enemy.z = sideCol.z;
            // Pick a clear lane if blocked near mid
            const openLanes = [-46, 0, 46];
            enemy.assaultLane = openLanes[Math.floor(Math.random() * openLanes.length)];
            enemy.targetX = enemy.assaultLane;
            enemy.nextMoveChange = nowMs + 350;
          }
        } else {
          enemy.isMoving = false;
          enemy.nextMoveChange = nowMs; // Immediately pick next assault target when reached!
        }

        // 3. Realistic Aggressive AK-47 Burst Shooting with 3D Tracers
        if (match.botFiresBack) {
          if (hasLineOfSight && enemy.burstRemaining <= 0 && nowMs >= enemy.nextFireTime) {
            enemy.burstRemaining = 3 + Math.floor(Math.random() * 3); // 3-5 round aggressive burst
            enemy.nextBurstShotMs = nowMs;
            enemy.nextFireTime = nowMs + 950 + Math.random() * 450;
          }

          if (enemy.burstRemaining > 0 && nowMs >= enemy.nextBurstShotMs) {
            enemy.burstRemaining -= 1;
            enemy.nextBurstShotMs = nowMs + 125;

            if (hasLineOfSight) {
              enemy.muzzleFlashUntil = nowMs + 65;
              playSound('shoot', 142);

              // Calculate 3D world-space muzzle tip of Enemy's AK-47
              const eSinY = Math.sin(enemy.yaw);
              const eCosY = Math.cos(enemy.yaw);
              const eMuzzleX = enemy.x + 0.36 * eCosY + 3.45 * eSinY;
              const eMuzzleY = enemy.y + 4.34;
              const eMuzzleZ = enemy.z - 0.36 * eSinY + 3.45 * eCosY;

              // Add realistic rifle spread to enemy burst shot
              const spreadX = (Math.random() - 0.5) * 2.8;
              const spreadY = (Math.random() - 0.5) * 2.2;
              const spreadZ = (Math.random() - 0.5) * 2.8;
              const shotEndX = player.x + spreadX;
              const shotEndY = player.y - 0.5 + spreadY;
              const shotEndZ = player.z + spreadZ;

              tracers.push({
                startX: eMuzzleX,
                startY: eMuzzleY,
                startZ: eMuzzleZ,
                endX: shotEndX,
                endY: shotEndY,
                endZ: shotEndZ,
                isEnemy: true,
                born: nowMs,
              });

              // Check if this round in the burst hit the player
              const hitAccuracy = Math.hypot(spreadX, spreadY, spreadZ);
              if (hitAccuracy < 2.25) {
                const dmg = 6 + Math.floor(Math.random() * 4);
                match.p1Health = Math.max(0, match.p1Health - dmg);
                player.hurtAlpha = Math.min(0.85, player.hurtAlpha + 0.48);
                player.screenShakeX = (Math.random() - 0.5) * 7;
                player.screenShakeY = 5;
                playSound('hit', 190);

                if (match.p1Health <= 0) {
                  match.p2Kills += 1;
                  profile.deaths += 1;
                  pushKillFeed(match.p2Name, 'CT // YOU', 'AK-47', false);
                  if (match.p2Kills >= match.winCondition) {
                    updateHUD();
                    endMatch(false);
                  } else {
                    match.p1Health = 100;
                    player.x = (Math.random() > 0.5 ? 1 : -1) * 24;
                    player.y = 6.2;
                    player.z = 94;
                  }
                }
                updateHUD();
              }
            } else {
              enemy.burstRemaining = 0;
            }
          }
        }
      }
    }

    // ------------------------------------------------------------------------
    // B. CAMERA SETUP & REALISTIC ATMOSPHERIC SKY / GROUND RENDERING
    // ------------------------------------------------------------------------
    const camX = match.active ? player.x : Math.sin(nowMs * 0.00035) * 14;
    const camY = match.active ? player.y : 10.5;
    const camZ = match.active ? player.z : 88;
    const camYaw = match.active ? player.yaw + player.recoilYawAccum : Math.sin(nowMs * 0.00025) * 0.18;
    const camPitch = match.active
      ? Math.max(-0.62, Math.min(0.62, player.pitch + player.recoilPitchAccum + player.recoilKick * 0.065))
      : -0.04;
    const currentWeapon = WEAPONS[player.weaponIndex];
    const fovDeg = match.active && player.isAiming ? currentWeapon.adsFov : (profile.settings.fov || 78);
    const focal = (h * 0.5) / Math.tan((fovDeg * Math.PI) / 360);

    const cosY = Math.cos(camYaw);
    const sinY = Math.sin(camYaw);
    const cosP = Math.cos(camPitch);
    const sinP = Math.sin(camPitch);

    const horizonY = h * 0.5 + Math.tan(camPitch) * focal;

    // 1. Multi-Stop Atmospheric Sky Gradient + Volumetric Sun Glow
    const skyGrad = ctx.createLinearGradient(0, 0, 0, Math.max(10, horizonY));
    skyGrad.addColorStop(0, activeArena.skyTop);
    skyGrad.addColorStop(0.55, activeArena.skyMid || activeArena.skyTop);
    skyGrad.addColorStop(1, activeArena.skyBottom);
    ctx.fillStyle = skyGrad;
    ctx.fillRect(0, 0, w, Math.max(0, horizonY + 2));

    // Sun Disc & Corona in 3D Skybox
    const sunCam = worldToCam(-140, 125, -240, 0, 0, 0, cosY, sinY, cosP, sinP);
    if (sunCam.z > 0.1) {
      const sunX = w * 0.5 + (sunCam.x / sunCam.z) * focal;
      const sunY = h * 0.5 - (sunCam.y / sunCam.z) * focal;
      if (sunY < horizonY + 90) {
        const sunGrad = ctx.createRadialGradient(sunX, sunY, 4, sunX, sunY, 150);
        sunGrad.addColorStop(0, 'rgba(255, 252, 230, 0.92)');
        sunGrad.addColorStop(0.2, 'rgba(255, 228, 170, 0.42)');
        sunGrad.addColorStop(1, 'rgba(255, 210, 140, 0)');
        ctx.fillStyle = sunGrad;
        ctx.beginPath();
        ctx.arc(sunX, sunY, 150, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    // 2. Ground Plane with Realistic Depth Shading
    const groundGrad = ctx.createLinearGradient(0, Math.max(0, horizonY), 0, h);
    groundGrad.addColorStop(0, shadeHexColor(activeArena.floorColor, 0.78, fogRGB, 0.45));
    groundGrad.addColorStop(0.22, activeArena.floorColor);
    groundGrad.addColorStop(0.75, shadeHexColor(activeArena.floorColor, 0.88));
    groundGrad.addColorStop(1, shadeHexColor(activeArena.floorColor, 0.68));
    ctx.fillStyle = groundGrad;
    ctx.fillRect(0, Math.max(0, horizonY), w, h - Math.max(0, horizonY));

    // 3. 3D Perspective Ground Tile Grid Lines (Expanded 190x260 Arena)
    ctx.strokeStyle = activeArena.floorGridColor;
    ctx.lineWidth = 1;
    for (let gx = -90; gx <= 90; gx += 15) {
      const poly = clipAndProjectPolygon([[gx, 0, -130], [gx, 0, 130], [gx + 0.05, 0, 130]], camX, camY, camZ, cosY, sinY, cosP, sinP, focal);
      if (poly && poly.length >= 2) {
        ctx.beginPath();
        ctx.moveTo(poly[0].x, poly[0].y);
        ctx.lineTo(poly[1].x, poly[1].y);
        ctx.stroke();
      }
    }
    for (let gz = -120; gz <= 120; gz += 15) {
      const poly = clipAndProjectPolygon([[-95, 0, gz], [95, 0, gz], [95, 0, gz + 0.05]], camX, camY, camZ, cosY, sinY, cosP, sinP, focal);
      if (poly && poly.length >= 2) {
        ctx.beginPath();
        ctx.moveTo(poly[0].x, poly[0].y);
        ctx.lineTo(poly[1].x, poly[1].y);
        ctx.stroke();
      }
    }

    // 4. 3D Ground Ambient-Occlusion & Directional Drop Shadows under Crates, Walls & Enemy
    const blocks = activeArena.blocks;
    ctx.fillStyle = 'rgba(14, 12, 10, 0.30)';
    for (let i = 0; i < blocks.length; i++) {
      const b = blocks[i];
      if (b.y > 0.1) continue;
      const sx0 = b.x - b.w * 0.5 - 0.4;
      const sx1 = b.x + b.w * 0.5 + 1.65;
      const sz0 = b.z - b.d * 0.5 - 0.4;
      const sz1 = b.z + b.d * 0.5 + 1.45;
      const shPoly = clipAndProjectPolygon(
        [[sx0, 0.02, sz1], [sx1, 0.02, sz1], [sx1, 0.02, sz0], [sx0, 0.02, sz0]],
        camX, camY, camZ, cosY, sinY, cosP, sinP, focal
      );
      if (shPoly) {
        ctx.beginPath();
        ctx.moveTo(shPoly[0].x, shPoly[0].y);
        for (let j = 1; j < shPoly.length; j++) ctx.lineTo(shPoly[j].x, shPoly[j].y);
        ctx.closePath();
        ctx.fill();
      }
    }

    // Enemy Ground Drop Shadow
    if (match.active) {
      const esx = enemy.x + (enemy.dead ? enemy.fallDirX * 2.8 : 0);
      const esz = enemy.z + (enemy.dead ? enemy.fallDirZ * 2.8 : 0);
      const radX = enemy.dead ? 2.4 : 1.35;
      const radZ = enemy.dead ? 2.8 : 1.35;
      const eShadow = clipAndProjectPolygon(
        [
          [esx - radX, 0.025, esz + radZ],
          [esx + radX, 0.025, esz + radZ],
          [esx + radX, 0.025, esz - radZ],
          [esx - radX, 0.025, esz - radZ],
        ],
        camX, camY, camZ, cosY, sinY, cosP, sinP, focal
      );
      if (eShadow) {
        ctx.fillStyle = 'rgba(10, 10, 10, 0.42)';
        ctx.beginPath();
        ctx.moveTo(eShadow[0].x, eShadow[0].y);
        for (let j = 1; j < eShadow.length; j++) ctx.lineTo(eShadow[j].x, eShadow[j].y);
        ctx.closePath();
        ctx.fill();
      }
    }

    // 5. Render 3D Floor Blood Pools & Splatters (Expanding Crimson Pools on Ground!)
    for (let i = bloodPools.length - 1; i >= 0; i--) {
      const bp = bloodPools[i];
      const age = nowMs - bp.born;
      if (age > 22000) {
        bloodPools.splice(i, 1);
        continue;
      }
      if (bp.radius < bp.maxRadius) {
        bp.radius = Math.min(bp.maxRadius, bp.radius + bp.growSpeed * dt);
      }
      const sides = 8;
      const outerVerts = [];
      const innerVerts = [];
      for (let s = 0; s < sides; s++) {
        const ang = (s / sides) * Math.PI * 2;
        const wobble = 0.84 + 0.22 * Math.sin(ang * 3 + bp.seed);
        const r = bp.radius * wobble;
        outerVerts.push([bp.x + Math.cos(ang) * r, 0.03, bp.z + Math.sin(ang) * r]);
        innerVerts.push([bp.x + Math.cos(ang) * r * 0.62, 0.035, bp.z + Math.sin(ang) * r * 0.62]);
      }
      const fade = age > 18000 ? Math.max(0, 1 - (age - 18000) / 4000) : 1;
      const polyOut = clipAndProjectPolygon(outerVerts, camX, camY, camZ, cosY, sinY, cosP, sinP, focal);
      if (polyOut) {
        ctx.save();
        ctx.globalAlpha = 0.86 * fade;
        ctx.fillStyle = '#7a0707';
        ctx.beginPath();
        ctx.moveTo(polyOut[0].x, polyOut[0].y);
        for (let j = 1; j < polyOut.length; j++) ctx.lineTo(polyOut[j].x, polyOut[j].y);
        ctx.closePath();
        ctx.fill();

        const polyIn = clipAndProjectPolygon(innerVerts, camX, camY, camZ, cosY, sinY, cosP, sinP, focal);
        if (polyIn) {
          ctx.fillStyle = '#4a0303';
          ctx.beginPath();
          ctx.moveTo(polyIn[0].x, polyIn[0].y);
          for (let j = 1; j < polyIn.length; j++) ctx.lineTo(polyIn[j].x, polyIn[j].y);
          ctx.closePath();
          ctx.fill();
        }
        ctx.restore();
      }
    }

    // ------------------------------------------------------------------------
    // C. COLLECT & SORT ALL 3D WORLD FACES (Walls, Crates & Articulated Enemy)
    // ------------------------------------------------------------------------
    const faceList = [];
    for (let i = 0; i < blocks.length; i++) {
      buildBoxFaces(blocks[i], camX, camY, camZ, faceList, fogRGB);
    }

    // Build Realistic 3D Enemy Soldier (Standing, Walking, Shooting, or Falling Dead!)
    if (match.active && (match.p2Health > 0 || enemy.dead)) {
      buildEnemySoldierModel(camX, camY, camZ, faceList, fogRGB, nowMs);
    }

    // Sort 3D faces back-to-front (Painter's Algorithm)
    faceList.sort((a, b) => b.dist - a.dist);

    // Draw all 3D polygons with Architectural & Crate Surface Detailing
    for (let i = 0; i < faceList.length; i++) {
      const f = faceList[i];
      const pts = clipAndProjectPolygon(f.verts, camX, camY, camZ, cosY, sinY, cosP, sinP, focal);
      if (!pts) continue;

      ctx.beginPath();
      ctx.moveTo(pts[0].x, pts[0].y);
      for (let j = 1; j < pts.length; j++) {
        ctx.lineTo(pts[j].x, pts[j].y);
      }
      ctx.closePath();
      ctx.fillStyle = f.fill;
      ctx.fill();
      ctx.strokeStyle = f.stroke;
      ctx.lineWidth = f.isCrate ? 1.4 : 0.9;
      ctx.stroke();

      // Realistic Wooden Crate Detailing: Recessed Frame & Cross-Plank Braces
      if (f.isCrate && pts.length === 4) {
        ctx.beginPath();
        ctx.moveTo(pts[0].x, pts[0].y);
        ctx.lineTo(pts[2].x, pts[2].y);
        ctx.moveTo(pts[1].x, pts[1].y);
        ctx.lineTo(pts[3].x, pts[3].y);
        ctx.strokeStyle = 'rgba(42, 26, 12, 0.45)';
        ctx.lineWidth = 1.8;
        ctx.stroke();
      } else if (f.isWall && pts.length === 4 && f.trimColor) {
        // Subtle architectural lower concrete baseboard line on walls
        const bx0 = pts[0].x + (pts[3].x - pts[0].x) * 0.12;
        const by0 = pts[0].y + (pts[3].y - pts[0].y) * 0.12;
        const bx1 = pts[1].x + (pts[2].x - pts[1].x) * 0.12;
        const by1 = pts[1].y + (pts[2].y - pts[1].y) * 0.12;
        ctx.beginPath();
        ctx.moveTo(bx0, by0);
        ctx.lineTo(bx1, by1);
        ctx.strokeStyle = f.trimColor;
        ctx.lineWidth = 1.2;
        ctx.stroke();
      }
    }

    // Render Enemy Overhead Name & Health Bar if alive
    if (match.active && match.p2Health > 0 && !enemy.dead) {
      const headCam = worldToCam(enemy.x, enemy.y + 7.6, enemy.z, camX, camY, camZ, cosY, sinY, cosP, sinP);
      if (headCam.z > 1) {
        const sx = w * 0.5 + (headCam.x / headCam.z) * focal;
        const sy = h * 0.5 - (headCam.y / headCam.z) * focal;
        const barW = Math.max(46, Math.min(92, (3.4 / headCam.z) * focal));
        ctx.fillStyle = 'rgba(12, 14, 12, 0.85)';
        ctx.fillRect(sx - barW * 0.5, sy - 8, barW, 6);
        ctx.fillStyle = '#d98238';
        ctx.fillRect(sx - barW * 0.5, sy - 8, barW * (match.p2Health / 100), 6);
      }
    }

    // Render Enemy 3D Muzzle Flash when Terrorist Bot Fires
    if (match.active && match.p2Health > 0 && !enemy.dead && nowMs < enemy.muzzleFlashUntil) {
      const eSinY = Math.sin(enemy.yaw);
      const eCosY = Math.cos(enemy.yaw);
      const mxWorld = enemy.x + 0.36 * eCosY + 3.45 * eSinY;
      const myWorld = enemy.y + 4.34;
      const mzWorld = enemy.z - 0.36 * eSinY + 3.45 * eCosY;
      const mCam = worldToCam(mxWorld, myWorld, mzWorld, camX, camY, camZ, cosY, sinY, cosP, sinP);
      if (mCam.z > 0.5) {
        const mx = w * 0.5 + (mCam.x / mCam.z) * focal;
        const my = h * 0.5 - (mCam.y / mCam.z) * focal;
        const mRad = Math.max(9, (1.6 / mCam.z) * focal);
        const eGrad = ctx.createRadialGradient(mx, my, 1, mx, my, mRad);
        eGrad.addColorStop(0, '#fffbe0');
        eGrad.addColorStop(0.45, '#ff9824');
        eGrad.addColorStop(1, 'transparent');
        ctx.fillStyle = eGrad;
        ctx.beginPath();
        ctx.arc(mx, my, mRad, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    // Render 3D Surface-Aligned Bullet Holes strictly on Static Walls & Crates (No Floating Dots!)
    for (let i = bulletImpacts.length - 1; i >= 0; i--) {
      const imp = bulletImpacts[i];
      const age = nowMs - imp.born;
      if (age > 6000) {
        bulletImpacts.splice(i, 1);
        continue;
      }
      const c = worldToCam(imp.x, imp.y, imp.z, camX, camY, camZ, cosY, sinY, cosP, sinP);
      if (c.z > 0.5) {
        const ix = w * 0.5 + (c.x / c.z) * focal;
        const iy = h * 0.5 - (c.y / c.z) * focal;
        const rad = Math.max(1.8, Math.min(7, (0.20 / c.z) * focal));
        if (imp.ringColor) {
          ctx.fillStyle = imp.ringColor;
          ctx.beginPath();
          ctx.arc(ix, iy, rad * 1.45, 0, Math.PI * 2);
          ctx.fill();
        }
        ctx.fillStyle = imp.color;
        ctx.beginPath();
        ctx.arc(ix, iy, rad, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    // Render 3D Blood Mist Clouds at Wound Impact Points
    for (let i = bloodMists.length - 1; i >= 0; i--) {
      const bm = bloodMists[i];
      const age = nowMs - bm.born;
      if (age >= bm.life) {
        bloodMists.splice(i, 1);
        continue;
      }
      const prog = age / bm.life;
      const curR = bm.radius + (bm.maxRadius - bm.radius) * prog;
      const c = worldToCam(bm.x, bm.y, bm.z, camX, camY, camZ, cosY, sinY, cosP, sinP);
      if (c.z > 0.4) {
        const sx = w * 0.5 + (c.x / c.z) * focal;
        const sy = h * 0.5 - (c.y / c.z) * focal;
        const sr = Math.max(6, (curR / c.z) * focal);
        ctx.save();
        ctx.globalAlpha = (1 - prog) * 0.78;
        const bGrad = ctx.createRadialGradient(sx, sy, 1, sx, sy, sr);
        bGrad.addColorStop(0, 'rgba(185, 12, 12, 0.95)');
        bGrad.addColorStop(0.55, 'rgba(120, 6, 6, 0.55)');
        bGrad.addColorStop(1, 'rgba(70, 0, 0, 0)');
        ctx.fillStyle = bGrad;
        ctx.beginPath();
        ctx.arc(sx, sy, sr, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      }
    }

    // Render 3D Flying Blood Droplets, Wood Crate Splinters & Stone Sparks
    for (let i = debrisSparks.length - 1; i >= 0; i--) {
      const sp = debrisSparks[i];
      const age = nowMs - sp.born;
      if (age > sp.life) {
        debrisSparks.splice(i, 1);
        continue;
      }
      sp.x += sp.vx * dt;
      sp.y += sp.vy * dt;
      sp.z += sp.vz * dt;
      sp.vy -= 28 * dt;

      // If a falling blood droplet hits the floor, leave a crimson blood stain on the floor!
      if (sp.isBlood && sp.y <= 0.06) {
        if (Math.random() < 0.35) {
          spawnFloorBloodPool(sp.x, sp.z, 0.42 + Math.random() * 0.35, 3.0, nowMs);
        }
        debrisSparks.splice(i, 1);
        continue;
      }

      const c = worldToCam(sp.x, sp.y, sp.z, camX, camY, camZ, cosY, sinY, cosP, sinP);
      if (c.z > 0.4) {
        const sx = w * 0.5 + (c.x / c.z) * focal;
        const sy = h * 0.5 - (c.y / c.z) * focal;
        const sz = Math.max(2.2, ((sp.size || 0.19) / c.z) * focal);
        ctx.globalAlpha = Math.max(0, 1 - age / sp.life);
        ctx.fillStyle = sp.color;
        if (sp.isBlood) {
          ctx.beginPath();
          ctx.arc(sx, sy, sz * 0.65, 0, Math.PI * 2);
          ctx.fill();
        } else {
          ctx.fillRect(sx - sz * 0.5, sy - sz * 0.5, sz, sz);
        }
        ctx.globalAlpha = 1.0;
      }
    }

    // Render 3D Supersonic Bullet Tracer Streaks (Player & Enemy)
    for (let i = tracers.length - 1; i >= 0; i--) {
      const tr = tracers[i];
      const age = nowMs - tr.born;
      if (age > 95) {
        tracers.splice(i, 1);
        continue;
      }
      const p0 = worldToCam(tr.startX, tr.startY, tr.startZ, camX, camY, camZ, cosY, sinY, cosP, sinP);
      const p1 = worldToCam(tr.endX, tr.endY, tr.endZ, camX, camY, camZ, cosY, sinY, cosP, sinP);
      if (p0.z > 0.35 && p1.z > 0.35) {
        const x0 = w * 0.5 + (p0.x / p0.z) * focal;
        const y0 = h * 0.5 - (p0.y / p0.z) * focal;
        const x1 = w * 0.5 + (p1.x / p1.z) * focal;
        const y1 = h * 0.5 - (p1.y / p1.z) * focal;

        const frac = age / 95;
        const tailX = x0 + (x1 - x0) * Math.max(0, frac - 0.35);
        const tailY = y0 + (y1 - y0) * Math.max(0, frac - 0.35);
        const headX = x0 + (x1 - x0) * Math.min(1, frac + 0.45);
        const headY = y0 + (y1 - y0) * Math.min(1, frac + 0.45);

        ctx.save();
        ctx.globalAlpha = Math.max(0, 1 - frac * 0.85);
        const tGrad = ctx.createLinearGradient(tailX, tailY, headX, headY);
        tGrad.addColorStop(0, 'rgba(255, 180, 40, 0.0)');
        tGrad.addColorStop(0.5, tr.isEnemy ? 'rgba(255, 110, 50, 0.85)' : 'rgba(255, 200, 75, 0.78)');
        tGrad.addColorStop(1, '#fff8d6');
        ctx.strokeStyle = tGrad;
        ctx.lineWidth = 2.4;
        ctx.beginPath();
        ctx.moveTo(tailX, tailY);
        ctx.lineTo(headX, headY);
        ctx.stroke();
        ctx.restore();
      }
    }

    // ------------------------------------------------------------------------
    // D. FIRST-PERSON CS 1.6 WEAPON VIEWMODEL (SHOOTING & MULTI-STAGE RELOAD)
    // ------------------------------------------------------------------------
    if (match.active && !(player.isAiming && currentWeapon.useScope)) {
      const skin = WEAPON_SKINS.find((s) => s.id === profile.equippedWeaponSkin) || WEAPON_SKINS[0];
      const bodyColor = skin.id === 'DefaultCyan' ? currentWeapon.bodyColor : skin.body;
      const accentColor = skin.id === 'DefaultCyan' ? currentWeapon.accentColor : skin.accent;
      const wepId = currentWeapon.id;

      // 1. Update & Render Rising Gunsmoke Puffs from Barrel & Chamber
      for (let i = muzzleSmoke.length - 1; i >= 0; i--) {
        const sm = muzzleSmoke[i];
        const age = nowMs - sm.born;
        if (age >= sm.life) {
          muzzleSmoke.splice(i, 1);
          continue;
        }
        sm.x += sm.vx * dt;
        sm.y += sm.vy * dt;
        sm.radius += sm.growRate * dt;
        const prog = age / sm.life;
        ctx.save();
        ctx.globalAlpha = sm.alpha * (1 - prog);
        const smGrad = ctx.createRadialGradient(sm.x, sm.y, 1, sm.x, sm.y, sm.radius);
        smGrad.addColorStop(0, 'rgba(195, 200, 192, 0.65)');
        smGrad.addColorStop(0.6, 'rgba(120, 126, 118, 0.3)');
        smGrad.addColorStop(1, 'rgba(60, 64, 60, 0)');
        ctx.fillStyle = smGrad;
        ctx.beginPath();
        ctx.arc(sm.x, sm.y, sm.radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      }

      // 2. Calculate Walk Bob, Horizontal Z-Kickback Recoil & Multi-Stage Reload Kinematics
      const isMoving =
        keys['KeyW'] ||
        keys['KeyA'] ||
        keys['KeyS'] ||
        keys['KeyD'] ||
        Math.hypot(touchState.moveX, touchState.moveY) > 0.12;
      const bobX = isMoving ? Math.cos(nowMs * 0.011) * 0.018 : Math.cos(nowMs * 0.0025) * 0.004;
      const bobY = isMoving ? Math.abs(Math.sin(nowMs * 0.011)) * 0.016 : Math.sin(nowMs * 0.0025) * 0.004;
      player.recoilRoll *= 0.82;

      // Reciprocating bolt / slide blowback along -Z right after firing
      const timeSinceShot = nowMs - player.lastShotMs;
      let shotBoltBlowback = 0;
      if (timeSinceShot >= 0 && timeSinceShot < 110) {
        shotBoltBlowback = Math.sin((timeSinceShot / 110) * Math.PI) * 0.18;
      }

      // Delayed AWP Bolt Action / M3 Shotgun Pump cycle after firing
      let postShotPumpZ = 0;
      let postShotBoltLiftY = 0;
      if (player.boltCycleStart > 0 && nowMs >= player.boltCycleStart && nowMs < player.boltCycleStart + 420) {
        const cyc = (nowMs - player.boltCycleStart) / 420;
        const wave = Math.sin(cyc * Math.PI);
        if (wepId === 'Shotgun') postShotPumpZ = wave * 0.22;
        if (wepId === 'SniperRifle') {
          postShotPumpZ = wave * 0.18;
          postShotBoltLiftY = wave * 0.06;
        }
      }

      // Multi-Stage 3D Reload Animation State (0.0 -> 1.0)
      // IMPORTANT: Rifle stays HORIZONTAL pointing forward (+Z), only rolling slightly on its axis!
      let reloadProg = 0;
      let reloadRollRad = 0;
      let reloadYawRad = 0;
      let reloadShiftX = 0;
      let reloadShiftY = 0;
      let magDropY = 0;
      let magShiftX = 0;
      let magShowBrass = false;
      let boltPullZ = shotBoltBlowback + postShotPumpZ;
      let leftHandTarget = { x: -0.03, y: -0.04, z: wepId === 'Pistol' ? -0.05 : 0.48 - (wepId === 'Shotgun' ? boltPullZ : 0) };
      let reloadStageText = '';
      let showShotgunShell = false;
      let shotgunShellInsertY = 0;

      if (player.isReloading) {
        reloadProg = Math.min(1, Math.max(0, (nowMs - player.reloadStartTime) / player.reloadDuration));

        if (reloadProg >= 0.56 && player.reloadStageAudio < 1) {
          player.reloadStageAudio = 1;
          playSound('reload_magin');
        }
        if (reloadProg >= 0.78 && player.reloadStageAudio < 2) {
          player.reloadStageAudio = 2;
          playSound('reload_bolt');
        }

        if (wepId === 'Shotgun') {
          if (reloadProg < 0.76) {
            reloadStageText = 'INSERTING 12-GAUGE SHELLS';
            reloadRollRad = 0.38;
            reloadShiftX = -0.05;
            const shellCycle = (reloadProg / 0.76) * 3;
            const sub = shellCycle - Math.floor(shellCycle);
            showShotgunShell = true;
            shotgunShellInsertY = -(1 - sub) * 0.24;
            leftHandTarget = { x: -0.04, y: -0.10 + shotgunShellInsertY, z: 0.16 };
            if (sub > 0.78 && player.reloadStageAudio < Math.floor(shellCycle) + 1) {
              player.reloadStageAudio = Math.floor(shellCycle) + 1;
              playSound('reload_magin');
            }
          } else {
            reloadStageText = 'PUMPING FOREND // CHAMBERING';
            const p = (reloadProg - 0.76) / 0.24;
            reloadRollRad = 0.38 * (1 - p);
            reloadShiftX = -0.05 * (1 - p);
            const pumpWave = Math.sin(p * Math.PI);
            boltPullZ = pumpWave * 0.24;
            leftHandTarget = { x: -0.03, y: -0.04, z: 0.48 - boltPullZ };
          }
        } else {
          if (reloadProg < 0.18) {
            // Phase 1: Roll rifle slightly on barrel axis to expose bottom magwell
            reloadStageText = 'UNLATCHING MAGAZINE';
            const p = reloadProg / 0.18;
            reloadRollRad = p * 0.42;
            reloadYawRad = p * 0.08;
            reloadShiftX = -p * 0.05;
            leftHandTarget = { x: -0.04, y: -0.18 * p, z: 0.48 * (1 - p) + 0.18 * p };
          } else if (reloadProg < 0.45) {
            // Phase 2: Pull empty magazine straight DOWN (-Y) out of receiver
            reloadStageText = 'EJECTING EMPTY MAGAZINE';
            const p = (reloadProg - 0.18) / 0.27;
            reloadRollRad = 0.42;
            reloadYawRad = 0.08;
            reloadShiftX = -0.05;
            magDropY = -p * 0.42;
            magShiftX = -p * 0.08;
            leftHandTarget = { x: -0.04 + magShiftX, y: -0.18 + magDropY, z: 0.18 };
          } else if (reloadProg < 0.74) {
            // Phase 3: Push fresh brass-loaded magazine UP (+Y) into receiver magwell
            reloadStageText = 'LOCKING FRESH MAGAZINE';
            const p = (reloadProg - 0.45) / 0.29;
            const easeOut = 1 - Math.pow(1 - p, 3);
            magShowBrass = true;
            magDropY = -0.42 * (1 - easeOut);
            magShiftX = -0.08 * (1 - easeOut);
            const lockJoltY = p > 0.65 && p < 0.9 ? 0.035 * Math.sin(((p - 0.65) / 0.25) * Math.PI) : 0;
            reloadRollRad = 0.42 - p * 0.12;
            reloadYawRad = 0.08 * (1 - p * 0.5);
            reloadShiftX = -0.05;
            reloadShiftY = lockJoltY;
            leftHandTarget = { x: -0.04 + magShiftX, y: -0.18 + magDropY, z: 0.18 };
          } else {
            // Phase 4: Left hand grabs charging handle/slide and pulls it BACK (-Z) along horizontal barrel
            reloadStageText = 'RACKING BOLT // CHAMBERING ROUND';
            const p = (reloadProg - 0.74) / 0.26;
            const rackWave = Math.sin(p * Math.PI);
            boltPullZ = rackWave * 0.22;
            reloadRollRad = 0.30 * (1 - p);
            reloadYawRad = 0.04 * (1 - p);
            reloadShiftX = -0.05 * (1 - p);
            leftHandTarget = { x: 0.05, y: 0.06, z: 0.14 - boltPullZ };
          }
        }
      }

      // 3. 3D Camera-Space Weapon Origin & Orientation (Pointing HORIZONTALLY FORWARD +Z!)
      // Notice: vmPitch is near 0.0 so the barrel points straight forward into the screen toward the crosshair!
      const vmFocal = (h * 0.5) / Math.tan((68 * Math.PI) / 360);
      const kickBackZ = player.recoilKick * 0.16; // Straight-back shoulder recoil along -Z!
      const vmOriginX = (player.isAiming ? 0.0 : (wepId === 'Pistol' ? 0.24 : 0.36)) + bobX + reloadShiftX;
      const vmOriginY = (player.isAiming ? -0.17 : (wepId === 'Pistol' ? -0.24 : -0.28)) - bobY + reloadShiftY - player.recoilKick * 0.015;
      const vmOriginZ = (player.isAiming ? 1.05 : (wepId === 'Pistol' ? 1.10 : 1.18)) - kickBackZ;

      // Weapon points forward (+Z) and slightly left (-X) so barrel line converges right at the center crosshair!
      const vmYaw = (player.isAiming ? 0.0 : -0.17) + reloadYawRad;
      // Pitch stays horizontal (0.02 rad), never pointing up at the ceiling!
      const vmPitch = (player.isAiming ? 0.0 : 0.015) - player.recoilMuzzleFlip * 0.22;
      const vmRoll = reloadRollRad + player.recoilRoll;

      const cY = Math.cos(vmYaw), sY = Math.sin(vmYaw);
      const cP = Math.cos(vmPitch), sP = Math.sin(vmPitch);
      const cR = Math.cos(vmRoll), sR = Math.sin(vmRoll);

      function localToVmCam(lx, ly, lz) {
        // 1. Roll around Z axis (barrel axis)
        const rx = lx * cR - ly * sR;
        const ry = lx * sR + ly * cR;
        const rz = lz;
        // 2. Pitch around X axis
        const py = ry * cP - rz * sP;
        const pz = ry * sP + rz * cP;
        // 3. Yaw around Y axis
        const yx = rx * cY + pz * sY;
        const yz = -rx * sY + pz * cY;
        return {
          x: vmOriginX + yx,
          y: vmOriginY + py,
          z: Math.max(0.25, vmOriginZ + yz),
        };
      }

      function projectVmPt(pt) {
        return {
          x: w * 0.5 + (pt.x / pt.z) * vmFocal + player.screenShakeX,
          y: h * 0.5 - (pt.y / pt.z) * vmFocal + player.screenShakeY,
        };
      }

      // 4. Multi-Lobed 3D Muzzle Flash at the Forward Barrel Tip!
      const muzzleLocalZ = wepId === 'Pistol' ? 0.52 : wepId === 'SMG' ? 1.02 : wepId === 'SniperRifle' ? 1.65 : 1.38;
      const muzzleCamPt = localToVmCam(0, 0.04, muzzleLocalZ);
      const muzzleScreen = projectVmPt(muzzleCamPt);

      if (nowMs < player.muzzleFlashUntil) {
        ctx.save();
        const flashR = wepId === 'Shotgun' || wepId === 'SniperRifle' ? 68 : 52;
        const outerGlow = ctx.createRadialGradient(muzzleScreen.x, muzzleScreen.y, 3, muzzleScreen.x, muzzleScreen.y, flashR * 1.5);
        outerGlow.addColorStop(0, 'rgba(255, 252, 215, 0.96)');
        outerGlow.addColorStop(0.35, 'rgba(255, 170, 38, 0.78)');
        outerGlow.addColorStop(0.7, 'rgba(235, 85, 20, 0.28)');
        outerGlow.addColorStop(1, 'rgba(235, 85, 20, 0)');
        ctx.fillStyle = outerGlow;
        ctx.beginPath();
        ctx.arc(muzzleScreen.x, muzzleScreen.y, flashR * 1.5, 0, Math.PI * 2);
        ctx.fill();

        ctx.translate(muzzleScreen.x, muzzleScreen.y);
        ctx.rotate(player.muzzleFlashAngle);
        const spikes = 6;
        ctx.beginPath();
        for (let s = 0; s < spikes * 2; s++) {
          const r = s % 2 === 0 ? flashR * (0.85 + (s % 3) * 0.12) : flashR * 0.28;
          const ang = (s * Math.PI) / spikes;
          const px = Math.cos(ang) * r;
          const py = Math.sin(ang) * r;
          if (s === 0) ctx.moveTo(px, py);
          else ctx.lineTo(px, py);
        }
        ctx.closePath();
        ctx.fillStyle = '#ffae24';
        ctx.fill();

        ctx.beginPath();
        ctx.arc(0, 0, 14, 0, Math.PI * 2);
        ctx.fillStyle = '#fffef2';
        ctx.fill();
        ctx.restore();
      }

      // 5. Collect 3D Shaded Faces for Both Arms/Hands & Horizontal 3D Weapon
      const vmFaces = [];
      function pushVmHexahedron(c000, c100, c010, c110, c001, c101, c011, c111, hexCol, strokeCol = '#121416') {
        const faces = [
          { verts: [c010, c110, c111, c011], shade: 1.18 }, // Top (+Y)
          { verts: [c000, c001, c101, c100], shade: 0.62 }, // Bottom (-Y)
          { verts: [c000, c010, c011, c001], shade: 0.96 }, // Left side (-X, facing camera)
          { verts: [c100, c101, c111, c110], shade: 0.78 }, // Right side (+X)
          { verts: [c000, c100, c110, c010], shade: 0.88 }, // Rear face (-Z, facing player)
          { verts: [c001, c011, c111, c101], shade: 0.72 }, // Front face (+Z)
        ];

        for (let i = 0; i < faces.length; i++) {
          const fv = faces[i].verts;
          const cx = (fv[0].x + fv[1].x + fv[2].x + fv[3].x) * 0.25;
          const cy = (fv[0].y + fv[1].y + fv[2].y + fv[3].y) * 0.25;
          const cz = (fv[0].z + fv[1].z + fv[2].z + fv[3].z) * 0.25;
          vmFaces.push({
            verts2D: fv.map(projectVmPt),
            fill: shadeHexColor(hexCol, faces[i].shade),
            stroke: strokeCol,
            dist: Math.hypot(cx, cy, cz),
          });
        }
      }

      function addVmBox(lx, ly, lz, bw, bh, bd, hexCol, strokeCol = '#121416') {
        const x0 = lx - bw * 0.5, x1 = lx + bw * 0.5;
        const y0 = ly - bh * 0.5, y1 = ly + bh * 0.5;
        const z0 = lz - bd * 0.5, z1 = lz + bd * 0.5;

        pushVmHexahedron(
          localToVmCam(x0, y0, z0),
          localToVmCam(x1, y0, z0),
          localToVmCam(x0, y1, z0),
          localToVmCam(x1, y1, z0),
          localToVmCam(x0, y0, z1),
          localToVmCam(x1, y0, z1),
          localToVmCam(x0, y1, z1),
          localToVmCam(x1, y1, z1),
          hexCol,
          strokeCol
        );
      }

      // Oriented 3D Limb Builder: Connects start point p0 seamlessly to end point p1 as ONE continuous arm!
      function addVmLimb(p0, p1, w0, h0, w1, h1, hexCol, strokeCol = '#121416') {
        const dx = p1.x - p0.x;
        const dy = p1.y - p0.y;
        const dz = p1.z - p0.z;
        const len = Math.hypot(dx, dy, dz) || 1;
        const fx = dx / len, fy = dy / len, fz = dz / len;

        // Cross product with Up (0, 1, 0) to get orthogonal Right vector
        let rx = fz, ry = 0, rz = -fx;
        const rLen = Math.hypot(rx, ry, rz) || 1;
        rx /= rLen; rz /= rLen;

        // Up = Forward x Right
        const ux = fy * rz - fz * ry;
        const uy = fz * rx - fx * rz;
        const uz = fx * ry - fy * rx;

        const hw0 = w0 * 0.5, hh0 = h0 * 0.5;
        const hw1 = w1 * 0.5, hh1 = h1 * 0.5;

        function corner(p, sR, sU) {
          return localToVmCam(
            p.x + rx * sR + ux * sU,
            p.y + ry * sR + uy * sU,
            p.z + rz * sR + uz * sU
          );
        }

        pushVmHexahedron(
          corner(p0, -hw0, -hh0),
          corner(p0, hw0, -hh0),
          corner(p0, -hw0, hh0),
          corner(p0, hw0, hh0),
          corner(p1, -hw1, -hh1),
          corner(p1, hw1, -hh1),
          corner(p1, -hw1, hh1),
          corner(p1, hw1, hh1),
          hexCol,
          strokeCol
        );
      }

      // --- A. STRICTLY 2 ARTICULATED 3D ARMS (1 Left Support Arm + 1 Right Trigger Arm!) ---
      const charSkin = CHARACTER_SKINS.find((c) => c.id === profile.equippedCharacterSkin) || CHARACTER_SKINS[0];
      const sleeveCol = charSkin.uniform || '#384634';

      // 1. RIGHT TRIGGER ARM (Single continuous forearm from lower-right edge to Pistol Grip)
      const rShoulder = { x: 0.22, y: -0.34, z: -0.38 };
      const rWrist = { x: 0.02, y: -0.14, z: -0.09 };
      addVmLimb(rShoulder, rWrist, 0.11, 0.105, 0.088, 0.085, sleeveCol);
      addVmBox(0.01, -0.125, -0.06, 0.088, 0.095, 0.11, '#1b1e1b'); // Right tactical glove on pistol grip
      addVmBox(-0.032, -0.11, -0.03, 0.035, 0.075, 0.09, '#cfa37a'); // Right trigger fingers wrapped on grip

      // 2. LEFT SUPPORT ARM (Single continuous forearm from lower-left edge to Handguard / Magazine)
      const lh = leftHandTarget;
      const lShoulder = { x: -0.28, y: -0.35, z: -0.20 };
      const lWrist = { x: lh.x - 0.015, y: lh.y - 0.015, z: lh.z - 0.07 };
      addVmLimb(lShoulder, lWrist, 0.11, 0.105, 0.086, 0.084, sleeveCol);
      addVmBox(lh.x, lh.y, lh.z, 0.092, 0.088, 0.14, '#1b1e1b'); // Left tactical glove gripping forend
      addVmBox(lh.x - 0.042, lh.y + 0.012, lh.z + 0.01, 0.034, 0.072, 0.11, '#d4aa82'); // Left fingers wrapped on handguard

      // --- B. 3D HORIZONTAL WEAPON GEOMETRY (Extending straight forward along +Z!) ---
      if (wepId === 'AssaultRifle') {
        // ==================== [1] 3D CV-47 / AK-47 ====================
        // Laminated wooden buttstock (-Z) & pistol grip
        addVmBox(0, -0.05, -0.42, 0.075, 0.12, 0.38, accentColor);
        addVmBox(0, -0.13, -0.08, 0.065, 0.16, 0.09, '#6e3f1d');
        // Stamped steel receiver & ribbed top dust cover
        addVmBox(0, 0.0, 0.06, 0.088, 0.11, 0.46, bodyColor);
        addVmBox(0, 0.065, 0.05, 0.076, 0.04, 0.44, '#202326');
        // Ejection port & reciprocating silver bolt carrier + charging handle knob
        addVmBox(0.036, 0.045, 0.14 - boltPullZ, 0.03, 0.045, 0.16, '#adb6be');
        addVmBox(0.065, 0.045, 0.18 - boltPullZ, 0.045, 0.025, 0.03, '#7c848c');
        // Curved 30-Round Banana Magazine hanging DOWNWARD (-Y) under receiver!
        addVmBox(magShiftX, -0.19 + magDropY, 0.18, 0.062, 0.24, 0.11, '#292420');
        addVmBox(magShiftX, -0.32 + magDropY, 0.23, 0.060, 0.14, 0.11, '#24201c');
        if (magShowBrass) {
          addVmBox(magShiftX, -0.06 + magDropY, 0.18, 0.05, 0.03, 0.09, '#ebb82f');
        }
        // Birch-wood lower & upper handguard extending forward (+Z)
        addVmBox(0, 0.005, 0.50, 0.082, 0.095, 0.42, accentColor);
        addVmBox(0, 0.06, 0.48, 0.068, 0.045, 0.36, shadeHexColor(accentColor, 0.88));
        // Forward rifle barrel, gas tube, front sight post & slanted compensator (+Z)
        addVmBox(0, 0.058, 0.82, 0.036, 0.036, 0.32, '#282c30'); // Gas tube
        addVmBox(0, 0.02, 1.04, 0.038, 0.038, 0.68, '#181a1c');  // Steel barrel pointing forward!
        addVmBox(0, 0.085, 1.26, 0.024, 0.095, 0.045, '#141618'); // Front sight post triangle
        addVmBox(0, 0.095, 0.24, 0.055, 0.03, 0.05, '#141618');   // Rear tangent iron sight

      } else if (wepId === 'SniperRifle') {
        // ==================== [2] 3D MAGNUM SNIPER / AWP ====================
        // Olive-drab thumbhole polymer chassis extending horizontally
        addVmBox(0, -0.03, -0.42, 0.082, 0.13, 0.42, bodyColor);
        addVmBox(0, -0.12, -0.08, 0.068, 0.14, 0.09, '#222622');
        addVmBox(0, -0.01, 0.25, 0.086, 0.10, 0.88, bodyColor);
        // Steel bolt-action receiver & animated bolt handle
        addVmBox(0, 0.055, 0.08, 0.076, 0.06, 0.44, '#1e2022');
        addVmBox(0.06, 0.055 + postShotBoltLiftY, 0.04 - boltPullZ, 0.06, 0.025, 0.03, '#6c747c');
        // Detachable .338 box magazine
        addVmBox(magShiftX, -0.12 + magDropY, 0.18, 0.065, 0.14, 0.14, '#24272a');
        // Dual-ring telescopic sniper scope on top of receiver
        addVmBox(0, 0.13, 0.12, 0.045, 0.06, 0.04, '#141618');  // Rear scope ring
        addVmBox(0, 0.13, 0.42, 0.045, 0.06, 0.04, '#141618');  // Front scope ring
        addVmBox(0, 0.165, 0.26, 0.068, 0.068, 0.56, '#16181a'); // Scope tube pointing forward
        addVmBox(0, 0.165, -0.02, 0.062, 0.062, 0.02, '#2d8a62'); // Emerald ocular lens
        // Long heavy free-floating fluted barrel & dual-baffle muzzle brake (+Z)
        addVmBox(0, 0.04, 1.16, 0.042, 0.042, 0.96, '#1a1d20');
        addVmBox(0, 0.04, 1.64, 0.062, 0.055, 0.09, '#121416');

      } else if (wepId === 'Shotgun') {
        // ==================== [3] 3D LEONE 12 GAUGE / BENELLI M3 ====================
        addVmBox(0, -0.05, -0.40, 0.078, 0.12, 0.38, '#222528');
        addVmBox(0, -0.13, -0.08, 0.065, 0.15, 0.09, '#1c1e20');
        // Parkerized shotgun receiver & red shell ejection port
        addVmBox(0, 0.02, 0.08, 0.088, 0.12, 0.46, bodyColor);
        addVmBox(0.038, 0.04, 0.14 - boltPullZ * 0.5, 0.025, 0.04, 0.14, '#c92a2a');
        // Over-under 12-gauge barrel & full-length under-barrel tubular magazine (+Z)
        addVmBox(0, 0.055, 0.84, 0.046, 0.046, 1.06, '#1c1e22');
        addVmBox(0, 0.005, 0.78, 0.042, 0.042, 0.94, '#2a2e34');
        // Sliding ribbed tactical pump forend (moves along Z with boltPullZ!)
        addVmBox(0, -0.01, 0.54 - boltPullZ, 0.092, 0.085, 0.34, accentColor);
        if (showShotgunShell) {
          addVmBox(-0.02, -0.08 + shotgunShellInsertY, 0.14, 0.042, 0.042, 0.11, '#d62828');
        }

      } else if (wepId === 'SMG') {
        // ==================== [4] 3D KM SUB-MACHINE / H&K MP5-NAVY ====================
        addVmBox(0, -0.03, -0.34, 0.068, 0.10, 0.32, '#1e2124');
        addVmBox(0, -0.13, -0.06, 0.062, 0.15, 0.085, '#1c1e20');
        // Roller-delayed blowback receiver
        addVmBox(0, 0.02, 0.10, 0.082, 0.11, 0.42, bodyColor);
        // Curved 9mm steel magazine hanging downward (-Y)
        addVmBox(magShiftX, -0.18 + magDropY, 0.20, 0.052, 0.22, 0.085, '#22262a');
        // Wide tropical polymer forearm grip (+Z)
        addVmBox(0, 0.0, 0.48, 0.086, 0.085, 0.34, accentColor);
        // Forward cocking tube, hooded front sight & lugged barrel
        addVmBox(0, 0.055, 0.54, 0.042, 0.042, 0.42, '#25292e');
        addVmBox(-0.045, 0.055, 0.58 - boltPullZ, 0.045, 0.024, 0.03, '#788088');
        addVmBox(0, 0.02, 0.84, 0.038, 0.038, 0.38, '#181a1e');
        addVmBox(0, 0.075, 0.82, 0.045, 0.055, 0.035, '#181a1e');

      } else {
        // ==================== [5] 3D NIGHT HAWK .50C / DESERT EAGLE ====================
        // Two-handed pistol grip & removable magazine inside grip
        addVmBox(0, -0.12, -0.04, 0.068, 0.18, 0.10, '#1e2022');
        if (player.isReloading) {
          addVmBox(magShiftX, -0.16 + magDropY, -0.04, 0.056, 0.16, 0.085, '#25282c');
        }
        // Lower frame & trigger guard
        addVmBox(0, -0.01, 0.18, 0.068, 0.05, 0.46, shadeHexColor(bodyColor, 0.82));
        // Exposed gold/brass .50 AE chamber when slide blows back
        addVmBox(0, 0.045, 0.16, 0.056, 0.055, 0.22, '#e6b832');
        // Heavy reciprocating two-tone Desert Eagle slide & triangular barrel pointing forward (+Z)
        addVmBox(0, 0.05, 0.18 - boltPullZ, 0.076, 0.078, 0.50, bodyColor);
        addVmBox(0, 0.095, -0.03 - boltPullZ, 0.062, 0.024, 0.03, '#42e642'); // Rear tritium sight
        addVmBox(0, 0.095, 0.40, 0.026, 0.024, 0.03, '#141618');              // Front sight blade
      }

      // Sort 3D weapon & arm faces back-to-front (Painter's Algorithm) and render
      vmFaces.sort((a, b) => b.dist - a.dist);
      for (let i = 0; i < vmFaces.length; i++) {
        const f = vmFaces[i];
        const pts = f.verts2D;
        ctx.beginPath();
        ctx.moveTo(pts[0].x, pts[0].y);
        for (let j = 1; j < pts.length; j++) {
          ctx.lineTo(pts[j].x, pts[j].y);
        }
        ctx.closePath();
        ctx.fillStyle = f.fill;
        ctx.fill();
        ctx.strokeStyle = f.stroke;
        ctx.lineWidth = 1.3;
        ctx.stroke();
      }

      // 6. Update & Render Spinning Ejected Brass Casings & Red Shotgun Hulls
      for (let i = shellCasings.length - 1; i >= 0; i--) {
        const sc = shellCasings[i];
        const age = nowMs - sc.born;
        if (age > 1100) {
          shellCasings.splice(i, 1);
          continue;
        }
        sc.x += sc.vx * dt;
        sc.y += sc.vy * dt;
        sc.vy += 980 * dt;
        sc.angle += sc.vAngle * dt;

        if (!sc.pinged && age > 420) {
          sc.pinged = true;
          playSound('shell_drop');
        }

        ctx.save();
        ctx.translate(sc.x, sc.y);
        ctx.rotate(sc.angle);
        if (sc.isShotgunHull) {
          ctx.fillStyle = '#cf2929';
          ctx.fillRect(-sc.length * 0.5, -sc.thickness * 0.5, sc.length * 0.72, sc.thickness);
          ctx.fillStyle = '#ebb82f';
          ctx.fillRect(sc.length * 0.22, -sc.thickness * 0.55, sc.length * 0.28, sc.thickness * 1.1);
          ctx.strokeStyle = '#1a1410';
          ctx.lineWidth = 1.2;
          ctx.strokeRect(-sc.length * 0.5, -sc.thickness * 0.5, sc.length, sc.thickness);
        } else {
          const bGrad = ctx.createLinearGradient(0, -sc.thickness * 0.5, 0, sc.thickness * 0.5);
          bGrad.addColorStop(0, '#fff2a6');
          bGrad.addColorStop(0.5, '#d9a126');
          bGrad.addColorStop(1, '#7a560d');
          ctx.fillStyle = bGrad;
          ctx.fillRect(-sc.length * 0.5, -sc.thickness * 0.5, sc.length, sc.thickness);
          ctx.strokeStyle = '#382806';
          ctx.lineWidth = 1;
          ctx.strokeRect(-sc.length * 0.5, -sc.thickness * 0.5, sc.length, sc.thickness);
        }
        ctx.restore();
      }

      // 7. On-Screen CS 1.6 Tactical Reload Progress Bar & Stage Readout
      if (player.isReloading) {
        const barW = 230;
        const barH = 10;
        const bx = w * 0.5 - barW * 0.5;
        const by = h * 0.5 + 54;

        ctx.save();
        ctx.fillStyle = 'rgba(14, 17, 14, 0.86)';
        ctx.strokeStyle = '#788470';
        ctx.lineWidth = 1.5;
        ctx.fillRect(bx - 6, by - 24, barW + 12, 42);
        ctx.strokeRect(bx - 6, by - 24, barW + 12, 42);

        ctx.font = 'bold 11px Consolas, monospace';
        ctx.fillStyle = '#ffb000';
        ctx.textAlign = 'center';
        ctx.fillText(`${reloadStageText} [${Math.round(reloadProg * 100)}%]`, w * 0.5, by - 8);

        ctx.fillStyle = '#1c201c';
        ctx.fillRect(bx, by, barW, barH);
        ctx.fillStyle = reloadProg > 0.74 ? '#42e642' : '#ffb000';
        ctx.fillRect(bx, by, barW * reloadProg, barH);
        ctx.strokeStyle = '#444c40';
        ctx.strokeRect(bx, by, barW, barH);
        ctx.restore();
      }
    }

    // 8. Crimson Blood Damage Vignette when Player Takes Enemy Fire
    if (match.active && player.hurtAlpha > 0.01) {
      ctx.save();
      const hurtGrad = ctx.createRadialGradient(
        w * 0.5,
        h * 0.5,
        Math.min(w, h) * 0.28,
        w * 0.5,
        h * 0.5,
        Math.max(w, h) * 0.68
      );
      hurtGrad.addColorStop(0, 'rgba(140, 0, 0, 0)');
      hurtGrad.addColorStop(1, `rgba(175, 10, 10, ${(player.hurtAlpha * 0.65).toFixed(3)})`);
      ctx.fillStyle = hurtGrad;
      ctx.fillRect(0, 0, w, h);
      ctx.restore();
    }

    requestAnimationFrame(renderFrame);
  }

  requestAnimationFrame(renderFrame);
})();
