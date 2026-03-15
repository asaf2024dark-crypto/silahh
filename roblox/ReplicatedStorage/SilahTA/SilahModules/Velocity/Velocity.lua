local ModuleComponents = require(script.Parent.Parent:WaitForChild("ModuleComponents"))

local Velocity = {
	Settings = {},
}

for _, valueObj in ipairs(script.Parent:WaitForChild("Settings"):WaitForChild("VelocitySettings"):GetChildren()) do
	if valueObj:IsA("ValueBase") then
		Velocity.Settings[valueObj.Name] = valueObj.Value
	end
end

local API = {}

function API.GetService(_, name)
	ModuleComponents:params({ "string" }, { name }, 1)
	local serviceModule = script.Parent:WaitForChild("Services"):FindFirstChild(name)
	if not serviceModule then
		ModuleComponents:errorf("%s is not a valid service!", name)
	end
	return require(serviceModule)
end

function API.AddService(_, moduleScript)
	ModuleComponents:params({ "Instance" }, { moduleScript }, 1)
	ModuleComponents:assertf(moduleScript:IsA("ModuleScript"), "%s is not a module!", moduleScript.Name)
	moduleScript:Clone().Parent = script.Parent:WaitForChild("Services")
end

function API.GetModule(_, moduleNameOrId)
	local valid = typeof(moduleNameOrId) == "string" or typeof(moduleNameOrId) == "number"
	ModuleComponents:assertf(valid, "%s is not valid, either give the string name or the id!", tostring(moduleNameOrId))

	if typeof(moduleNameOrId) == "string" then
		local obj = script.Parent:WaitForChild("ExtraModules"):FindFirstChild(moduleNameOrId)
		if not obj then
			ModuleComponents:errorf("%s module doesn't exist!", moduleNameOrId)
		end
		if obj:IsA("NumberValue") or obj:IsA("IntValue") then
			return require(obj.Value)
		end
		if obj:IsA("ModuleScript") then
			return require(obj)
		end
		ModuleComponents:errorf("%s is not a NumberValue/IntValue or ModuleScript!", moduleNameOrId)
	end

	return require(moduleNameOrId)
end

function API.AddModule(_, instance)
	ModuleComponents:params({ "Instance" }, { instance }, 1)
	if instance:IsA("NumberValue") or instance:IsA("IntValue") or instance:IsA("ModuleScript") then
		instance.Parent = script.Parent:WaitForChild("ExtraModules")
		return
	end
	ModuleComponents:errorf("%s is not a valid Instance class", tostring(instance))
end

function Velocity:GetVersion()
	return "Velocity - The Framework speeding up development!\nVersion: " .. script.Parent:WaitForChild("Misc"):WaitForChild("Version").Value
end

function Velocity:SetSetting(name, newValue)
	ModuleComponents:params({ "string" }, { name }, 1)
	local setting = script.Parent:WaitForChild("Settings"):FindFirstChild(name, true)
	ModuleComponents:assertf(setting and setting:IsA("ValueBase"), "%s is not a valid setting!", name)
	setting.Value = newValue
	self.Settings[name] = newValue
end

function Velocity:GetSetting(name)
	ModuleComponents:params({ "string" }, { name }, 1)
	local setting = script.Parent:WaitForChild("Settings"):FindFirstChild(name, true)
	ModuleComponents:assertf(setting and setting:IsA("ValueBase"), "%s is not a valid setting!", name)
	return setting.Value
end

local function ensureFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ensureBool(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("BoolValue") then
		return existing
	end
	local value = Instance.new("BoolValue")
	value.Name = name
	value.Parent = parent
	return value
end

local function handleRespawn(settings)
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local InbuiltEvents = ensureFolder(ReplicatedStorage, "InbuiltEvents")

	local playerAdded = InbuiltEvents:FindFirstChild("playerAdded") or Instance.new("BindableEvent")
	playerAdded.Name = "playerAdded"
	playerAdded.Parent = InbuiltEvents

	local characterAdded = InbuiltEvents:FindFirstChild("characterAdded") or Instance.new("BindableEvent")
	characterAdded.Name = "characterAdded"
	characterAdded.Parent = InbuiltEvents

	Players.CharacterAutoLoads = false
	Players.PlayerAdded:Connect(function(player)
		playerAdded:Fire(player)
		task.wait(settings.RespawnTime or 3)
		player.CharacterAdded:Connect(function(character)
			characterAdded:Fire(player, character)
			character:WaitForChild("Humanoid").Died:Connect(function()
				task.wait(settings.RespawnTime or 3)
				player:LoadCharacter()
			end)
		end)
		player:LoadCharacter()
	end)
end

function Velocity:Init(enableRespawnHandler)
	local misc = script.Parent:WaitForChild("Misc")
	local alreadyInited = misc:WaitForChild("AlreadyInited")
	if alreadyInited.Value then
		return API
	end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	ensureFolder(ReplicatedStorage, "RemoteEvents")
	ensureFolder(ReplicatedStorage, "RemoteFunctions")
	ensureFolder(ReplicatedStorage, "BindableEvents")
	ensureFolder(ReplicatedStorage, "BindableFunctions")
	ensureFolder(ReplicatedStorage, "InbuiltEvents")
	local isHandling = ensureBool(ReplicatedStorage, "isHandling")

	alreadyInited.Value = true

	if self.Settings.PrintOnInit then
		print(self:GetVersion())
	end

	if enableRespawnHandler then
		handleRespawn(self.Settings)
		isHandling.Value = true
	end

	return API
end

return Velocity
