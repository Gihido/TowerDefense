local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyConfig = require(ReplicatedStorage.Modules.EnemyConfig)

local EnemyService = { AliveEnemies = {} }

function EnemyService.Init(remotes, gameState, tdMap, economyService)
	EnemyService.Remotes = remotes
	EnemyService.GameState = gameState
	EnemyService.Map = tdMap
	EnemyService.EconomyService = economyService
end

function EnemyService.CreateEnemyModel(enemyId)
	local cfg = EnemyConfig[enemyId]
	if not cfg then return nil end
	local model = Instance.new("Model")
	model.Name = enemyId
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 2) * cfg.Scale
	root.Anchored = true
	root.Color = cfg.Color
	root.Material = Enum.Material.Neon
	root.CFrame = EnemyService.Map.EnemySpawn.CFrame + Vector3.new(0, 2, 0)
	root.Parent = model
	model.PrimaryPart = root
	local hp = Instance.new("NumberValue")
	hp.Name = "HP"
	hp.Value = cfg.HP
	hp.Parent = model
	local maxHp = Instance.new("NumberValue")
	maxHp.Name = "MaxHP"
	maxHp.Value = cfg.HP
	maxHp.Parent = model
	model:SetAttribute("EnemyId", enemyId)
	model:SetAttribute("Speed", cfg.Speed)
	model:SetAttribute("Reward", cfg.Reward)
	model:SetAttribute("DamageToBase", cfg.DamageToBase)
	model.Parent = workspace
	return model
end

function EnemyService.SpawnEnemy(enemyId)
	local enemy = EnemyService.CreateEnemyModel(enemyId)
	if not enemy then return nil end
	table.insert(EnemyService.AliveEnemies, enemy)
	EnemyService.GameState.EnemiesAlive += 1
	EnemyService.Remotes.PlayEffect:FireAllClients("EnemySpawn", { Enemy = enemy })
	task.spawn(function() EnemyService.MoveEnemy(enemy) end)
	return enemy
end

function EnemyService.GetWaypoints()
	local folder = EnemyService.Map:FindFirstChild("Waypoints")
	if not folder then return {} end
	local pts = folder:GetChildren()
	table.sort(pts, function(a, b) return tonumber(a.Name) < tonumber(b.Name) end)
	return pts
end

function EnemyService.MoveEnemy(enemy)
	local points = EnemyService.GetWaypoints()
	for _, wp in ipairs(points) do
		if not enemy or not enemy.Parent then return end
		local startPos = enemy.PrimaryPart.Position
		local dist = (wp.Position - startPos).Magnitude
		local speed = enemy:GetAttribute("Speed") or 8
		local duration = math.max(0.05, dist / speed)
		local t = 0
		while t < duration and enemy.Parent do
			local dt = RunService.Heartbeat:Wait()
			t += dt
			local alpha = math.clamp(t / duration, 0, 1)
			enemy:PivotTo(CFrame.new(startPos:Lerp(wp.Position, alpha)))
		end
	end
	if enemy and enemy.Parent then EnemyService.EnemyReachedBase(enemy) end
end

function EnemyService.DamageEnemy(enemy, damage, sourcePlayer)
	if not enemy or not enemy.Parent then return end
	local hp = enemy:FindFirstChild("HP")
	if not hp then return end
	hp.Value -= damage
	EnemyService.Remotes.PlayEffect:FireAllClients("EnemyHit", { Enemy = enemy })
	if hp.Value <= 0 then EnemyService.KillEnemy(enemy, sourcePlayer) end
end

function EnemyService.KillEnemy(enemy, killerPlayer)
	if not enemy or not enemy.Parent then return end
	EnemyService.Remotes.PlayEffect:FireAllClients("EnemyDeath", { Position = enemy.PrimaryPart.Position })
	if killerPlayer then
		EnemyService.EconomyService.AddCoins(killerPlayer, enemy:GetAttribute("Reward") or 0)
	end
	EnemyService.GameState.EnemiesAlive = math.max(0, EnemyService.GameState.EnemiesAlive - 1)
	for i, e in ipairs(EnemyService.AliveEnemies) do if e == enemy then table.remove(EnemyService.AliveEnemies, i) break end end
	enemy:Destroy()
end

function EnemyService.EnemyReachedBase(enemy)
	if not enemy or not enemy.Parent then return end
	EnemyService.GameState.BaseHealth -= enemy:GetAttribute("DamageToBase") or 5
	EnemyService.GameState.EnemiesAlive = math.max(0, EnemyService.GameState.EnemiesAlive - 1)
	for i, e in ipairs(EnemyService.AliveEnemies) do if e == enemy then table.remove(EnemyService.AliveEnemies, i) break end end
	enemy:Destroy()
end

function EnemyService.GetAliveEnemies()
	local list = {}
	for _, enemy in ipairs(EnemyService.AliveEnemies) do
		if enemy and enemy.Parent then table.insert(list, enemy) end
	end
	EnemyService.AliveEnemies = list
	return list
end

return EnemyService
