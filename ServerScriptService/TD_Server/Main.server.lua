local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cfg = require(ReplicatedStorage.Modules.TD_Config)

local function SafeWaitForChild(parent, name, timeout)
	if not parent then return nil end
	local found = parent:FindFirstChild(name)
	if found then return found end
	local ok, result = pcall(function() return parent:WaitForChild(name, timeout or 5) end)
	return ok and result or nil
end

local function ensureRemote(folder, name)
	local obj = folder:FindFirstChild(name)
	if not obj then obj = Instance.new("RemoteEvent"); obj.Name = name; obj.Parent = folder end
	return obj
end

local remotesFolder = SafeWaitForChild(ReplicatedStorage, "Remotes", 5) or Instance.new("Folder", ReplicatedStorage)
remotesFolder.Name = "Remotes"
local Remotes = {
	StartGameRequest = ensureRemote(remotesFolder, "StartGameRequest"),
	PlaceTowerRequest = ensureRemote(remotesFolder, "PlaceTowerRequest"),
	SummonUnitRequest = ensureRemote(remotesFolder, "SummonUnitRequest"),
	UpdateHud = ensureRemote(remotesFolder, "UpdateHud"),
	NotifyPlayer = ensureRemote(remotesFolder, "NotifyPlayer"),
	PlayEffect = ensureRemote(remotesFolder, "PlayEffect"),
}

local GameState = { MatchActive = false, CurrentWave = 0, EnemiesAlive = 0, BaseHealth = Cfg.Game.BaseHealth }
local PlayerData, AliveEnemies, ZoneOccupation = {}, {}, {}

local function createMapIfMissing()
	local map = workspace:FindFirstChild("TD_Map")
	if map then return map end
	map = Instance.new("Folder", workspace); map.Name = "TD_Map"
	local lobby = Instance.new("SpawnLocation", map); lobby.Name="LobbySpawn"; lobby.Anchored=true; lobby.Size=Vector3.new(12,1,12); lobby.Position=Vector3.new(-70,2,0); lobby.Color=Color3.fromRGB(80,200,120)
	local match = Instance.new("SpawnLocation", map); match.Name="MatchSpawn"; match.Anchored=true; match.Size=Vector3.new(10,1,10); match.Position=Vector3.new(-20,2,20)
	local enemySpawn = Instance.new("Part", map); enemySpawn.Name="EnemySpawn"; enemySpawn.Anchored=true; enemySpawn.Size=Vector3.new(4,1,4); enemySpawn.Position=Vector3.new(-50,1,0)
	local base = Instance.new("Part", map); base.Name="Base"; base.Anchored=true; base.Size=Vector3.new(10,10,10); base.Position=Vector3.new(55,5,20)
	local wp = Instance.new("Folder", map); wp.Name = "Waypoints"
	for i,v in ipairs({Vector3.new(-40,2,0),Vector3.new(-10,2,0),Vector3.new(5,2,20),Vector3.new(30,2,20),Vector3.new(50,2,20)}) do local p=Instance.new("Part",wp); p.Name=tostring(i); p.Anchored=true; p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(1,1,1); p.Position=v end
	local zones = Instance.new("Folder", map); zones.Name="TowerZones"
	for i,v in ipairs({Vector3.new(-15,1,8),Vector3.new(0,1,8),Vector3.new(15,1,30),Vector3.new(28,1,10)}) do local z=Instance.new("Part",zones); z.Name="Zone"..i; z.Anchored=true; z.Size=Vector3.new(8,1,8); z.Position=v; z.Color=Color3.fromRGB(80,255,120); z.Transparency=0.35 end
	return map
end
local map = createMapIfMissing()

local function updateHud(plr)
	local d = PlayerData[plr]; if not d then return end
	Remotes.UpdateHud:FireClient(plr, {Coins=d.Coins, Wave=GameState.CurrentWave, EnemiesLeft=GameState.EnemiesAlive, BaseHealth=GameState.BaseHealth, MatchActive=GameState.MatchActive, UnlockedTowers=d.UnlockedTowers})
end
local function updateHudAll() for _,p in ipairs(Players:GetPlayers()) do updateHud(p) end end

local function award(plr, amount) if PlayerData[plr] then PlayerData[plr].Coins += amount; updateHud(plr) end end
local function spend(plr, amount) local d=PlayerData[plr]; if not d or d.Coins < amount then return false end d.Coins -= amount; updateHud(plr); return true end

local function getWaypoints() local pts = map.Waypoints:GetChildren(); table.sort(pts, function(a,b) return tonumber(a.Name)<tonumber(b.Name) end); return pts end
local function removeEnemy(enemy)
	for i,e in ipairs(AliveEnemies) do if e==enemy then table.remove(AliveEnemies,i); break end end
	GameState.EnemiesAlive = math.max(0, GameState.EnemiesAlive - 1)
end

local function damageEnemy(enemy, damage, owner)
	if not enemy or not enemy.Parent then return end
	local hp = enemy:FindFirstChild("HP"); if not hp then return end
	hp.Value -= damage; Remotes.PlayEffect:FireAllClients("EnemyHit", {Enemy=enemy})
	if hp.Value <= 0 then
		Remotes.PlayEffect:FireAllClients("EnemyDeath", {Position=enemy.PrimaryPart.Position})
		removeEnemy(enemy); enemy:Destroy(); if owner then award(owner, enemy:GetAttribute("Reward") or 0) end
	end
end

local function spawnEnemy(enemyId)
	local eCfg = Cfg.Enemies[enemyId]; if not eCfg then return end
	local enemy = Instance.new("Model", workspace); enemy.Name = enemyId
	local root = Instance.new("Part", enemy); root.Name="HumanoidRootPart"; root.Anchored=true; root.Size=Vector3.new(2,2,2)*eCfg.Scale; root.CFrame=map.EnemySpawn.CFrame+Vector3.new(0,2,0); root.Color=eCfg.Color; root.Material=Enum.Material.Neon
	enemy.PrimaryPart = root
	local hp = Instance.new("NumberValue", enemy); hp.Name="HP"; hp.Value=eCfg.HP
	enemy:SetAttribute("Speed", eCfg.Speed); enemy:SetAttribute("Reward", eCfg.Reward); enemy:SetAttribute("DamageToBase", eCfg.DamageToBase)
	table.insert(AliveEnemies, enemy); GameState.EnemiesAlive += 1; Remotes.PlayEffect:FireAllClients("EnemySpawn", {Enemy=enemy})
	task.spawn(function()
		for _,wp in ipairs(getWaypoints()) do
			if not enemy.Parent then return end
			local startPos = enemy.PrimaryPart.Position
			local dur = (wp.Position - startPos).Magnitude / math.max(1, enemy:GetAttribute("Speed") or 8)
			local t = 0
			while t < dur and enemy.Parent do local dt=RunService.Heartbeat:Wait(); t += dt; enemy:PivotTo(CFrame.new(startPos:Lerp(wp.Position, math.clamp(t/dur,0,1)))) end
		end
		if enemy.Parent then GameState.BaseHealth -= enemy:GetAttribute("DamageToBase") or 1; removeEnemy(enemy); enemy:Destroy() end
	end)
end

local function placeTower(plr, towerId, zoneName)
	if not GameState.MatchActive then return false, "Матч не начат" end
	local tCfg = Cfg.Towers[towerId]; local d = PlayerData[plr]
	local zone = map.TowerZones:FindFirstChild(zoneName)
	if not d or not tCfg then return false, "Ошибка башни" end
	if not d.UnlockedTowers[towerId] then return false, "Башня не открыта" end
	if not zone then return false, "Неверная зона" end
	if ZoneOccupation[zone] then return false, "Место занято" end
	if not spend(plr, tCfg.Price) then return false, "Не хватает монет" end
	local tower = Instance.new("Model", workspace); tower.Name=towerId
	local base = Instance.new("Part", tower); base.Name="Base"; base.Anchored=true; base.Size=Vector3.new(4,1,4); base.CFrame=zone.CFrame+Vector3.new(0,1,0); base.Color=tCfg.Color
	local top = Instance.new("Part", tower); top.Name="Top"; top.Anchored=true; top.Size=Vector3.new(2,2,2); top.CFrame=base.CFrame+Vector3.new(0,1.6,0); top.Color=tCfg.Color
	tower.PrimaryPart = base
	ZoneOccupation[zone] = tower
	Remotes.PlayEffect:FireAllClients("PlaceTower", {Position=base.Position})
	task.spawn(function()
		while tower.Parent and GameState.MatchActive do
			local best, bestDist
			for _,enemy in ipairs(AliveEnemies) do
				if enemy.Parent then
					local dist=(enemy.PrimaryPart.Position-base.Position).Magnitude
					if dist <= tCfg.Range and (not bestDist or dist < bestDist) then best=enemy; bestDist=dist end
				end
			end
			if best then
				Remotes.PlayEffect:FireAllClients("TowerShoot", {Tower=tower, Enemy=best})
				damageEnemy(best, tCfg.Damage, plr)
				if (tCfg.SplashRadius or 0) > 0 then
					for _,enemy in ipairs(AliveEnemies) do if enemy.Parent and enemy~=best and (enemy.PrimaryPart.Position-best.PrimaryPart.Position).Magnitude <= tCfg.SplashRadius then damageEnemy(enemy, math.floor(tCfg.Damage*0.6), plr) end end
				end
			end
			task.wait(tCfg.FireRate)
		end
	end)
	return true
end

local function summon(plr)
	if not spend(plr, Cfg.Game.SummonCost) then return false, "Недостаточно монет" end
	local roll, acc = math.random(1,100), 0
	for _,unit in ipairs(Cfg.SummonPool) do
		acc += unit.Chance
		if roll <= acc then
			table.insert(PlayerData[plr].OwnedUnits, unit.Name)
			PlayerData[plr].UnlockedTowers[unit.UnlockTower] = true
			Remotes.NotifyPlayer:FireClient(plr, "Получен юнит: "..unit.Name)
			Remotes.PlayEffect:FireClient(plr, "SummonReveal", unit)
			updateHud(plr)
			return true
		end
	end
	return false, "Ошибка призыва"
end

local function startGame()
	if GameState.MatchActive then return false, "Матч уже идет" end
	GameState.MatchActive = true; GameState.CurrentWave = 0; GameState.BaseHealth = Cfg.Game.BaseHealth
	task.spawn(function()
		for wave = 1, Cfg.Game.MaxWaves do
			if not GameState.MatchActive then return end
			GameState.CurrentWave = wave
			for _,batch in ipairs(Cfg.Waves[wave] or {}) do for _=1,batch.Count do spawnEnemy(batch.EnemyId); task.wait(Cfg.Game.EnemySpawnDelay) end end
			while GameState.EnemiesAlive > 0 and GameState.BaseHealth > 0 do updateHudAll(); task.wait(0.25) end
			if GameState.BaseHealth <= 0 then break end
			task.wait(Cfg.Game.IntermissionTime)
		end
		GameState.MatchActive = false
		Remotes.NotifyPlayer:FireAllClients(GameState.BaseHealth <= 0 and "База разрушена" or "Победа")
		updateHudAll()
	end)
	return true
end

Players.PlayerAdded:Connect(function(plr)
	PlayerData[plr] = { Coins = Cfg.Game.StartCoins, OwnedUnits = {}, UnlockedTowers = {ScoutTower=true} }
	plr.CharacterAdded:Connect(function(ch)
		task.wait(0.15)
		local hrp = ch:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = map.LobbySpawn.CFrame + Vector3.new(0,4,0) end
	end)
	updateHud(plr)
end)
Players.PlayerRemoving:Connect(function(plr) PlayerData[plr] = nil end)

Remotes.StartGameRequest.OnServerEvent:Connect(function(plr)
	local ok,msg = startGame(); if not ok then Remotes.NotifyPlayer:FireClient(plr,msg); return end
	for _,p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then p.Character.HumanoidRootPart.CFrame = map.MatchSpawn.CFrame + Vector3.new(0,4,0) end end
end)
Remotes.PlaceTowerRequest.OnServerEvent:Connect(function(plr,towerId,zoneName) local ok,err = placeTower(plr,towerId,zoneName); if not ok then Remotes.NotifyPlayer:FireClient(plr,err) end end)
Remotes.SummonUnitRequest.OnServerEvent:Connect(function(plr) local ok,err=summon(plr); if not ok then Remotes.NotifyPlayer:FireClient(plr,err) end end)
