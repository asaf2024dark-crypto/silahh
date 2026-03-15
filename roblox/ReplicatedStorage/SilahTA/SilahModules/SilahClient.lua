local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local SilahTA = ReplicatedStorage:WaitForChild("SilahTA")
local SilahRemotes = SilahTA:WaitForChild("SilahRemotes")
local SilahAssets = SilahTA:WaitForChild("SilahAssets")

local DamageRemote = SilahRemotes:WaitForChild("Damage")
local BulletTemplate = SilahAssets:WaitForChild("Bullet")

local Client = {}

local function getCrosshairTarget(ignoreList)
	local mousePos = game:GetService("UserInputService"):GetMouseLocation()
	local ray = CurrentCamera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList or {}
	local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
	if result then
		return result.Position
	end
	return ray.Origin + ray.Direction * 5000
end

function Client.CreateBullet(fromPos, toPos)
	if not fromPos or not toPos then
		return
	end
	local terrain = workspace:FindFirstChild("Terrain")
	if not terrain then
		return
	end

	local bullet = BulletTemplate:Clone()
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	a0.WorldPosition = fromPos
	a1.WorldPosition = fromPos
	a0.Parent = terrain
	a1.Parent = terrain
	bullet.Attachment0 = a0
	bullet.Attachment1 = a1
	bullet.Parent = terrain

	local duration = math.max((fromPos - toPos).Magnitude / 1000, 0.03)
	TweenService:Create(a0, TweenInfo.new(duration, Enum.EasingStyle.Linear), { WorldPosition = toPos }):Play()
	local tailTween = TweenService:Create(a1, TweenInfo.new(duration * 2, Enum.EasingStyle.Linear), { WorldPosition = toPos })
	task.delay(0.02, function()
		tailTween:Play()
	end)

	Debris:AddItem(bullet, 10)
	Debris:AddItem(a0, 10)
	Debris:AddItem(a1, 10)
end

function Client.CastBullet(targetPosition, firePointAttachment, ownerPlayer, ownerCharacter, weaponType, effectPoint)
	if not targetPosition or not firePointAttachment or not ownerPlayer or not ownerCharacter then
		return
	end

	local origin = firePointAttachment.WorldPosition
	Client.CreateBullet(origin, targetPosition)
	if effectPoint and effectPoint:FindFirstChild("Fire") then
		effectPoint.Fire:Play()
	end

	local tool = firePointAttachment:FindFirstAncestorOfClass("Tool")
	if tool then
		SilahRemotes:WaitForChild("Fire"):FireServer(targetPosition, tool, weaponType)
	end
end

function Client.UIEfekts(worldPos, damage, hitPart)
	if not LocalPlayer then
		return
	end
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end
	local ui = playerGui:FindFirstChild("SilahTA")
	if not ui then
		return
	end

	local markerTemplate = ui:FindFirstChild("HitMarker")
	local damageTemplate = ui:FindFirstChild("Damage")
	if not markerTemplate or not damageTemplate then
		return
	end

	local marker = markerTemplate:Clone()
	local dmgLabel = damageTemplate:Clone()
	local point = CurrentCamera:WorldToScreenPoint(worldPos)
	local half = marker.AbsoluteSize.X * 0.5
	marker.Position = UDim2.new(0, point.X - half, 0, point.Y + half)
	dmgLabel.Position = UDim2.new(0, point.X - half, 0, point.Y - half)
	dmgLabel.Text = "-" .. tostring(damage)
	marker.Visible = true
	dmgLabel.Visible = true
	marker.Parent = markerTemplate.Parent
	dmgLabel.Parent = damageTemplate.Parent
	Debris:AddItem(marker, 0.12)
	Debris:AddItem(dmgLabel, 1)
end

DamageRemote.OnClientEvent:Connect(function(worldPos, damage, hitPart, _tool, fromPos)
	if fromPos and worldPos then
		Client.CreateBullet(fromPos, worldPos)
	end
	if damage and damage > 0 and worldPos then
		Client.UIEfekts(worldPos, damage, hitPart)
	end
end)

function Client.GetFireDirection(characterToIgnore)
	local ignore = {}
	if characterToIgnore then
		table.insert(ignore, characterToIgnore)
	end
	return getCrosshairTarget(ignore)
end

return Client
