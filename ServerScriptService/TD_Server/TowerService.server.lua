local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TowerConfig = require(ReplicatedStorage.Modules.TowerConfig)

local TowerService = { OccupiedZones = {} }

function TowerService.Init(remotes, playerDataService, economyService, enemyService, gameState, tdMap)
	TowerService.Remotes = remotes
	TowerService.PlayerDataService = playerDataService
	TowerService.EconomyService = economyService
	TowerService.EnemyService = enemyService
	TowerService.GameState = gameState
	TowerService.Map = tdMap
end

function TowerService.CreateTowerModel(towerId, cframe)
	local cfg = TowerConfig[towerId]
	if not cfg then return nil end
	local model = Instance.new("Model")
	model.Name = towerId
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 1, 4)
	base.Color = cfg.Color
	base.Material = Enum.Material.SmoothPlastic
	base.Anchored = true
	base.CFrame = cframe
	base.Parent = model
	local top = Instance.new("Part")
	top.Name = "Top"
	top.Size = Vector3.new(2, 2, 2)
	top.Color = cfg.Color:Lerp(Color3.new(1, 1, 1), 0.2)
	top.Anchored = true
	top.CFrame = cframe + Vector3.new(0, 1.6, 0)
	top.Parent = model
	model.PrimaryPart = base
	model:SetAttribute("TowerId", towerId)
	model:SetAttribute("Damage", cfg.Damage)
	model:SetAttribute("Range", cfg.Range)
	model:SetAttribute("FireRate", cfg.FireRate)
	model:SetAttribute("SplashRadius", cfg.SplashRadius or 0)
	model:SetAttribute("Level", 1)
	model.Parent = workspace
	return model
end

function TowerService.IsValidZone(zoneName)
	local zones = TowerService.Map:FindFirstChild("TowerZones")
	if not zones then return nil end
	return zones:FindFirstChild(zoneName)
end

function TowerService.PlaceTower(player, towerId, zoneName)
	if not TowerService.GameState.MatchActive then return false, "Матч не начат" end
	local cfg = TowerConfig[towerId]
	if not cfg then return false, "Неизвестная башня" end
	if not TowerService.PlayerDataService.HasTowerUnlocked(player, towerId) then return false, "Башня не открыта" end
	local zone = TowerService.IsValidZone(zoneName)
	if not zone then return false, "Неверная зона" end
	if TowerService.OccupiedZones[zone] then return false, "Место занято" end
	if not TowerService.EconomyService.SpendCoins(player, cfg.Price) then return false, "Не хватает монет" end
	local tower = TowerService.CreateTowerModel(towerId, zone.CFrame + Vector3.new(0, 1, 0))
	if not tower then return false, "Ошибка создания" end
	TowerService.OccupiedZones[zone] = tower
	task.spawn(function() TowerService.StartTowerAI(tower, player) end)
	TowerService.Remotes.PlayEffect:FireAllClients("PlaceTower", { Position = tower.PrimaryPart.Position })
	return true
end

function TowerService.FindTarget(towerModel, range)
	local enemies = TowerService.EnemyService.GetAliveEnemies()
	local best, bestDist
	for _, enemy in ipairs(enemies) do
		local d = (enemy.PrimaryPart.Position - towerModel.PrimaryPart.Position).Magnitude
		if d <= range and (not bestDist or d < bestDist) then
			best, bestDist = enemy, d
		end
	end
	return best
end

function TowerService.AttackTarget(tower, target, owner)
	if not target or not target.Parent then return end
	TowerService.Remotes.PlayEffect:FireAllClients("TowerShoot", { Tower = tower, Enemy = target })
	TowerService.EnemyService.DamageEnemy(target, tower:GetAttribute("Damage") or 0, owner)
	local splash = tower:GetAttribute("SplashRadius") or 0
	if splash > 0 then
		for _, enemy in ipairs(TowerService.EnemyService.GetAliveEnemies()) do
			if enemy ~= target and (enemy.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude <= splash then
				TowerService.EnemyService.DamageEnemy(enemy, math.floor((tower:GetAttribute("Damage") or 0) * 0.6), owner)
			end
		end
	end
end

function TowerService.StartTowerAI(towerModel, ownerPlayer)
	while towerModel and towerModel.Parent and TowerService.GameState.MatchActive do
		local range = towerModel:GetAttribute("Range") or 20
		local target = TowerService.FindTarget(towerModel, range)
		if target then TowerService.AttackTarget(towerModel, target, ownerPlayer) end
		task.wait(towerModel:GetAttribute("FireRate") or 1)
	end
end

return TowerService
