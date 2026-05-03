local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local UnitConfig = require(ReplicatedStorage.Modules.UnitConfig)

local SummonService = {}

function SummonService.Init(remotes, playerDataService, economyService)
	SummonService.Remotes = remotes
	SummonService.PlayerDataService = playerDataService
	SummonService.EconomyService = economyService
end

function SummonService.RollUnit()
	local roll = math.random(1, 100)
	local acc = 0
	for _, unit in ipairs(UnitConfig.Pools) do
		acc += unit.Chance
		if roll <= acc then return unit end
	end
	return UnitConfig.Pools[1]
end

function SummonService.Summon(player)
	if not SummonService.EconomyService.SpendCoins(player, GameConfig.SummonCost) then
		return false, "Недостаточно монет"
	end
	local data = SummonService.PlayerDataService.GetData(player)
	if not data then return false, "Игрок не найден" end
	local unit = SummonService.RollUnit()
	table.insert(data.OwnedUnits, unit.Name)
	SummonService.PlayerDataService.UnlockTower(player, unit.UnlockTower)
	SummonService.Remotes.NotifyPlayer:FireClient(player, "Получен юнит: " .. unit.Name)
	SummonService.Remotes.PlayEffect:FireClient(player, "SummonReveal", { UnitName = unit.Name, Rarity = unit.Rarity })
	SummonService.EconomyService.UpdateHudForPlayer(player)
	return true, unit
end

return SummonService
