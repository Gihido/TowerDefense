local EconomyService = {}

function EconomyService.Init(remotes, playerDataService, gameState)
	EconomyService.Remotes = remotes
	EconomyService.PlayerDataService = playerDataService
	EconomyService.GameState = gameState
end

function EconomyService.AddCoins(player, amount)
	if EconomyService.PlayerDataService.AddCoins(player, amount) then
		EconomyService.UpdateHudForPlayer(player)
		return true
	end
	return false
end

function EconomyService.SpendCoins(player, amount)
	if EconomyService.PlayerDataService.SpendCoins(player, amount) then
		EconomyService.UpdateHudForPlayer(player)
		return true
	end
	return false
end

function EconomyService.UpdateHudForPlayer(player)
	local data = EconomyService.PlayerDataService.GetData(player)
	if not data then return end
	EconomyService.Remotes.UpdateHud:FireClient(player, {
		Coins = data.Coins,
		BaseHealth = EconomyService.GameState.BaseHealth,
		Wave = EconomyService.GameState.CurrentWave,
		EnemiesLeft = EconomyService.GameState.EnemiesAlive,
		MatchActive = EconomyService.GameState.MatchActive,
		UnlockedTowers = data.UnlockedTowers,
	})
end

function EconomyService.UpdateHudForAll(players)
	for _, player in ipairs(players:GetPlayers()) do
		EconomyService.UpdateHudForPlayer(player)
	end
end

return EconomyService
