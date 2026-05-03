local PlayerDataService = {}

local playerData = {}

function PlayerDataService.InitPlayer(player, startCoins)
	playerData[player] = {
		Coins = startCoins,
		OwnedUnits = {},
		UnlockedTowers = { ScoutTower = true },
		PlacedTowers = {},
	}
end

function PlayerDataService.GetData(player)
	return playerData[player]
end

function PlayerDataService.AddCoins(player, amount)
	local data = playerData[player]
	if not data then return false end
	data.Coins += math.max(0, amount)
	return true
end

function PlayerDataService.SpendCoins(player, amount)
	local data = playerData[player]
	if not data or amount < 0 then return false end
	if data.Coins < amount then return false end
	data.Coins -= amount
	return true
end

function PlayerDataService.UnlockTower(player, towerId)
	local data = playerData[player]
	if not data then return false end
	data.UnlockedTowers[towerId] = true
	return true
end

function PlayerDataService.HasTowerUnlocked(player, towerId)
	local data = playerData[player]
	if not data then return false end
	return data.UnlockedTowers[towerId] == true
end

function PlayerDataService.CleanupPlayer(player)
	playerData[player] = nil
end

return PlayerDataService
