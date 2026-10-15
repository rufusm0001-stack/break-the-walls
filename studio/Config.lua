-- ReplicatedStorage.BTW.Config: every tunable number lives here (DESIGN.md "Starting numbers").
local Config = {}

Config.CUBE_SIZE = 2 -- studs
Config.WALL_CUBES = { w = 16, h = 10, d = 2 } -- breakable wall in cubes (32 x 20 x 4 studs)

Config.Fists = { cooldown = 0.35, damage = 1, pattern = "cross5", ringDamage = 0.5 }
Config.Hammer = { price = 250, cooldown = 0.45, damage = 4, pattern = "cross9" }

Config.Storage = { start = 50 }
Config.FirstUpgradeCosts = { 50, 150, 400 } -- Radius / Power / Depth tiers I-III

-- Zones run along -Z. zMax/zMin are the zone's floor bounds (used by ZoneMood and checkpoints).
Config.Zones = {
	{
		id = 1, name = "Stone Facility", zMax = 2, zMin = -62,
		cube = { name = "Stone", value = 1, hits = 2, colors = { "C7CBD4", "C7CBD4", "A8ADB8" } },
		accent = "3FD45B", spawn = Vector3.new(0, 1, -8),
	},
	{
		id = 2, name = "Mine Cave", zMax = -62, zMin = -166,
		cube = { name = "Orange Ore", value = 3, hits = 3, colors = { "E07A2E", "E07A2E", "F2A04A", "7A5A45" } },
		accent = "FFB000", spawn = Vector3.new(0, 1, -70),
		mood = { tint = "FFE6CC", saturation = 0.1, fogColor = "8A6E58" },
	},
	{
		id = 3, name = "Security Vault", zMax = -166, zMin = -290, provisional = true,
		cube = { name = "Reinforced Steel", value = 8, hits = 4, colors = { "9FB4C8", "9FB4C8", "7F95AB", "5E6E80" } },
		accent = "E5322D", spawn = Vector3.new(0, 1, -174),
		boss = { name = "Warden", hp = 200 },
	},
}

return Config
