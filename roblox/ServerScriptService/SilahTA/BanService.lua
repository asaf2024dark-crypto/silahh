local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BanService = {
	BanDatastoreName = "SilahBans",
	BanDefaultReason = "Kurallara aykırı davranış",
}

local inbuiltEvents = ReplicatedStorage:FindFirstChild("InbuiltEvents")
if not inbuiltEvents then
	inbuiltEvents = Instance.new("Folder")
	inbuiltEvents.Name = "InbuiltEvents"
	inbuiltEvents.Parent = ReplicatedStorage
end

local kickedEvent = inbuiltEvents:FindFirstChild("kickedBannedPlayer")
if not kickedEvent then
	kickedEvent = Instance.new("BindableEvent")
	kickedEvent.Name = "kickedBannedPlayer"
	kickedEvent.Parent = inbuiltEvents
end

local function getKey(userId)
	return "ban:" .. tostring(userId)
end

local function getStore(self)
	return DataStoreService:GetDataStore(self.BanDatastoreName)
end

function BanService:CheckBan(player)
	local store = getStore(self)
	local ok, data = pcall(function()
		return store:GetAsync(getKey(player.UserId))
	end)

	if not ok then
		warn("BanService CheckBan error:", data)
		return false, "", 0
	end

	data = data or { IsBanned = false, Reason = "", BanTime = 0 }
	return data.IsBanned == true, data.Reason or "", data.BanTime or 0
end

function BanService:BanPlayer(player, reason, durationSeconds)
	reason = reason or self.BanDefaultReason
	local banTime = 0
	if durationSeconds and durationSeconds > 0 then
		banTime = os.time() + durationSeconds
	end

	local payload = {
		IsBanned = true,
		Reason = reason,
		BanTime = banTime,
	}

	local store = getStore(self)
	pcall(function()
		store:SetAsync(getKey(player.UserId), payload)
	end)

	player:Kick(reason)
end

function BanService:UnbanPlayer(userId)
	local store = getStore(self)
	pcall(function()
		store:SetAsync(getKey(userId), { IsBanned = false, Reason = "", BanTime = 0 })
	end)
end

function BanService:Init()
	return Players.PlayerAdded:Connect(function(player)
		local isBanned, reason, banTime = self:CheckBan(player)
		if not isBanned then
			return
		end

		if banTime > 0 and banTime <= os.time() then
			self:UnbanPlayer(player.UserId)
			return
		end

		kickedEvent:Fire(player, reason)
		player:Kick(reason ~= "" and reason or self.BanDefaultReason)
	end)
end

return BanService
