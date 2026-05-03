local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartGameRequest = remotes:WaitForChild("StartGameRequest")
local PlaceTowerRequest = remotes:WaitForChild("PlaceTowerRequest")
local SummonUnitRequest = remotes:WaitForChild("SummonUnitRequest")

local gui = player:WaitForChild("PlayerGui"):FindFirstChild("TDGui") or Instance.new("ScreenGui")
gui.Name = "TDGui"; gui.ResetOnSpawn = false; gui.Parent = player.PlayerGui

local hud = Instance.new("Frame", gui); hud.Name="MainHud"; hud.Size=UDim2.fromScale(1,1); hud.BackgroundTransparency=1
local coins = Instance.new("TextLabel", hud); coins.Size=UDim2.fromScale(0.2,0.06); coins.Position=UDim2.fromScale(0.01,0.02); coins.TextScaled=true
local wave = Instance.new("TextLabel", hud); wave.Size=UDim2.fromScale(0.28,0.06); wave.Position=UDim2.fromScale(0.36,0.02); wave.TextScaled=true
local base = Instance.new("TextLabel", hud); base.Size=UDim2.fromScale(0.2,0.06); base.Position=UDim2.fromScale(0.79,0.02); base.TextScaled=true
local startBtn = Instance.new("TextButton", hud); startBtn.Text="Начать игру"; startBtn.Size=UDim2.fromScale(0.18,0.07); startBtn.Position=UDim2.fromScale(0.41,0.11)
local summonBtn = Instance.new("TextButton", hud); summonBtn.Text="Призыв"; summonBtn.Size=UDim2.fromScale(0.14,0.07); summonBtn.Position=UDim2.fromScale(0.84,0.86)

local shop = Instance.new("Frame", gui); shop.Size=UDim2.fromScale(0.52,0.15); shop.Position=UDim2.fromScale(0.24,0.82); shop.BackgroundColor3=Color3.fromRGB(30,30,30); shop.BackgroundTransparency=0.2
local notify = Instance.new("Frame", gui); notify.Size=UDim2.fromScale(0.3,0.2); notify.Position=UDim2.fromScale(0.68,0.1); notify.BackgroundTransparency=1
local summonGui = Instance.new("Frame", gui); summonGui.Size=UDim2.fromScale(0.8,0.6); summonGui.Position=UDim2.fromScale(0.1,0.2); summonGui.Visible=false; summonGui.BackgroundColor3=Color3.fromRGB(20,20,20)
local summonRoll = Instance.new("TextButton", summonGui); summonRoll.Text="Призвать за 100"; summonRoll.Size=UDim2.fromScale(0.3,0.12); summonRoll.Position=UDim2.fromScale(0.35,0.8)
local closeBtn = Instance.new("TextButton", summonGui); closeBtn.Text="X"; closeBtn.Size=UDim2.fromScale(0.08,0.1); closeBtn.Position=UDim2.fromScale(0.9,0.02)

local selectedTower
for i,tid in ipairs({"ScoutTower","SniperTower","CannonTower"}) do local b=Instance.new("TextButton",shop); b.Size=UDim2.fromScale(0.31,0.84); b.Position=UDim2.fromScale((i-1)*0.33+0.01,0.08); b.Text=tid; b.MouseButton1Click:Connect(function() selectedTower = tid end) end

local function notifyMsg(msg)
	local lbl = Instance.new("TextLabel", notify)
	lbl.Size=UDim2.fromScale(1,0.35); lbl.Position=UDim2.fromScale(0,1); lbl.Text=tostring(msg); lbl.TextScaled=true; lbl.BackgroundColor3=Color3.new(0,0,0); lbl.BackgroundTransparency=0.25; lbl.TextColor3=Color3.new(1,1,1)
	TweenService:Create(lbl, TweenInfo.new(0.25), {Position=UDim2.fromScale(0,0)}):Play(); task.delay(2.5, function() lbl:Destroy() end)
end

local function pulse(pos,color)
	local p=Instance.new("Part",workspace); p.Anchored=true; p.CanCollide=false; p.Shape=Enum.PartType.Ball; p.Material=Enum.Material.Neon; p.Size=Vector3.new(1,1,1); p.Position=pos; p.Color=color
	TweenService:Create(p, TweenInfo.new(0.35), {Size=Vector3.new(6,6,6), Transparency=1}):Play(); Debris:AddItem(p,0.4)
end

startBtn.MouseButton1Click:Connect(function() StartGameRequest:FireServer() end)
summonBtn.MouseButton1Click:Connect(function() summonGui.Visible=true end)
closeBtn.MouseButton1Click:Connect(function() summonGui.Visible=false end)
summonRoll.MouseButton1Click:Connect(function() SummonUnitRequest:FireServer() end)

UIS.InputBegan:Connect(function(input,gp)
	if gp or not selectedTower then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local cam = workspace.CurrentCamera
		local m = UIS:GetMouseLocation()
		local ray = cam:ViewportPointToRay(m.X,m.Y)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Whitelist; rp.FilterDescendantsInstances = {workspace:WaitForChild("TD_Map"):WaitForChild("TowerZones")}
		local r = workspace:Raycast(ray.Origin, ray.Direction * 500, rp)
		if r and r.Instance then PlaceTowerRequest:FireServer(selectedTower, r.Instance.Name) end
	end
end)

remotes.UpdateHud.OnClientEvent:Connect(function(d)
	coins.Text = "Монеты: "..(d.Coins or 0)
	wave.Text = string.format("Волна: %d | Враги: %d", d.Wave or 0, d.EnemiesLeft or 0)
	base.Text = "HP Базы: "..(d.BaseHealth or 0)
	startBtn.Visible = not d.MatchActive
end)
remotes.NotifyPlayer.OnClientEvent:Connect(notifyMsg)
remotes.PlayEffect.OnClientEvent:Connect(function(t,p)
	if t=="EnemySpawn" and p.Enemy and p.Enemy.PrimaryPart then pulse(p.Enemy.PrimaryPart.Position, Color3.fromRGB(100,255,255))
	elseif t=="EnemyHit" and p.Enemy and p.Enemy.PrimaryPart then pulse(p.Enemy.PrimaryPart.Position, Color3.fromRGB(255,90,90))
	elseif t=="EnemyDeath" and p.Position then pulse(p.Position, Color3.fromRGB(255,180,90))
	elseif t=="PlaceTower" and p.Position then pulse(p.Position, Color3.fromRGB(80,255,120))
	elseif t=="TowerShoot" and p.Tower and p.Enemy and p.Tower.PrimaryPart and p.Enemy.PrimaryPart then
		local a,b = p.Tower.PrimaryPart.Position, p.Enemy.PrimaryPart.Position
		local beam = Instance.new("Part", workspace); beam.Anchored=true; beam.CanCollide=false; beam.Material=Enum.Material.Neon; beam.Color=Color3.fromRGB(255,255,160); beam.Size=Vector3.new(0.2,0.2,(a-b).Magnitude); beam.CFrame = CFrame.lookAt((a+b)/2,b)
		Debris:AddItem(beam,0.1)
	end
end)
