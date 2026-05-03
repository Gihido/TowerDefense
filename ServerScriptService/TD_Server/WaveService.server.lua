local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local WaveConfig = require(ReplicatedStorage.Modules.WaveConfig)

local WaveService = {}

function WaveService.Init(gameState, enemyService, economyService, remotes)
	WaveService.GameState = gameState
	WaveService.EnemyService = enemyService
	WaveService.EconomyService = economyService
	WaveService.Remotes = remotes
end

function WaveService.StartGame()
	if WaveService.GameState.MatchActive then return false, "Матч уже идет" end
	WaveService.GameState.MatchActive = true
	WaveService.GameState.CurrentWave = 0
	task.spawn(function()
		for wave = 1, GameConfig.MaxWaves do
			if not WaveService.GameState.MatchActive then break end
			WaveService.StartWave(wave)
			while WaveService.GameState.EnemiesAlive > 0 and WaveService.GameState.BaseHealth > 0 do
				task.wait(0.25)
				WaveService.EconomyService.UpdateHudForAll(Players)
			end
			if WaveService.GameState.BaseHealth <= 0 then
				WaveService.EndGame("База разрушена")
				return
			end
			task.wait(GameConfig.IntermissionTime)
		end
		if WaveService.GameState.BaseHealth > 0 then
			WaveService.EndGame("Победа! Волны завершены")
		end
	end)
	return true
end

function WaveService.StartWave(waveNumber)
	WaveService.GameState.CurrentWave = waveNumber
	WaveService.SpawnWave(WaveConfig[waveNumber] or {})
end

function WaveService.SpawnWave(waveData)
	for _, batch in ipairs(waveData) do
		for _ = 1, batch.Count do
			WaveService.EnemyService.SpawnEnemy(batch.EnemyId)
			task.wait(GameConfig.EnemySpawnDelay)
		end
	end
end

function WaveService.EndGame(reason)
	WaveService.GameState.MatchActive = false
	for _, player in ipairs(Players:GetPlayers()) do
		WaveService.Remotes.NotifyPlayer:FireClient(player, reason)
	end
end

return WaveService
