local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local MATCH_PLACE_ID = 1234567890 -- TODO: replace with your real match place id

local remotesFolder = ReplicatedStorage:FindFirstChild("TD_Remotes") or Instance.new("Folder")
remotesFolder.Name = "TD_Remotes"
remotesFolder.Parent = ReplicatedStorage

local function getRemote(name)
	local r = remotesFolder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotesFolder
	end
	return r
end

local LobbySummonRequest = getRemote("LobbySummonRequest")
local LobbyInventoryRequest = getRemote("LobbyInventoryRequest")
local LobbyEquipRequest = getRemote("LobbyEquipRequest")
local LobbyPlayRequest = getRemote("LobbyPlayRequest")
local UpdateLobbyGui = getRemote("UpdateLobbyGui")
local Notify = getRemote("Notify")

getRemote("MatchPlaceUnitRequest")
getRemote("MatchUpgradeUnitRequest")
getRemote("MatchSelectUnitRequest")
getRemote("UpdateMatchGui")
getRemote("PlayEffect")

local UNIT_POOL = {
	{ Name = "Scout", Rarity = "Common", Chance = 65 },
	{ Name = "Gunner", Rarity = "Rare", Chance = 25 },
	{ Name = "Sniper", Rarity = "Epic", Chance = 8 },
	{ Name = "Blaster", Rarity = "Legendary", Chance = 2 },
}

local SESSION = {}
local START_LOBBY_COINS = 100
local SUMMON_COST = 50
local MAX_EQUIP = 4

local function cloneArray(a)
	local n = {}
	for i, v in ipairs(a) do n[i] = v end
	return n
end

local function pushLobby(player)
	local d = SESSION[player]
	if not d then return end
	UpdateLobbyGui:FireClient(player, {
		LobbyCoins = d.LobbyCoins,
		Inventory = cloneArray(d.Inventory),
		Equipped = cloneArray(d.Equipped),
		SummonCost = SUMMON_COST,
		MaxEquip = MAX_EQUIP,
		UnitPool = UNIT_POOL,
	})
end

local function hasUnit(inv, name)
	for _, v in ipairs(inv) do if v == name then return true end end
	return false
end

local function chooseUnit()
	local roll = math.random(1, 100)
	local sum = 0
	for _, u in ipairs(UNIT_POOL) do
		sum += u.Chance
		if roll <= sum then return u end
	end
	return UNIT_POOL[1]
end

Players.PlayerAdded:Connect(function(player)
	-- TODO DataStore load here
	SESSION[player] = { LobbyCoins = START_LOBBY_COINS, Inventory = {"Scout"}, Equipped = {"Scout"} }
	pushLobby(player)
end)

Players.PlayerRemoving:Connect(function(player)
	-- TODO DataStore save here
	SESSION[player] = nil
end)

LobbyInventoryRequest.OnServerEvent:Connect(function(player)
	pushLobby(player)
end)

LobbySummonRequest.OnServerEvent:Connect(function(player)
	local d = SESSION[player]; if not d then return end
	if d.LobbyCoins < SUMMON_COST then
		Notify:FireClient(player, "Не хватает монет для призыва")
		return
	end
	d.LobbyCoins -= SUMMON_COST
	local unit = chooseUnit()
	table.insert(d.Inventory, unit.Name)
	pushLobby(player)
	Notify:FireClient(player, "Получен: "..unit.Name.." ("..unit.Rarity..")")
	getRemote("PlayEffect"):FireClient(player, "SummonReveal", unit)
end)

LobbyEquipRequest.OnServerEvent:Connect(function(player, unitName, equip)
	local d = SESSION[player]; if not d then return end
	if type(unitName) ~= "string" then return end
	if not hasUnit(d.Inventory, unitName) then return end
	local idx
	for i, v in ipairs(d.Equipped) do if v == unitName then idx = i break end end
	if equip then
		if idx then return end
		if #d.Equipped >= MAX_EQUIP then Notify:FireClient(player, "Максимум 4 юнита") return end
		table.insert(d.Equipped, unitName)
	else
		if idx then table.remove(d.Equipped, idx) end
	end
	pushLobby(player)
end)

LobbyPlayRequest.OnServerEvent:Connect(function(player)
	if MATCH_PLACE_ID == 0 or MATCH_PLACE_ID == game.PlaceId or MATCH_PLACE_ID == 1234567890 then
		local spawn = workspace:FindFirstChild("TD_Map") and workspace.TD_Map:FindFirstChild("MatchSpawn") or workspace:FindFirstChild("MatchSpawn")
		if spawn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
		end
		Notify:FireClient(player, "Тестовый старт в этом же Place")
	else
		TeleportService:Teleport(MATCH_PLACE_ID, player)
	end
end)

_G.TD_LOBBY_SESSION = SESSION
