-- ReplicatedStorage.BTW.Config: every tunable number lives here (DESIGN.md "Starting numbers").
local Config = {}

Config.CUBE_SIZE = 1 -- studs (was 2; owner wanted smaller cubes, 2026-10-15)
-- breakable wall face in cubes (32 x 20 studs). Depth (layers) is per zone: Config.Zones[n].wallDepth.
-- The layers past the doorway's 4-stud wall reach into the corridor behind it.
Config.WALL_CUBES = { w = 32, h = 20 }

Config.Fists = { slot = 1, cooldown = 0.35, damage = 1, pattern = "cross5", ringDamage = 0.5, range = 10 }
Config.Hammer = { price = 250, cooldown = 0.45, damage = 4, pattern = "cross9" }

-- Hit patterns on the wall face: { u, v, ring } in cube steps. Ring cells take damage * ringDamage.
Config.Patterns = {
	cross5 = { { 0, 0, false }, { 1, 0, true }, { -1, 0, true }, { 0, 1, true }, { 0, -1, true } },
	cross9 = {
		{ 0, 0, false }, { 1, 0, false }, { -1, 0, false }, { 0, 1, false }, { 0, -1, false },
		{ 2, 0, true }, { -2, 0, true }, { 0, 2, true }, { 0, -2, true },
	},
}

-- Vacuum (slot 2, hold LMB): pulls loose cubes inside a cone in front of the camera.
-- A cube caught in the cone is claimed (anchored) and every client flies it along a curved, swirling path into
-- the nozzle; the server banks it when the flight ends (flight time = distance / pullSpeed, clamped).
Config.Vacuum = {
	slot = 2, range = 18, coneDot = 0.7, pullSpeed = 30, collectRadius = 3.5, tick = 0.05,
	minFlight = 0.25, maxFlight = 0.7, swirl = 3,
}

Config.Storage = { start = 50 }

-- Broken cubes drop as loose pickups. Past maxCount, new drops merge into a nearby loose cube
-- (it carries Count) or the oldest one is recycled, so the part count stays bounded.
Config.Loose = { size = 0.6, maxCount = 200, mergeRadius = 6 }

-- Player settings (gear button): saved with the player's data.
Config.Settings = {
	sensitivity = { default = 0.45, min = 0.05, max = 1.5 }, -- UserInputService.MouseDeltaSensitivity
	music = { default = 0.35, min = 0, max = 1 },
	sfx = { default = 0.8, min = 0, max = 1 },
}

-- Deposit machine: pays the stored Value in batches while you stand in Function.DepositZone.
Config.Deposit = { batch = 10, tick = 0.15 }

-- A zone's wall counts as "passable" once a hole holeW x holeH cubes, fully through every layer, starts
-- in one of the bottom (maxStartRow + 1) rows. Then the next Spawn_ZoneN checkpoint is enabled.
-- Counted in cubes: 4 x 6 one-stud cubes = the same 4 x 6 stud hole as before.
Config.Checkpoint = { holeW = 4, holeH = 6, maxStartRow = 3 }

Config.Save = { store = "BTW_Player_v1", autosave = 60 }
Config.FirstUpgradeCosts = { 50, 150, 400 } -- Radius / Power / Depth tiers I-III

-- Zones run along -Z. zMax/zMin are the zone's floor bounds (used by ZoneMood and checkpoints).
-- Balance for 1-stud cubes (first pass, 2026-10-15): a cube is 1/8 the old volume, so hits dropped (a cross5
-- punch now breaks ~3 cubes in Zone 1) and value per cube stays, so a full 50-cube storage trip pays the same as
-- before; trips just fill faster. Hole: 4x6xwallDepth cubes.
Config.Zones = {
	{
		id = 1, name = "Stone Facility", zMax = 2, zMin = -62,
		cube = { name = "Stone", value = 1, hits = 1, colors = { "C7CBD4", "C7CBD4", "A8ADB8" } },
		wallDepth = 5, accent = "3FD45B", spawn = Vector3.new(0, 1, -8),
	},
	{
		id = 2, name = "Mine Cave", zMax = -62, zMin = -166,
		cube = { name = "Orange Ore", value = 3, hits = 1.5, colors = { "E07A2E", "E07A2E", "F2A04A", "7A5A45" } },
		wallDepth = 6, accent = "FFB000", spawn = Vector3.new(0, 1, -70),
		mood = { tint = "FFE6CC", saturation = 0.1, fogColor = "8A6E58" },
	},
	{
		id = 3, name = "Security Vault", zMax = -166, zMin = -290, provisional = true,
		cube = { name = "Reinforced Steel", value = 8, hits = 2, colors = { "9FB4C8", "9FB4C8", "7F95AB", "5E6E80" } },
		wallDepth = 7, accent = "E5322D", spawn = Vector3.new(0, 1, -174),
		boss = { name = "Warden", hp = 200 },
	},
}

return Config
