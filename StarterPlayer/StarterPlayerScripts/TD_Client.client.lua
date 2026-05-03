local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("TD_Remotes")

local LobbySummonRequest=remotes:WaitForChild("LobbySummonRequest")
local LobbyInventoryRequest=remotes:WaitForChild("LobbyInventoryRequest")
local LobbyEquipRequest=remotes:WaitForChild("LobbyEquipRequest")
local LobbyPlayRequest=remotes:WaitForChild("LobbyPlayRequest")
local MatchPlaceUnitRequest=remotes:WaitForChild("MatchPlaceUnitRequest")
local MatchUpgradeUnitRequest=remotes:WaitForChild("MatchUpgradeUnitRequest")
local UpdateLobbyGui=remotes:WaitForChild("UpdateLobbyGui")
local UpdateMatchGui=remotes:WaitForChild("UpdateMatchGui")
local Notify=remotes:WaitForChild("Notify")
local PlayEffect=remotes:WaitForChild("PlayEffect")

local g=Instance.new("ScreenGui", player:WaitForChild("PlayerGui")); g.Name="TD_GUI"; g.ResetOnSpawn=false
local top=Instance.new("Frame",g); top.Size=UDim2.fromScale(1,0.12); top.BackgroundTransparency=1
local money=Instance.new("TextLabel",top); money.Size=UDim2.fromScale(0.25,0.7); money.Position=UDim2.fromScale(0.01,0.15); money.BackgroundTransparency=0.2; money.TextScaled=true
local wave=money:Clone(); wave.Parent=top; wave.Position=UDim2.fromScale(0.28,0.15)
local base=money:Clone(); base.Parent=top; base.Position=UDim2.fromScale(0.55,0.15)
local timer=money:Clone(); timer.Parent=top; timer.Position=UDim2.fromScale(0.78,0.15)
local menu=Instance.new("Frame",g); menu.Size=UDim2.fromScale(0.42,0.18); menu.Position=UDim2.fromScale(0.29,0.78); menu.BackgroundTransparency=0.25
local function mkBtn(txt,x) local b=Instance.new("TextButton",menu); b.Text=txt;b.TextScaled=true;b.Size=UDim2.fromScale(0.31,0.8);b.Position=UDim2.fromScale(x,0.1); return b end
local playBtn=mkBtn("Играть",0.02) local invBtn=mkBtn("Инвентарь",0.345) local sumBtn=mkBtn("Призыв",0.67)
local inv=Instance.new("Frame",g); inv.Size=UDim2.fromScale(0.5,0.55); inv.Position=UDim2.fromScale(0.25,0.2); inv.Visible=false
local summon=inv:Clone(); summon.Parent=g; summon.Visible=false
local matchPanel=Instance.new("Frame",g); matchPanel.Size=UDim2.fromScale(0.9,0.14); matchPanel.Position=UDim2.fromScale(0.05,0.85); matchPanel.Visible=false
local towerInfo=Instance.new("Frame",g); towerInfo.Size=UDim2.fromScale(0.3,0.26); towerInfo.Position=UDim2.fromScale(0.68,0.58); towerInfo.Visible=false
local notify=Instance.new("TextLabel",g); notify.Size=UDim2.fromScale(0.4,0.07); notify.Position=UDim2.fromScale(0.3,0.02); notify.Visible=false; notify.TextScaled=true

local state={LobbyCoins=0,Inventory={},Equipped={},SummonCost=50,Placed={},Selecting=nil,SelectedTowerId=nil}
local function tempMsg(t)
	notify.Text=t; notify.Visible=true; notify.TextTransparency=1
	TweenService:Create(notify,TweenInfo.new(0.2),{TextTransparency=0}):Play(); task.delay(2,function() TweenService:Create(notify,TweenInfo.new(0.3),{TextTransparency=1}):Play(); task.wait(0.3); notify.Visible=false end)
end
local function refreshInventory()
	inv:ClearAllChildren(); local layout=Instance.new("UIGridLayout",inv); layout.CellSize=UDim2.fromScale(0.3,0.18)
	for _,u in ipairs(state.Inventory) do local b=Instance.new("TextButton",inv); local eq=false for _,e in ipairs(state.Equipped) do if e==u then eq=true end end; b.Text=u..(eq and " [E]" or ""); b.TextScaled=true; b.MouseButton1Click:Connect(function() LobbyEquipRequest:FireServer(u, not eq) end) end
end
local function refreshMatchPanel()
	matchPanel:ClearAllChildren(); local layout=Instance.new("UIListLayout",matchPanel); layout.FillDirection=Enum.FillDirection.Horizontal
	for _,u in ipairs(state.Equipped) do local b=Instance.new("TextButton",matchPanel); b.Size=UDim2.fromScale(0.24,0.9); b.Text=u; b.TextScaled=true; b.MouseButton1Click:Connect(function() state.Selecting=u; tempMsg("Выбран "..u..". Нажмите на зеленую зону") end) end
end

UpdateLobbyGui.OnClientEvent:Connect(function(data)
	for k,v in pairs(data) do state[k]=v end
	money.Text="Лобби: "..state.LobbyCoins
	refreshInventory(); refreshMatchPanel()
end)
UpdateMatchGui.OnClientEvent:Connect(function(data)
	money.Text="Матч: "..(data.MatchCoins or 0); wave.Text="Волна: "..(data.Wave or 0); base.Text="База HP: "..(data.BaseHP or 100); timer.Text="След. волна: "..(data.WaveTimer or 0)
	if data.Equipped then state.Equipped=data.Equipped; refreshMatchPanel() end
	if data.Placed then state.Placed=data.Placed end
	matchPanel.Visible=true
end)
Notify.OnClientEvent:Connect(tempMsg)
PlayEffect.OnClientEvent:Connect(function(effect,a,b)
	if effect=="SummonReveal" then
		summon.Visible=true; summon.BackgroundTransparency=1; summon:ClearAllChildren()
		local card=Instance.new("TextLabel",summon); card.Size=UDim2.fromScale(0.4,0.4); card.Position=UDim2.fromScale(0.3,0.3); card.Text=a.Name.."\n"..a.Rarity; card.TextScaled=true
		card.Rotation=-20; card.Size=UDim2.fromScale(0.2,0.2)
		TweenService:Create(summon,TweenInfo.new(0.2),{BackgroundTransparency=0.25}):Play(); TweenService:Create(card,TweenInfo.new(0.45,Enum.EasingStyle.Back),{Rotation=0,Size=UDim2.fromScale(0.5,0.5)}):Play()
		task.delay(1.2,function() summon.Visible=false end)
	elseif effect=="UnitShoot" then local beam=Instance.new("Part",workspace); beam.Anchored=true; beam.CanCollide=false; beam.Material=Enum.Material.Neon; local p1,p2=a,b; local d=(p2-p1); beam.Size=Vector3.new(0.2,0.2,d.Magnitude); beam.CFrame=CFrame.lookAt(p1,p2)*CFrame.new(0,0,-d.Magnitude/2); task.delay(0.07,function() beam:Destroy() end)
	elseif effect=="PlaceFlash" or effect=="UpgradePulse" or effect=="EnemyDeath" then local p=Instance.new("Part",workspace); p.Shape=Enum.PartType.Ball; p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon; p.Color=Color3.new(1,1,0); p.Size=Vector3.new(1,1,1); p.Position=a; TweenService:Create(p,TweenInfo.new(0.4),{Size=Vector3.new(6,6,6),Transparency=1}):Play(); task.delay(0.4,function() p:Destroy() end) end
end)

playBtn.MouseButton1Click:Connect(function() LobbyPlayRequest:FireServer() end)
invBtn.MouseButton1Click:Connect(function() inv.Visible=not inv.Visible; if inv.Visible then LobbyInventoryRequest:FireServer() end end)
sumBtn.MouseButton1Click:Connect(function() LobbySummonRequest:FireServer() end)

local mouse=player:GetMouse()
mouse.Button1Down:Connect(function()
	if mouse.Target and mouse.Target.Parent and mouse.Target.Parent.Name=="PlacementZones" and state.Selecting then MatchPlaceUnitRequest:FireServer(state.Selecting, mouse.Target.Name); state.Selecting=nil end
	if mouse.Target and mouse.Target.Parent and mouse.Target.Parent:IsA("Model") then
		for id,data in pairs(state.Placed) do if data.Zone and mouse.Target.Name==data.Unit then state.SelectedTowerId=id end end
	end
end)

local up=Instance.new("TextButton",towerInfo); up.Size=UDim2.fromScale(0.9,0.3); up.Position=UDim2.fromScale(0.05,0.65); up.Text="Улучшить"; up.TextScaled=true
up.MouseButton1Click:Connect(function() if state.SelectedTowerId then MatchUpgradeUnitRequest:FireServer(state.SelectedTowerId) end end)

LobbyInventoryRequest:FireServer()
