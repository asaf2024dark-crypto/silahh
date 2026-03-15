local ModuleComponents = require(script.Parent:WaitForChild("ModuleComponents"))

local OtherFunctions = {}

local function instanceMatchesClasses(instance, classOrClasses)
	if typeof(classOrClasses) == "string" then
		return instance:IsA(classOrClasses)
	end
	if typeof(classOrClasses) == "table" then
		for _, className in ipairs(classOrClasses) do
			ModuleComponents:assertf(typeof(className) == "string", "%s is not a string in class table", tostring(className))
			if instance:IsA(className) then
				return true
			end
		end
		return false
	end
	ModuleComponents:errorf("class parameter must be string/table, got %s", typeof(classOrClasses))
end

function OtherFunctions:GetChildrenOfA(classOrClasses, parent)
	ModuleComponents:params({ "skip", "Instance" }, { classOrClasses, parent }, 2)
	local result = {}
	for _, child in ipairs(parent:GetChildren()) do
		if instanceMatchesClasses(child, classOrClasses) then
			table.insert(result, child)
		end
	end
	return result
end

function OtherFunctions:GetDescendantsOfA(classOrClasses, parent)
	ModuleComponents:params({ "skip", "Instance" }, { classOrClasses, parent }, 2)
	local result = {}
	for _, child in ipairs(parent:GetDescendants()) do
		if instanceMatchesClasses(child, classOrClasses) then
			table.insert(result, child)
		end
	end
	return result
end

function OtherFunctions:CreateWeld(parts, targetPart)
	ModuleComponents:params({ "skip", "Instance" }, { parts, targetPart }, 2)
	ModuleComponents:assertf(targetPart:IsA("BasePart"), "%s must be BasePart", tostring(targetPart))

	local created = {}
	local function createOne(part)
		ModuleComponents:assertf(typeof(part) == "Instance" and part:IsA("BasePart"), "%s must be BasePart", tostring(part))
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part
		weld.Part1 = targetPart
		weld.Parent = part
		table.insert(created, weld)
	end

	if typeof(parts) == "Instance" then
		createOne(parts)
	elseif typeof(parts) == "table" then
		for _, part in ipairs(parts) do
			createOne(part)
		end
	else
		ModuleComponents:errorf("parts must be BasePart or table")
	end

	return created
end

function OtherFunctions:GetPartsWeldedWith(basePart)
	ModuleComponents:params({ "Instance" }, { basePart }, 1)
	ModuleComponents:assertf(basePart:IsA("BasePart"), "%s must be BasePart", tostring(basePart))

	local result = {}
	for _, weld in ipairs(workspace:GetDescendants()) do
		if weld:IsA("Weld") or weld:IsA("WeldConstraint") then
			if weld.Part0 == basePart and weld.Part1 then
				table.insert(result, weld.Part1)
			elseif weld.Part1 == basePart and weld.Part0 then
				table.insert(result, weld.Part0)
			end
		end
	end
	return result
end

function OtherFunctions:GetFullObjectMass(rootPart)
	ModuleComponents:params({ "Instance" }, { rootPart }, 1)
	ModuleComponents:assertf(rootPart:IsA("BasePart"), "%s must be BasePart", tostring(rootPart))

	local mass = rootPart:GetMass()
	for _, part in ipairs(self:GetDescendantsOfA("BasePart", rootPart)) do
		mass += part:GetMass()
	end
	return mass
end

function OtherFunctions:VectorClamp(v, minVal, maxVal)
	ModuleComponents:params({ "Vector3", "number", "number" }, { v, minVal, maxVal }, 3)
	return Vector3.new(
		math.clamp(v.X, minVal, maxVal),
		math.clamp(v.Y, minVal, maxVal),
		math.clamp(v.Z, minVal, maxVal)
	)
end

function OtherFunctions:RandomVector(minVal, maxVal, seed)
	ModuleComponents:params({ "number", "number", "number" }, { minVal, maxVal, seed }, 0)
	local rng = Random.new(seed or math.floor(os.clock() * 1000))
	return Vector3.new(rng:NextNumber(minVal, maxVal), rng:NextNumber(minVal, maxVal), rng:NextNumber(minVal, maxVal))
end

function OtherFunctions:ColorClamp(c, minVal, maxVal)
	ModuleComponents:params({ "Color3", "number", "number" }, { c, minVal, maxVal }, 3)
	return Color3.new(
		math.clamp(c.R, minVal, maxVal),
		math.clamp(c.G, minVal, maxVal),
		math.clamp(c.B, minVal, maxVal)
	)
end

function OtherFunctions:RandomColor(minVal, maxVal, seed)
	ModuleComponents:params({ "number", "number", "number" }, { minVal, maxVal, seed }, 0)
	local rng = Random.new(seed or math.floor(os.clock() * 1000))
	return Color3.fromRGB(
		math.floor(rng:NextNumber(minVal, maxVal)),
		math.floor(rng:NextNumber(minVal, maxVal)),
		math.floor(rng:NextNumber(minVal, maxVal))
	)
end

function OtherFunctions:GetServerType()
	if game.PrivateServerOwnerId ~= 0 then
		return "VIP", game.PrivateServerOwnerId
	end
	if game.PrivateServerId ~= "" then
		return "Reserved"
	end
	return "Public"
end

return OtherFunctions
