local TowerConfig = {
	ScoutTower = {
		DisplayName = "Scout Tower",
		Price = 100,
		Damage = 10,
		Range = 25,
		FireRate = 1,
		Color = Color3.fromRGB(70, 140, 255),
		Description = "Обычный стрелок",
		SplashRadius = 0,
		Upgrade = {
			MaxLevel = 3,
			Levels = {
				[2] = { UpgradeCost = 80, Damage = 14, Range = 28, FireRate = 0.95 },
				[3] = { UpgradeCost = 140, Damage = 20, Range = 32, FireRate = 0.85 },
			},
		},
	},
	SniperTower = {
		DisplayName = "Sniper Tower",
		Price = 250,
		Damage = 35,
		Range = 45,
		FireRate = 2.2,
		Color = Color3.fromRGB(165, 85, 255),
		Description = "Дальняя атака",
		SplashRadius = 0,
		Upgrade = {
			MaxLevel = 3,
			Levels = {
				[2] = { UpgradeCost = 170, Damage = 45, Range = 50, FireRate = 2.0 },
				[3] = { UpgradeCost = 260, Damage = 65, Range = 56, FireRate = 1.8 },
			},
		},
	},
	CannonTower = {
		DisplayName = "Cannon Tower",
		Price = 400,
		Damage = 25,
		Range = 28,
		FireRate = 2.5,
		Color = Color3.fromRGB(255, 155, 70),
		Description = "Урон по области",
		SplashRadius = 10,
		Upgrade = {
			MaxLevel = 3,
			Levels = {
				[2] = { UpgradeCost = 240, Damage = 34, Range = 30, FireRate = 2.3, SplashRadius = 12 },
				[3] = { UpgradeCost = 350, Damage = 48, Range = 33, FireRate = 2.0, SplashRadius = 14 },
			},
		},
	},
}

return TowerConfig
