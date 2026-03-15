local ModuleComponents = require(script.Parent:WaitForChild("ModuleComponents"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not root then
	root = Instance.new("Folder")
	root.Name = "RemoteEvents"
	root.Parent = ReplicatedStorage
end

local RemoteEvents = {}

function RemoteEvents.new(name)
	ModuleComponents:params({ "string" }, { name }, 0)
	local event = root:FindFirstChild(name)
	if event and event:IsA("RemoteEvent") then
		return event
	end
	event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = root
	return event
end

function RemoteEvents.connect(name, shouldWait, callback)
	ModuleComponents:params({ "string", "boolean", "function" }, { name, shouldWait, callback }, 3)
	local event = shouldWait and root:WaitForChild(name) or root:FindFirstChild(name)
	if not event or not event:IsA("RemoteEvent") then
		ModuleComponents:errorf("RemoteEvent %s does not exist", name)
	end

	if RunService:IsServer() then
		return event.OnServerEvent:Connect(callback)
	end
	return event.OnClientEvent:Connect(callback)
end

function RemoteEvents.fire(name, shouldWait, targetOrFirstArg, ...)
	ModuleComponents:params({ "string", "boolean" }, { name, shouldWait }, 2)
	local event = shouldWait and root:WaitForChild(name) or root:FindFirstChild(name)
	if not event or not event:IsA("RemoteEvent") then
		ModuleComponents:errorf("RemoteEvent %s does not exist", name)
	end

	if RunService:IsServer() then
		if typeof(targetOrFirstArg) == "Instance" and targetOrFirstArg:IsA("Player") then
			event:FireClient(targetOrFirstArg, ...)
			return
		end
		if typeof(targetOrFirstArg) == "string" and string.lower(targetOrFirstArg) == "all" then
			event:FireAllClients(...)
			return
		end
		ModuleComponents:errorf("On server target must be Player or 'all'")
	else
		event:FireServer(targetOrFirstArg, ...)
	end
end

return RemoteEvents
