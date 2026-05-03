local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService.server)
local EconomyService = require(script.Parent.EconomyService.server)
local EnemyService = require(script.Parent.EnemyService.server)
local TowerService = require(script.Parent.TowerService.server)
local SummonService = require(script.Parent.SummonService.server)
local WaveService = require(script.Parent.WaveService.server)

local function SafeWaitForChild(parent, name, timeout)
	if not parent then return nil end
	local obj = parent:FindFirstChild(name)
	if obj then return obj end
	local ok, result = pcall(function() return parent:WaitForChild(name, timeout or 5) end)
	if ok then return result end
	return nil
end

local function ensureRemote(name)
	local folder = SafeWaitForChild(ReplicatedStorage, "Remotes", 5) or Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	local remote = folder:FindFirstChild(name)
	if not remote then remote = Instance.new("RemoteEvent"); remote.Name = name; remote.Parent = folder end
	return remote
end

local Remotes = {
	StartGameRequest = ensureRemote("StartGameRequest"),
	PlaceTowerRequest = ensureRemote("PlaceTowerRequest"),
	SummonUnitRequest = ensureRemote("SummonUnitRequest"),
	UpdateHud = ensureRemote("UpdateHud"),
	NotifyPlayer = ensureRemote("NotifyPlayer"),
	PlayEffect = ensureRemote("PlayEffect"),
}

local function createMapIfMissing()
	local map = workspace:FindFirstChild("TD_Map")
	if map then return map end
	map = Instance.new("Folder"); map.Name = "TD_Map"; map.Parent = workspace
	local floor = Instance.new("Part", map); floor.Name = "Baseplate"; floor.Size = Vector3.new(180,1,120); floor.Anchored=true; floor.Color=Color3.fromRGB(95,95,95); floor.Position=Vector3.new(0,0,0)
	local lobby = Instance.new("SpawnLocation", map); lobby.Name="LobbySpawn"; lobby.Anchored=true; lobby.Size=Vector3.new(12,1,12); lobby.Color=Color3.fromRGB(80,200,120); lobby.Position=Vector3.new(-70,2,0)
	local match = Instance.new("SpawnLocation", map); match.Name="MatchSpawn"; match.Anchored=true; match.Size=Vector3.new(10,1,10); match.Position=Vector3.new(-20,2,20)
	local enemySpawn = Instance.new("Part", map); enemySpawn.Name="EnemySpawn"; enemySpawn.Anchored=true; enemySpawn.Size=Vector3.new(4,1,4); enemySpawn.Position=Vector3.new(-50,1,0)
	local base = Instance.new("Part", map); base.Name="Base"; base.Anchored=true; base.Size=Vector3.new(10,10,10); base.Color=Color3.fromRGB(50,150,255); base.Position=Vector3.new(55,5,20)
	local wpFolder = Instance.new("Folder", map); wpFolder.Name="Waypoints"
	local pts = {Vector3.new(-40,2,0),Vector3.new(-10,2,0),Vector3.new(5,2,20),Vector3.new(30,2,20),Vector3.new(50,2,20)}
	for i,p in ipairs(pts) do local wp=Instance.new("Part",wpFolder); wp.Name=tostring(i); wp.Shape=Enum.PartType.Ball; wp.Size=Vector3.new(1,1,1); wp.Anchored=true; wp.Position=p; wp.Color=Color3.fromRGB(255,255,0) end
	local zFolder = Instance.new("Folder", map); zFolder.Name = "TowerZones"
	for i,pos in ipairs({Vector3.new(-15,1,8),Vector3.new(0,1,8),Vector3.new(15,1,30),Vector3.new(28,1,10)}) do local z=Instance.new("Part",zFolder); z.Name="Zone"..i; z.Anchored=true; z.Size=Vector3.new(8,1,8); z.Position=pos; z.Color=Color3.fromRGB(80,255,120); z.Transparency=0.35 end
	return map
end

local map = createMapIfMissing()

local GameState = { MatchActive = false, CurrentWave = 0, EnemiesAlive = 0, BaseHealth = GameConfig.BaseHealth }
EconomyService.Init(Remotes, PlayerDataService, GameState)
EnemyService.Init(Remotes, GameState, map, EconomyService)
TowerService.Init(Remotes, PlayerDataService, EconomyService, EnemyService, GameState, map)
SummonService.Init(Remotes, PlayerDataService, EconomyService)
WaveService.Init(GameState, EnemyService, EconomyService, Remotes)

Players.PlayerAdded:Connect(function(player)
	PlayerDataService.InitPlayer(player, GameConfig.StartCoins)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.15)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and map:FindFirstChild("LobbySpawn") then hrp.CFrame = map.LobbySpawn.CFrame + Vector3.new(0,4,0) end
	end)
	EconomyService.UpdateHudForPlayer(player)
end)
Players.PlayerRemoving:Connect(function(player) PlayerDataService.CleanupPlayer(player) end)

Remotes.StartGameRequest.OnServerEvent:Connect(function(player)
	local ok,msg = WaveService.StartGame()
	if not ok then Remotes.NotifyPlayer:FireClient(player, msg or "Ошибка") return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and map:FindFirstChild("MatchSpawn") then
			p.Character.HumanoidRootPart.CFrame = map.MatchSpawn.CFrame + Vector3.new(0,4,0)
		end
	end
end)

Remotes.PlaceTowerRequest.OnServerEvent:Connect(function(player, towerId, zoneName)
	local ok, err = TowerService.PlaceTower(player, towerId, zoneName)
	if not ok then Remotes.NotifyPlayer:FireClient(player, err) end
	EconomyService.UpdateHudForPlayer(player)
end)

Remotes.SummonUnitRequest.OnServerEvent:Connect(function(player)
	local ok, result = SummonService.Summon(player)
	if not ok then Remotes.NotifyPlayer:FireClient(player, result) end
end)
