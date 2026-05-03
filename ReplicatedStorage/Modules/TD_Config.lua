-- TD_Config: единый конфиг для быстрой настройки игры
local TD_Config = {
	Game = {
		StartCoins = 300,
		BaseHealth = 100,
		SummonCost = 100,
		IntermissionTime = 5,
		EnemySpawnDelay = 0.7,
		MaxWaves = 5,
	},
	Towers = {
		ScoutTower = { Price = 100, Damage = 10, Range = 25, FireRate = 1, SplashRadius = 0, Color = Color3.fromRGB(70,140,255), Description = "Обычный стрелок" },
		SniperTower = { Price = 250, Damage = 35, Range = 45, FireRate = 2.2, SplashRadius = 0, Color = Color3.fromRGB(165,85,255), Description = "Дальняя атака" },
		CannonTower = { Price = 400, Damage = 25, Range = 28, FireRate = 2.5, SplashRadius = 10, Color = Color3.fromRGB(255,155,70), Description = "Урон по области" },
	},
	Enemies = {
		BasicEnemy = { HP = 50, Speed = 8, Reward = 25, DamageToBase = 5, Color = Color3.fromRGB(220,220,220), Scale = 1 },
		FastEnemy = { HP = 35, Speed = 14, Reward = 35, DamageToBase = 4, Color = Color3.fromRGB(255,240,70), Scale = 0.9 },
		TankEnemy = { HP = 160, Speed = 5, Reward = 75, DamageToBase = 15, Color = Color3.fromRGB(90,140,90), Scale = 1.2 },
		BossEnemy = { HP = 450, Speed = 6, Reward = 200, DamageToBase = 25, Color = Color3.fromRGB(170,70,70), Scale = 1.6 },
	},
	Waves = {
		[1] = { { EnemyId = "BasicEnemy", Count = 8 } },
		[2] = { { EnemyId = "BasicEnemy", Count = 12 }, { EnemyId = "FastEnemy", Count = 3 } },
		[3] = { { EnemyId = "BasicEnemy", Count = 10 }, { EnemyId = "FastEnemy", Count = 5 }, { EnemyId = "TankEnemy", Count = 2 } },
		[4] = { { EnemyId = "BasicEnemy", Count = 15 }, { EnemyId = "FastEnemy", Count = 8 }, { EnemyId = "TankEnemy", Count = 4 } },
		[5] = { { EnemyId = "TankEnemy", Count = 8 } },
	},
	SummonPool = {
		{ Name = "Common Scout", Rarity = "Common", Chance = 70, UnlockTower = "ScoutTower" },
		{ Name = "Rare Sniper", Rarity = "Rare", Chance = 25, UnlockTower = "SniperTower" },
		{ Name = "Epic Cannon", Rarity = "Epic", Chance = 5, UnlockTower = "CannonTower" },
	},
}

return TD_Config
