local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SilahTA = ReplicatedStorage:WaitForChild("SilahTA")
local SilahRemotes = SilahTA:WaitForChild("SilahRemotes")

local FireRemote = SilahRemotes:WaitForChild("Fire")
local DamageRemote = SilahRemotes:WaitForChild("Damage")

local TEAM_RULES = require(SilahTA:WaitForChild("SilahModules"):WaitForChild("TakimKurallari"))

local MAX_DISTANCE = 5000
local MIN_SHOT_INTERVAL = 0.05
local BASE_DAMAGE = {
	Auto = 20,
	Single = 20,
	Shotgun = 8,
	Tank = 80,
	TankMG = 12,
}

local lastShotAt = {}

local function isEnemy(attacker, victim)
	if not attacker.Team or not victim.Team then
		return true
	end
	local enemies = TEAM_RULES.Teams[attacker.Team.Name]
	if not enemies then
		return false
	end
	for _, teamName in ipairs(enemies) do
		if teamName == victim.Team.Name then
			return true
		end
	end
	return false
end

local function isToolOwnedByPlayer(player, tool)
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	return tool.Parent == character
end

local function validateRate(player, weaponType)
	local now = os.clock()
	local interval = MIN_SHOT_INTERVAL
	if weaponType == "Shotgun" then
		interval = 0.25
	elseif weaponType == "Tank" then
		interval = 1.2
	elseif weaponType == "TankMG" then
		interval = 0.08
	end

	local prev = lastShotAt[player]
	if prev and (now - prev) < interval then
		return false
	end
	lastShotAt[player] = now
	return true
end

local function getHumanoidFromHit(instance)
	if not instance then
		return nil, nil
	end
	local model = instance:FindFirstAncestorOfClass("Model")
	if not model then
		return nil, nil
	end
	return model:FindFirstChildOfClass("Humanoid"), model
end

local function getMuzzleOrigin(character, tool)
	local grip = tool:FindFirstChild("Grip")
	if grip and grip:IsA("BasePart") then
		local firePoint = grip:FindFirstChild("FirePoint")
		if firePoint and firePoint:IsA("Attachment") then
			return firePoint.WorldPosition
		end
		return grip.Position
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position
	end

	return nil
end

local function makeRaycastParams(player)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = true
	return params
end

FireRemote.OnServerEvent:Connect(function(player, targetPosition, tool, fireType)
	if typeof(targetPosition) ~= "Vector3" then
		return
	end
	if type(fireType) ~= "string" or not BASE_DAMAGE[fireType] then
		return
	end
	if not isToolOwnedByPlayer(player, tool) then
		return
	end
	if not validateRate(player, fireType) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local origin = getMuzzleOrigin(character, tool)
	if not origin then
		return
	end

	local direction = targetPosition - origin
	if direction.Magnitude <= 0 then
		return
	end
	if direction.Magnitude > MAX_DISTANCE then
		direction = direction.Unit * MAX_DISTANCE
	end

	local result = workspace:Raycast(origin, direction, makeRaycastParams(player))
	if not result then
		DamageRemote:FireClient(player, targetPosition, 0, nil, tool, origin, direction.Unit)
		return
	end

	local damage = 0
	local humanoid, hitModel = getHumanoidFromHit(result.Instance)
	if humanoid and humanoid.Health > 0 then
		local victimPlayer = Players:GetPlayerFromCharacter(hitModel)
		local canApply = true
		if victimPlayer then
			canApply = isEnemy(player, victimPlayer)
		end

		if canApply then
			damage = BASE_DAMAGE[fireType]
			if result.Instance.Name == "Head" then
				damage *= 2
			end
			humanoid:TakeDamage(damage)
		end
	end

	DamageRemote:FireAllClients(result.Position, damage, result.Instance, tool, origin, direction.Unit)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotAt[player] = nil
end)
