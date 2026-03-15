local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SilahTA = ReplicatedStorage:WaitForChild("SilahTA")
local SilahRemotes = SilahTA:WaitForChild("SilahRemotes")

local FireRemote = SilahRemotes:WaitForChild("Fire")
local DamageRemote = SilahRemotes:WaitForChild("Damage")

local TEAM_RULES = require(SilahTA:WaitForChild("SilahModules"):WaitForChild("TakimKurallari"))

local MAX_DISTANCE = 5000
local MIN_SHOT_INTERVAL = 0.05

local lastShotAt = {}

local function canDamage(attacker, victim)
	if not attacker.Team or not victim.Team then
		return true
	end
	local blocked = TEAM_RULES.Teams[attacker.Team.Name]
	if not blocked then
		return true
	end
	for _, teamName in ipairs(blocked) do
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
	if not player.Character then
		return false
	end
	return tool.Parent == player.Character
end

local function validateRate(player)
	local now = os.clock()
	local prev = lastShotAt[player]
	if prev and (now - prev) < MIN_SHOT_INTERVAL then
		return false
	end
	lastShotAt[player] = now
	return true
end

local function getHumanoidFromHit(instance)
	if not instance then
		return nil
	end
	local model = instance:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return model:FindFirstChildOfClass("Humanoid"), model
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
	if not isToolOwnedByPlayer(player, tool) then
		return
	end
	if not validateRate(player) then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local origin = root.Position
	local direction = targetPosition - origin
	local distance = direction.Magnitude
	if distance <= 0 then
		return
	end
	if distance > MAX_DISTANCE then
		direction = direction.Unit * MAX_DISTANCE
	end

	local result = workspace:Raycast(origin, direction, makeRaycastParams(player))
	if not result then
		DamageRemote:FireClient(player, targetPosition, 0, Instance.new("Part"), nil, nil, nil)
		return
	end

	local humanoid, hitModel = getHumanoidFromHit(result.Instance)
	local damage = 0
	if humanoid and humanoid.Health > 0 then
		local victimPlayer = Players:GetPlayerFromCharacter(hitModel)
		if victimPlayer and canDamage(player, victimPlayer) then
			damage = fireType == "Shotgun" and 8 or 20
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
