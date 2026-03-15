local Players = game:GetService("Players")
local Skins = require(script.Parent:WaitForChild("Skins"))

local SkinService = {}

local FACES = {
	Enum.NormalId.Left,
	Enum.NormalId.Right,
	Enum.NormalId.Front,
	Enum.NormalId.Back,
	Enum.NormalId.Top,
	Enum.NormalId.Bottom,
}

local function clearPartVisuals(part)
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Texture") or child:IsA("SurfaceAppearance") then
			child:Destroy()
		end
	end

	if part:IsA("MeshPart") then
		part.TextureID = ""
	end

	local mesh = part:FindFirstChild("Mesh")
	if mesh and mesh:IsA("SpecialMesh") then
		mesh.TextureId = ""
	end
end

local function applyTextureToPart(part, skinData)
	if skinData.TextureId == "" then
		return
	end

	for _, face in ipairs(FACES) do
		local texture = Instance.new("Texture")
		texture.Face = face
		texture.Color3 = skinData.TextureColor
		texture.Texture = skinData.TextureId
		texture.OffsetStudsU = skinData.OffsetStudsU
		texture.OffsetStudsV = skinData.OffsetStudsV
		texture.StudsPerTileU = skinData.StudsPerTileU
		texture.StudsPerTileV = skinData.StudsPerTileV
		texture.Transparency = skinData.TextureTransparency
		texture.Parent = part
	end
end

function SkinService.SetSkin(player, tool)
	if not player or not tool then
		return
	end

	local skinName = player:GetAttribute("Skin") or ""
	local skinCase = player:GetAttribute("SkinKasa") or ""
	if skinName == "" or skinCase == "" then
		return
	end

	local caseData = Skins[skinCase]
	if not caseData then
		return
	end
	local skinData = caseData[skinName]
	if not skinData then
		return
	end

	for _, child in ipairs(tool:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("Skin") then
			clearPartVisuals(child)
			applyTextureToPart(child, skinData)
			child.Material = skinData.Material
			child.MaterialVariant = skinData.MaterialVariant
			child.Color = skinData.Color
		end
	end
end

local function onPlayerCharacterAdded(player, character)
	for _, tool in ipairs(player:WaitForChild("Backpack"):GetChildren()) do
		if tool:FindFirstChild("TA") then
			SkinService.SetSkin(player, tool)
		end
	end

	for _, equipped in ipairs(character:GetChildren()) do
		if equipped:IsA("Tool") and equipped:FindFirstChild("TA") then
			SkinService.SetSkin(player, equipped)
		end
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:FindFirstChild("TA") then
			SkinService.SetSkin(player, child)
		end
	end)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onPlayerCharacterAdded(player, character)
	end)
end

function SkinService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
		if player.Character then
			onPlayerCharacterAdded(player, player.Character)
		end
	end
end

return SkinService
