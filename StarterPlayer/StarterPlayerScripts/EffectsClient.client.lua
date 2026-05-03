local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local playEffect = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayEffect")

local function pulse(position, color)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.Shape = Enum.PartType.Ball; p.Material=Enum.Material.Neon
	p.Color = color; p.Size=Vector3.new(1,1,1); p.Position=position; p.Parent=workspace
	TweenService:Create(p, TweenInfo.new(0.35), {Size=Vector3.new(6,6,6), Transparency=1}):Play()
	Debris:AddItem(p,0.4)
end

playEffect.OnClientEvent:Connect(function(effectType, payload)
	if effectType == "EnemySpawn" and payload.Enemy and payload.Enemy.PrimaryPart then
		pulse(payload.Enemy.PrimaryPart.Position, Color3.fromRGB(100,255,255))
	elseif effectType == "EnemyHit" and payload.Enemy and payload.Enemy.PrimaryPart then
		pulse(payload.Enemy.PrimaryPart.Position, Color3.fromRGB(255,80,80))
	elseif effectType == "EnemyDeath" and payload.Position then
		pulse(payload.Position, Color3.fromRGB(255,180,80))
	elseif effectType == "PlaceTower" and payload.Position then
		pulse(payload.Position, Color3.fromRGB(80,255,120))
	elseif effectType == "TowerShoot" and payload.Tower and payload.Enemy and payload.Tower.PrimaryPart and payload.Enemy.PrimaryPart then
		local a,b = payload.Tower.PrimaryPart.Position, payload.Enemy.PrimaryPart.Position
		local beam = Instance.new("Part")
		beam.Anchored=true; beam.CanCollide=false; beam.Material=Enum.Material.Neon; beam.Color=Color3.fromRGB(255,255,150)
		beam.Size = Vector3.new(0.2,0.2,(a-b).Magnitude)
		beam.CFrame = CFrame.lookAt((a+b)/2,b)
		beam.Parent=workspace; Debris:AddItem(beam,0.1)
	elseif effectType == "SummonReveal" then
		-- place for future card reveal animations via TweenService / AnimationController
	end
end)
