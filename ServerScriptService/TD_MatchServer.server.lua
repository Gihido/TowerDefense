local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local remotes = ReplicatedStorage:WaitForChild("TD_Remotes")
local PlaceReq = remotes:WaitForChild("MatchPlaceUnitRequest")
local UpgradeReq = remotes:WaitForChild("MatchUpgradeUnitRequest")
local SelectReq = remotes:WaitForChild("MatchSelectUnitRequest")
local UpdateMatchGui = remotes:WaitForChild("UpdateMatchGui")
local Notify = remotes:WaitForChild("Notify")
local PlayEffect = remotes:WaitForChild("PlayEffect")

local UNIT_STATS = {
	Scout = {Damage=8,Range=22,AttackSpeed=1.2,Cost=100,SplashRadius=0,Desc="обычный стрелок"},
	Gunner = {Damage=15,Range=26,AttackSpeed=1.0,Cost=175,SplashRadius=0,Desc="быстрый стрелок"},
	Sniper = {Damage=45,Range=45,AttackSpeed=2.5,Cost=300,SplashRadius=0,Desc="дальняя атака"},
	Blaster = {Damage=30,Range=30,AttackSpeed=1.8,Cost=450,SplashRadius=10,Desc="урон по области"},
}
local ENEMY = {Normal={HP=40,Speed=8,Reward=20,DamageToBase=5,Color=Color3.fromRGB(180,180,180)},Fast={HP=30,Speed=13,Reward=25,DamageToBase=4,Color=Color3.fromRGB(80,200,255)},Tank={HP=140,Speed=5,Reward=50,DamageToBase=12,Color=Color3.fromRGB(120,90,60)},Boss={HP=700,Speed=4,Reward=250,DamageToBase=35,Color=Color3.fromRGB(255,60,60)}}
local WAVES = {
	{{"Normal",6}},{{"Normal",10}},{{"Normal",8},{"Fast",3}},{{"Normal",12},{"Fast",5}},{{"Tank",5},{"Normal",10}},
	{{"Fast",8},{"Tank",6}},{{"Normal",15},{"Fast",10},{"Tank",4}},{{"Tank",8},{"Fast",12}},{{"Normal",20},{"Fast",12},{"Tank",8}},{{"Boss",1},{"Tank",12},{"Fast",15}},
}

local map = workspace:FindFirstChild("TD_Map") or Instance.new("Folder", workspace); map.Name = "TD_Map"
local function ensurePart(name,size,cf,color,parent,transparency)
	local p = parent:FindFirstChild(name) or Instance.new("Part")
	p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.CanCollide=true;p.Color=color;p.Transparency=transparency or 0;p.Parent=parent
	return p
end
ensurePart("Floor", Vector3.new(240,1,180), CFrame.new(0,0,0), Color3.fromRGB(90,90,90), map)
local enemySpawn = ensurePart("EnemySpawn", Vector3.new(8,1,8), CFrame.new(-100,1,-50), Color3.fromRGB(255,0,0), map, 0.4)
local base = ensurePart("Base", Vector3.new(12,12,12), CFrame.new(100,6,50), Color3.fromRGB(20,120,255), map)
local matchSpawn = ensurePart("MatchSpawn", Vector3.new(8,1,8), CFrame.new(-90,1,60), Color3.fromRGB(255,255,0), map, 0.4)
local wpFolder = map:FindFirstChild("Waypoints") or Instance.new("Folder", map); wpFolder.Name="Waypoints"
for i,pos in ipairs({Vector3.new(-80,1,-50),Vector3.new(-40,1,-20),Vector3.new(0,1,-5),Vector3.new(40,1,15),Vector3.new(70,1,35),Vector3.new(95,1,50)}) do ensurePart(tostring(i),Vector3.new(2,2,2),CFrame.new(pos),Color3.fromRGB(255,255,255),wpFolder,0.7) end
local zFolder = map:FindFirstChild("PlacementZones") or Instance.new("Folder", map); zFolder.Name="PlacementZones"
for i,pos in ipairs({Vector3.new(-60,1,-35),Vector3.new(-20,1,-28),Vector3.new(10,1,10),Vector3.new(30,1,-10),Vector3.new(55,1,25),Vector3.new(85,1,20)}) do local z=ensurePart("Zone"..i,Vector3.new(10,1,10),CFrame.new(pos),Color3.fromRGB(0,255,100),zFolder,0.5); z.CanCollide=false end

local state={BaseHP=100,Wave=0,WaveTimer=10,Enemies={},Placed={},ZoneBusy={},Players={}}
local function pushAll()
	for p,d in pairs(state.Players) do
		UpdateMatchGui:FireClient(p,{BaseHP=state.BaseHP,Wave=state.Wave,WaveTimer=state.WaveTimer,MatchCoins=d.MatchCoins,Equipped=d.Equipped,Placed=d.PlacedClient})
	end
end
local function makeUnitModel(name,pos)
	local m=Instance.new("Model");m.Name=name
	local body=Instance.new("Part");body.Anchored=true;body.CanCollide=false;body.Parent=m
	local gun=Instance.new("Part");gun.Anchored=true;gun.CanCollide=false;gun.Parent=m;gun.Name="Gun"
	if name=="Scout" then body.Size=Vector3.new(2,3,2); body.Color=Color3.fromRGB(80,120,255); gun.Size=Vector3.new(0.6,0.6,2)
	elseif name=="Gunner" then body.Size=Vector3.new(2.3,3,2.3); body.Color=Color3.fromRGB(90,220,90); gun.Size=Vector3.new(2,0.4,2)
	elseif name=="Sniper" then body.Size=Vector3.new(2,5,2); body.Color=Color3.fromRGB(180,80,255); gun.Size=Vector3.new(0.5,0.5,4)
	else body.Size=Vector3.new(3,3.5,3); body.Color=Color3.fromRGB(255,150,60); gun.Size=Vector3.new(1,1,3.8) end
	body.Position=pos+Vector3.new(0,body.Size.Y/2,0); gun.Position=body.Position+Vector3.new(0,0,1.6); m.PrimaryPart=body; m.Parent=workspace
	return m
end
local function enemyModel(kind)
	local e=Instance.new("Part"); e.Size=Vector3.new(3,3,3); e.Anchored=true; e.CanCollide=false; e.Color=ENEMY[kind].Color; e.Material=Enum.Material.Neon; e.Position=enemySpawn.Position+Vector3.new(0,2,0); e.Parent=workspace; return e
end

Players.PlayerAdded:Connect(function(p)
	local lobby=_G.TD_LOBBY_SESSION and _G.TD_LOBBY_SESSION[p]
	state.Players[p]={MatchCoins=300,Equipped=lobby and lobby.Equipped or {"Scout"},PlacedClient={}}
	p.CharacterAdded:Connect(function(c) task.wait(0.2); local hrp=c:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame=matchSpawn.CFrame+Vector3.new(0,3,0) end end)
	pushAll()
end)
Players.PlayerRemoving:Connect(function(p) state.Players[p]=nil end)

PlaceReq.OnServerEvent:Connect(function(p,unit,zoneName)
	local d=state.Players[p]; if not d then return end
	local z=zFolder:FindFirstChild(zoneName); local s=UNIT_STATS[unit]
	if not z or not s then return end
	if state.ZoneBusy[zoneName] then return end
	local eq=false for _,u in ipairs(d.Equipped) do if u==unit then eq=true end end if not eq then return end
	if d.MatchCoins<s.Cost then Notify:FireClient(p,"Не хватает монет матча") return end
	d.MatchCoins-=s.Cost; state.ZoneBusy[zoneName]=true
	local model=makeUnitModel(unit,z.Position)
	local id=tostring(os.clock())..p.UserId
	state.Placed[id]={Owner=p,Unit=unit,Zone=zoneName,Model=model,Level=1,Damage=s.Damage,Range=s.Range,AttackSpeed=s.AttackSpeed,UpgradeCost=math.floor(s.Cost*0.9),Last=0,SplashRadius=s.SplashRadius}
	d.PlacedClient[id]={Id=id,Unit=unit,Level=1,Damage=s.Damage,Range=s.Range,AttackSpeed=s.AttackSpeed,UpgradeCost=math.floor(s.Cost*0.9),Zone=zoneName}
	PlayEffect:FireAllClients("PlaceFlash", z.Position, unit)
	pushAll()
end)
UpgradeReq.OnServerEvent:Connect(function(p,id)
	local d=state.Players[p]; local t=state.Placed[id]; if not d or not t or t.Owner~=p then return end
	if t.Level>=5 then return end
	if d.MatchCoins<t.UpgradeCost then Notify:FireClient(p,"Не хватает монет на улучшение") return end
	d.MatchCoins-=t.UpgradeCost; t.Level+=1; t.Damage*=1.35; t.Range+=3; t.AttackSpeed*=0.92; t.UpgradeCost=math.floor(t.UpgradeCost*1.6)
	local c=d.PlacedClient[id]; if c then c.Level=t.Level;c.Damage=t.Damage;c.Range=t.Range;c.AttackSpeed=t.AttackSpeed;c.UpgradeCost=t.UpgradeCost end
	PlayEffect:FireAllClients("UpgradePulse", t.Model.PrimaryPart.Position, t.Level)
	pushAll()
end)

local function spawnEnemy(kind)
	local e=enemyModel(kind); local dat=ENEMY[kind]
	table.insert(state.Enemies,{Model=e,Kind=kind,HP=dat.HP,MaxHP=dat.HP,Speed=dat.Speed,Reward=dat.Reward,DamageToBase=dat.DamageToBase,WP=1})
	PlayEffect:FireAllClients("EnemySpawn", e.Position)
end

task.spawn(function()
	while task.wait(1) do
		if state.BaseHP<=0 then continue end
		if state.Wave>=#WAVES then continue end
		state.WaveTimer-=1; pushAll()
		if state.WaveTimer<=0 then
			state.Wave+=1; state.WaveTimer=10
			for p,d in pairs(state.Players) do d.MatchCoins += 50 + state.Wave*10 end
			pushAll()
			for _,group in ipairs(WAVES[state.Wave]) do for i=1,group[2] do spawnEnemy(group[1]); task.wait(0.55) end end
			if state.Wave==#WAVES then task.delay(45,function() if state.BaseHP>0 then Notify:FireAllClients("Победа!"); for p,_ in pairs(state.Players) do if _G.TD_LOBBY_SESSION and _G.TD_LOBBY_SESSION[p] then _G.TD_LOBBY_SESSION[p].LobbyCoins += 150 end end end end) end
		end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for i=#state.Enemies,1,-1 do
		local e=state.Enemies[i]
		if e.HP<=0 or not e.Model.Parent then table.remove(state.Enemies,i) else
			local wp=wpFolder:FindFirstChild(tostring(e.WP)); if wp then
				local dir=wp.Position-e.Model.Position; local dist=dir.Magnitude
				if dist<1 then e.WP+=1 else e.Model.Position += dir.Unit*math.min(dist,e.Speed*dt) end
			else state.BaseHP-=e.DamageToBase; e.Model:Destroy(); table.remove(state.Enemies,i); if state.BaseHP<=0 then Notify:FireAllClients("Поражение") end end
		end
	end
	for id,t in pairs(state.Placed) do
		if tick()-t.Last >= t.AttackSpeed and t.Model and t.Model.PrimaryPart then
			local nearest,nd
			for _,e in ipairs(state.Enemies) do local d=(e.Model.Position-t.Model.PrimaryPart.Position).Magnitude; if d<=t.Range and (not nd or d<nd) then nearest=e;nd=d end end
			if nearest then t.Last=tick(); t.Model:SetPrimaryPartCFrame(CFrame.lookAt(t.Model.PrimaryPart.Position, nearest.Model.Position)); PlayEffect:FireAllClients("UnitShoot", t.Model.Gun.Position, nearest.Model.Position)
				if t.SplashRadius and t.SplashRadius>0 then for _,e in ipairs(state.Enemies) do if (e.Model.Position-nearest.Model.Position).Magnitude<=t.SplashRadius then e.HP-=t.Damage end end else nearest.HP-=t.Damage end
				for i=#state.Enemies,1,-1 do local e=state.Enemies[i]; if e.HP<=0 then for p,d in pairs(state.Players) do d.MatchCoins += e.Reward end; PlayEffect:FireAllClients("EnemyDeath", e.Model.Position); e.Model:Destroy(); table.remove(state.Enemies,i); pushAll() end end
			end
		end
	end
end)
