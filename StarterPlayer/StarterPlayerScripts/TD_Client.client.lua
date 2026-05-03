local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local selectedTower

local function safe(name)
	return remotes:WaitForChild(name, 5)
end

local StartGameRequest = safe("StartGameRequest")
local PlaceTowerRequest = safe("PlaceTowerRequest")
local SummonUnitRequest = safe("SummonUnitRequest")
local UpdateHud = safe("UpdateHud")
local NotifyPlayer = safe("NotifyPlayer")

local gui = player:WaitForChild("PlayerGui"):FindFirstChild("TDGui") or Instance.new("ScreenGui")
gui.Name = "TDGui"; gui.ResetOnSpawn = false; gui.Parent = player.PlayerGui
local mainHud = gui:FindFirstChild("MainHud") or Instance.new("Frame", gui); mainHud.Name="MainHud"; mainHud.Size=UDim2.fromScale(1,1); mainHud.BackgroundTransparency=1

local coins = Instance.new("TextLabel", mainHud); coins.Name="Coins"; coins.Position=UDim2.fromScale(0.01,0.02); coins.Size=UDim2.fromScale(0.2,0.06); coins.TextScaled=true
local wave = Instance.new("TextLabel", mainHud); wave.Name="Wave"; wave.Position=UDim2.fromScale(0.4,0.02); wave.Size=UDim2.fromScale(0.2,0.06); wave.TextScaled=true
local base = Instance.new("TextLabel", mainHud); base.Name="Base"; base.Position=UDim2.fromScale(0.79,0.02); base.Size=UDim2.fromScale(0.2,0.06); base.TextScaled=true

local startBtn = Instance.new("TextButton", mainHud); startBtn.Text="Начать игру"; startBtn.Size=UDim2.fromScale(0.18,0.07); startBtn.Position=UDim2.fromScale(0.41,0.12)
local summonBtn = Instance.new("TextButton", mainHud); summonBtn.Text="Призыв"; summonBtn.Size=UDim2.fromScale(0.14,0.07); summonBtn.Position=UDim2.fromScale(0.84,0.86)

local shop = gui:FindFirstChild("TowerShop") or Instance.new("Frame", gui); shop.Name="TowerShop"; shop.Size=UDim2.fromScale(0.52,0.15); shop.Position=UDim2.fromScale(0.24,0.82); shop.BackgroundColor3=Color3.fromRGB(30,30,30); shop.BackgroundTransparency=0.2
local notify = gui:FindFirstChild("Notifications") or Instance.new("Frame", gui); notify.Name="Notifications"; notify.Size=UDim2.fromScale(0.3,0.2); notify.Position=UDim2.fromScale(0.68,0.1); notify.BackgroundTransparency=1
local summonGui = gui:FindFirstChild("SummonGui") or Instance.new("Frame", gui); summonGui.Name="SummonGui"; summonGui.Size=UDim2.fromScale(0.8,0.6); summonGui.Position=UDim2.fromScale(0.1,0.2); summonGui.Visible=false; summonGui.BackgroundColor3=Color3.fromRGB(20,20,20)

for i, towerId in ipairs({"ScoutTower","SniperTower","CannonTower"}) do
	local b = Instance.new("TextButton", shop)
	b.Size=UDim2.fromScale(0.31,0.84); b.Position=UDim2.fromScale((i-1)*0.33+0.01,0.08); b.Text=towerId
	b.MouseButton1Click:Connect(function() selectedTower = towerId end)
end

local summonRoll = Instance.new("TextButton", summonGui); summonRoll.Text="Призвать за 100"; summonRoll.Size=UDim2.fromScale(0.3,0.12); summonRoll.Position=UDim2.fromScale(0.35,0.8)
local summonClose = Instance.new("TextButton", summonGui); summonClose.Text="X"; summonClose.Size=UDim2.fromScale(0.08,0.1); summonClose.Position=UDim2.fromScale(0.9,0.02)

startBtn.MouseButton1Click:Connect(function() StartGameRequest:FireServer() end)
summonBtn.MouseButton1Click:Connect(function() summonGui.Visible=true end)
summonClose.MouseButton1Click:Connect(function() summonGui.Visible=false end)
summonRoll.MouseButton1Click:Connect(function() SummonUnitRequest:FireServer() end)

UIS.InputBegan:Connect(function(input,gp)
	if gp or not selectedTower then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local cam = workspace.CurrentCamera
		local pos = UIS:GetMouseLocation()
		local ray = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Whitelist; params.FilterDescendantsInstances = {workspace:WaitForChild("TD_Map"):WaitForChild("TowerZones")}
		local result = workspace:Raycast(ray.Origin, ray.Direction*500, params)
		if result and result.Instance then PlaceTowerRequest:FireServer(selectedTower, result.Instance.Name) end
	end
end)

UpdateHud.OnClientEvent:Connect(function(data)
	coins.Text = "Монеты: " .. (data.Coins or 0)
	wave.Text = string.format("Волна: %d | Враги: %d", data.Wave or 0, data.EnemiesLeft or 0)
	base.Text = "База HP: " .. (data.BaseHealth or 0)
	startBtn.Visible = not data.MatchActive
end)

NotifyPlayer.OnClientEvent:Connect(function(msg)
	local lbl = Instance.new("TextLabel", notify)
	lbl.Size = UDim2.fromScale(1,0.35); lbl.Position=UDim2.fromScale(0,1); lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.BackgroundTransparency=0.3; lbl.TextColor3=Color3.new(1,1,1); lbl.TextScaled=true; lbl.Text=tostring(msg)
	TweenService:Create(lbl, TweenInfo.new(0.25), {Position = UDim2.fromScale(0,0)}):Play()
	task.delay(2.6, function() if lbl.Parent then lbl:Destroy() end end)
end)
