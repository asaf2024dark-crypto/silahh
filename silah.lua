-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local torso = character:WaitForChild("Torso")
local head = character:WaitForChild("Head")
local humanoid = character:WaitForChild("Humanoid")
local backpack = player:WaitForChild("Backpack")
local playerGui = player:WaitForChild("PlayerGui")

local SilahTA = ReplicatedStorage:WaitForChild("SilahTA")
local SilahKutusu = ReplicatedStorage:WaitForChild("SilahKutusu")
local SilahRemotes = SilahTA:WaitForChild("SilahRemotes")
local FireRemote = SilahRemotes:WaitForChild("Fire")
local DamageRemote = SilahRemotes:WaitForChild("Damage")
local KontrolRemote = SilahRemotes:WaitForChild("Kontrol")
local YetkilerRemote = SilahRemotes:WaitForChild("Yetkiler")
local KickRemote = SilahRemotes:WaitForChild("Kick")

local SilahAssets = SilahTA:WaitForChild("SilahAssets")
local Viewmodels = SilahAssets:WaitForChild("Viewmodels")
local Animations = SilahAssets:WaitForChild("Animations")
local Bullet = SilahAssets:WaitForChild("Bullet")
local Efektler = SilahAssets:WaitForChild("Efektler")

local mouse = player:GetMouse()
local SilahModules = SilahTA:WaitForChild("SilahModules")
local spring = require(SilahModules:WaitForChild("spring"))
local Velocity = require(SilahModules:WaitForChild("Velocity"))
local SilahClient = require(SilahModules:WaitForChild("SilahClient"))

local SilahTAUI = playerGui:WaitForChild("SilahTA")
local AmmoLabel = SilahTAUI:WaitForChild("Ammo")
local MaxAmmoLabel = SilahTAUI:WaitForChild("MaxAmmo")
local Crosshair = SilahTAUI:WaitForChild("Crosshair")
local MobileButtons = SilahTAUI:WaitForChild("MobileButtons")
local FireButton = MobileButtons:WaitForChild("Fire")
local ReloadButton = MobileButtons:WaitForChild("Reload")
local ScopeButton = MobileButtons:WaitForChild("Scope")
local LowerButton = MobileButtons:WaitForChild("Lower")
local ScopeUI = SilahTAUI:WaitForChild("Scope")

local currentCamera = workspace.CurrentCamera
local otoAim = player:WaitForChild("PlayerScripts"):WaitForChild("OtoAim")
local TeamRelations = require(SilahTA:WaitForChild("TeamRelations"))

-- Weapon state variables
local currentWeapon = nil
local weaponGrip = nil
local firePoint = nil
local effectPoint = nil
local weaponData = nil
local reloadSound = nil
local isFiring = false
local isReloading = false
local isScoped = false
local isLowered = false
local isAiming = false
local fireCooldown = false
local aimbotCount = 0
local viewModel = nil

-- Animation variables
local animations = {}
local viewmodelAnimations = {
	Idle = nil,
	Down = nil,
	Fire = nil,
	Fire2 = nil,
	Reload = nil,
	ReloadFirst = nil,
	ReloadSecond = nil,
	ReloadThird = nil
}

local springSystem = {
	WalkCycle = spring.create(),
	Sway = spring.create()
}

local cameraOffset = Instance.new("CFrameValue")
cameraOffset.Value = CFrame.new(0, -0.2, 0)

local weaponPositions = {
	["Tüfek"] = {
		Position = Vector3.new(0.537, 0.418, 0.618),
		Rotation = Vector3.new(0, 90, 0),
		TwistLowerAngle = -40,
		TwistUpperAngle = -30
	},
	SMG = {
		Position = Vector3.new(0.105, -0.029, -0.717),
		Rotation = Vector3.new(-60, 90, 0),
		TwistLowerAngle = 30,
		TwistUpperAngle = 10
	},
	Tabanca = {
		Position = Vector3.new(-1.014, -0.831, -0.11),
		Rotation = Vector3.new(-80, 0, 0),
		TwistLowerAngle = 30,
		TwistUpperAngle = 10
	}
}

-- Clean up old viewmodel if exists
if currentCamera:FindFirstChild("OldViewmodel") then
	currentCamera:FindFirstChild("OldViewmodel"):Destroy()
end

-- Helper functions
local function WeldGun(model, grip)
	for _, part in pairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name ~= "Mag" and part.Name ~= "Bolt" then
				part.Anchored = false
				local weld = Instance.new("Weld")
				weld.Part0 = grip
				weld.Part1 = part
				weld.C0 = grip.CFrame:Inverse()
				weld.C1 = part.CFrame:inverse()
				weld.Parent = grip
			else
				part.Anchored = false
				local motor = Instance.new("Motor6D")
				motor.Part0 = grip
				motor.Part1 = part
				motor.C0 = grip.CFrame:Inverse() * part.CFrame
				motor.Parent = grip
			end
		end
	end
end

local function ToggleScope()
	if currentWeapon and weaponData then
		if not ScopeUI.Visible then
			UserInputService.MouseDeltaSensitivity = 0.1
			isScoped = true
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			currentCamera.FieldOfView = 15
			Crosshair.Visible = false
			ScopeUI.Visible = true
		else
			UserInputService.MouseDeltaSensitivity = 1
			isScoped = false
			player.CameraMode = Enum.CameraMode.Classic
			currentCamera.FieldOfView = 70
			Crosshair.Visible = true
			ScopeUI.Visible = false
		end
	end
end

local function GetMass(model)
	local mass = 0
	for _, part in pairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			mass = mass + part:GetMass()
		end
	end
	return mass
end

local function SetupWeaponPhysics(weaponModel)
	if weaponModel:FindFirstChild("TA") then
		SilahKutusu:ClearAllChildren()

		local model = Instance.new("Model")
		local gunNameValue = Instance.new("StringValue")

		for _, part in pairs(weaponModel:GetChildren()) do
			if part:IsA("BasePart") then
				part:Clone().Parent = model
			end
		end

		local grip = model:FindFirstChild("Grip")
		local mass = GetMass(model)

		if grip then
			-- Weld all parts to grip
			for _, part in pairs(model:GetChildren()) do
				if part:IsA("BasePart") and part ~= grip then
					local weld = Instance.new("WeldConstraint", grip)
					weld.Part0 = grip
					weld.Part1 = part
					part.Massless = true
				end
			end

			wait()

			-- Create attachments
			Instance.new("Attachment", grip).Name = "GunAttach"

			if not torso:FindFirstChild("BallSocket") then
				local ballSocket = Instance.new("BallSocketConstraint")
				local torsoAttachment = Instance.new("Attachment", torso)

				ballSocket.Name = "BallSocket"
				torsoAttachment.Name = "GunAttachTorso"
				torsoAttachment.Position = Vector3.new(0.537, 0.498, 0.618)
				torsoAttachment.Orientation = Vector3.new(-20, 90, 0)

				ballSocket.LimitsEnabled = true
				ballSocket.Restitution = 0
				ballSocket.TwistLimitsEnabled = true
				ballSocket.TwistUpperAngle = 30
				ballSocket.TwistLowerAngle = -30
				ballSocket.UpperAngle = 5
				ballSocket.MaxFrictionTorque = 0.1
				ballSocket.Attachment0 = torsoAttachment
				ballSocket.Parent = torso
			end

			gunNameValue.Name = "GunName"
			gunNameValue.Value = weaponModel.Name
			model.Name = "ArkaSilah"
			model.PrimaryPart = grip
			model.Parent = SilahKutusu
			gunNameValue.Parent = model
		end
	end
end

local function EquipFPSWeapon(weapon)
	-- Clean up existing viewmodel
	if viewModel then
		viewModel:Destroy()
		viewModel = nil
	end

	cameraOffset.Value = CFrame.new(0, -10, 0)

	-- Create new weapon model
	local weaponModel = Instance.new("Model")
	weaponModel.Name = weapon.Name

	for _, part in pairs(weapon:Clone():GetChildren()) do
		if part:IsA("BasePart") then
			part.Parent = weaponModel
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end

	-- Get viewmodel and animations
	local viewmodelTemplate = (Viewmodels:FindFirstChild(player.Team.Name) or 
		(ReplicatedStorage:FindFirstChild("Viewmodels"):FindFirstChild(player.Team.Name) or Viewmodels:FindFirstChild("NoTeam")))
			local viewmodel = viewmodelTemplate:Clone()
			local weaponAnimations = Animations:WaitForChild(weapon.Name)
			local animator = viewmodel:WaitForChild("AnimationController"):WaitForChild("Animator")
			local grip = weaponModel:WaitForChild("Grip")
			local viewmodelRoot = viewmodel:WaitForChild("HumanoidRootPart")

			-- Weld weapon parts
			if not grip:FindFirstChildWhichIsA("Weld") then
				WeldGun(weaponModel, grip)
			end

			-- Attach weapon to viewmodel
			local motor = Instance.new("Motor6D", viewmodelRoot)
			motor.Part0 = viewmodelRoot
			motor.Part1 = grip
			weaponModel.Parent = viewmodel
			viewmodel.Parent = currentCamera
			viewmodel.Name = "OldViewmodel"

			-- Load animations
			for _, anim in pairs(weaponAnimations:GetChildren()) do
				viewmodelAnimations[anim.Name] = animator:LoadAnimation(anim)
			end

			viewModel = viewmodel
			viewmodelAnimations.Idle:Play()

			repeat
				task.wait()
			until viewmodelAnimations.Equip and viewmodelAnimations.Equip.Length > 0

			-- Tween camera
			local tween = TweenService:Create(cameraOffset, TweenInfo.new(0.1), {
				Value = CFrame.new(0, -0.2, 0)
			})
			tween:Play()

			-- Play equip animation
			if not isLowered then
				viewmodelAnimations.Equip:Play()
				viewmodelAnimations.Equip:AdjustWeight(100)
				viewmodelAnimations.Equip.Stopped:Wait()
			else
				if viewModel then
					viewmodelAnimations.Down:Play()
				end
			end
end

local function CanDamage(attackerPlayer, targetPlayer)
	-- Aynı oyuncu kontrolü
	if attackerPlayer == targetPlayer then
		return false
	end

	-- Friendly fire kontrolü
	if TeamRelations.AllowFriendlyFire and attackerPlayer.Team == targetPlayer.Team then
		return true
	end

	-- Takım ilişkileri kontrolü
	local attackerTeam = attackerPlayer.Team.Name
	local targetTeam = targetPlayer.Team.Name

	if TeamRelations[attackerTeam] then
		for _, enemyTeam in ipairs(TeamRelations[attackerTeam]) do
			if enemyTeam == targetTeam then
				return true
			end
		end
	end

	return false
end

local function AttachBackWeapon(weaponModel, weaponType)
	local backWeapon = character:FindFirstChild("ArkaSilah")

	-- Remove existing back weapon if different
	if backWeapon and backWeapon ~= weaponModel then
		backWeapon:Destroy()
	end

	local grip = weaponModel:FindFirstChild("Grip")
	if grip then
		local gunAttach = grip:FindFirstChild("GunAttach")
		if gunAttach then
			local torsoAttach = torso:FindFirstChild("GunAttachTorso")
			local ballSocket = torso:FindFirstChild("BallSocket")

			if ballSocket and torsoAttach then
				-- Clean up weapon model
				for _, descendant in pairs(weaponModel:GetDescendants()) do
					if descendant:IsA("Texture") or descendant:IsA("Decal") then
						if tonumber(descendant.Name) then
							descendant.Transparency = tonumber(descendant.Name)
						end
					elseif descendant.Name == "EfektPoint" or descendant.Name == "FirePoint" then
						descendant:Destroy()
					end
				end

				-- Position weapon
				torsoAttach.Position = weaponPositions[weaponType].Position
				torsoAttach.Orientation = weaponPositions[weaponType].Rotation

				weaponModel:SetPrimaryPartCFrame(CFrame.new(torsoAttach.WorldPosition) * grip.CFrame.Rotation)

				-- Configure constraints
				ballSocket.TwistLowerAngle = weaponPositions[weaponType].TwistLowerAngle
				ballSocket.TwistUpperAngle = weaponPositions[weaponType].TwistUpperAngle
				grip.Anchored = false
				ballSocket.Attachment1 = gunAttach
				weaponModel.Parent = character

				-- Adjust grip properties after a short delay
				delay(0.1, function()
					for _, part in pairs(weaponModel:GetChildren()) do
						if part.Name == "Grip" then
							part.Size = Vector3.new(0.4, 0.4, 0.4)
							part.Massless = false
							part.CustomPhysicalProperties = PhysicalProperties.new(10, 0.1, 0.1, 0.1, 0.1)
						end
					end
				end)
			end
		end
	end
end

-- Character events
character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and child:FindFirstChild("TA") then
		-- Remove existing back weapon if same type
		local backWeapon = character:FindFirstChild("ArkaSilah")
		if backWeapon then
			local gunName = backWeapon:FindFirstChild("GunName")
			if gunName and gunName.Value == child.Name then
				backWeapon:Destroy()
			end
		end

		-- Set up new weapon
		SilahTAUI.Enabled = true
		currentWeapon = child
		weaponGrip = child:WaitForChild("Grip")
		firePoint = weaponGrip:WaitForChild("FirePoint")
		effectPoint = weaponGrip:WaitForChild("EfektPoint")
		weaponData = require(child:WaitForChild("TA"))

		delay(0.1, function()
			SetupWeaponPhysics(child)
		end)

		reloadSound = effectPoint:WaitForChild("Reload")
		Crosshair.Visible = true
		UserInputService.MouseIconEnabled = false
		SilahTAUI.Enabled = true

		-- Load animations
		for _, anim in pairs(child:WaitForChild("TA"):GetChildren()) do
			if not animations[child.Name .. anim.Name] then
				animations[child.Name .. anim.Name] = humanoid:LoadAnimation(anim)
			end
		end

		-- Mobile setup
		if UserInputService.TouchEnabled then
			MobileButtons.Visible = true
			UserInputService.MouseDeltaSensitivity = 0.5
			ScopeButton.Visible = weaponData.Scope == true
		end

		EquipFPSWeapon(child)
	end
end)

character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") and child:FindFirstChild("TA") and child == currentWeapon then
		-- Stop all animations
		for _, anim in pairs(animations) do
			if anim.IsPlaying then
				anim:Stop()
			end
		end

		for _, anim in pairs(viewmodelAnimations) do
			if anim and anim.IsPlaying then
				anim:Stop()
			end
		end

		-- Attach weapon to back
		if SilahKutusu:FindFirstChild("ArkaSilah") then
			coroutine.wrap(AttachBackWeapon)(SilahKutusu:FindFirstChild("ArkaSilah"), weaponData.Tur)
		end

		-- Clean up viewmodel
		if viewModel then
			viewModel:Destroy()
			viewModel = nil
		end

		-- Reset states
		isFiring = false
		isReloading = false
		isScoped = false
		isAiming = false
		isLowered = false
		currentWeapon = nil
		weaponGrip = nil
		firePoint = nil
		effectPoint = nil
		weaponData = nil
		reloadSound = nil

		-- Reset UI
		SilahTAUI.Enabled = false
		UserInputService.MouseDeltaSensitivity = 1
		UserInputService.MouseIconEnabled = true
		isScoped = false
		player.CameraMode = Enum.CameraMode.Classic
		currentCamera.FieldOfView = 70
		ScopeUI.Visible = false

		-- Reset mobile camera
		if UserInputService.TouchEnabled then
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
		end
	end
end)

character.Destroying:Connect(function()
	UserInputService.MouseDeltaSensitivity = 1
	UserInputService.MouseIconEnabled = true
	player.CameraMode = Enum.CameraMode.Classic
	currentCamera.FieldOfView = 70

	if UserInputService.TouchEnabled then
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end
end)

humanoid.Died:Connect(function()
	UserInputService.MouseDeltaSensitivity = 1
	UserInputService.MouseIconEnabled = true
	player.CameraMode = Enum.CameraMode.Classic
	currentCamera.FieldOfView = 70

	if UserInputService.TouchEnabled then
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end

	wait()
	if currentWeapon then
		currentWeapon:Destroy()
	end
end)

-- Weapon effects
local function PlayBarrelEffects()
	if currentWeapon and effectPoint then
		if not viewModel then
			local light = effectPoint:FindFirstChildWhichIsA("Light")

			for _, effect in pairs(effectPoint:GetChildren()) do
				if effect:IsA("Light") then
					effect.Enabled = true
				elseif effect:IsA("ParticleEmitter") then
					effect:Emit(effect.Rate)
				end
			end

			wait()
			light.Enabled = false
		else
			local weaponModel = viewModel:FindFirstChild(currentWeapon.Name)
			if weaponModel then
				local grip = weaponModel:FindFirstChild("Grip")
				if grip then
					local effectPointVM = grip:FindFirstChild("EfektPoint")
					if effectPointVM then
						local light = effectPointVM:FindFirstChildWhichIsA("Light")

						for _, effect in pairs(effectPointVM:GetChildren()) do
							if effect:IsA("Light") then
								effect.Enabled = true
							elseif effect:IsA("ParticleEmitter") then
								effect:Emit(effect.Rate)
							end
						end

						wait()
						light.Enabled = false
					end
				end
			end
		end
	end
end

-- UI functions
local function UpdateCrosshair()
	if not UserInputService.TouchEnabled then
		local mousePos = UserInputService:GetMouseLocation()
		local crosshairSize = Crosshair.AbsoluteSize.X * 0.5
		Crosshair.Position = UDim2.new(0, mousePos.X - crosshairSize, 0, mousePos.Y - crosshairSize)
	else
		if UserInputService.TouchEnabled then
			if viewModel then
				humanoid.CameraOffset = Vector3.new(0, 0, 0)
			else
				humanoid.CameraOffset = Vector3.new(3, 2, 0)
			end

			local viewportSize = currentCamera.ViewportSize
			Crosshair.Position = UDim2.new(0, viewportSize.X / 2, 0, viewportSize.Y / 2)
		end
	end
end

local function UpdateScope()
	if not UserInputService.TouchEnabled then
		local mousePos = UserInputService:GetMouseLocation()
		local scopeSize = ScopeUI.AbsoluteSize.X * 0.5
		ScopeUI.Position = UDim2.new(0, mousePos.X - scopeSize, 0, mousePos.Y - scopeSize)
	else
		if UserInputService.TouchEnabled then
			local viewportSize = currentCamera.ViewportSize
			local scopeSize = ScopeUI.AbsoluteSize.X * 0.47
			ScopeUI.Position = UDim2.new(0, viewportSize.X / 2 - scopeSize, 0, viewportSize.Y / 2 - scopeSize)
		end
	end
end

-- Weapon actions
local function ReloadWeapon()
	if currentWeapon and weaponData and not isReloading and not isLowered then
		isReloading = true

		-- Eğer reloadSound varsa çal
		if reloadSound then
			reloadSound:Play()
		end

		-- Viewmodel animasyonu varsa oynat
		if viewModel and viewmodelAnimations.Reload then
			viewmodelAnimations.Reload:Play()
			viewmodelAnimations.Reload:AdjustWeight(200)
		end

		-- MaxAmmo kontrolü ekleyin
		if weaponData and weaponData.MaxAmmo then
			if animations[currentWeapon.Name .. "Reload"] then
				local reloadAnim = animations[currentWeapon.Name .. "Reload"]
				reloadAnim:Play(0.2)
				reloadAnim:AdjustWeight(100)
				wait(reloadAnim.Length)
				weaponData.Ammo = weaponData.MaxAmmo
			else
				wait(3)
				weaponData.Ammo = weaponData.MaxAmmo
			end
		else
			warn("Weapon data veya MaxAmmo tanımlı değil!")
		end

		isReloading = false
	end
end

local function ToggleLowerWeapon()
	if currentWeapon and weaponData and not isReloading and not isFiring then
		if not isLowered then
			if viewModel then
				viewmodelAnimations.Down:Play(0.3)
			end

			if animations[currentWeapon.Name .. "Down"] then
				isLowered = true
				local lowerAnim = animations[currentWeapon.Name .. "Down"]
				lowerAnim:Play(0.1)
				lowerAnim:AdjustWeight(100)
			end
		else
			if viewModel then
				viewmodelAnimations.Down:Stop(0.3)
			end

			isLowered = false

			if animations[currentWeapon.Name .. "Down"] then
				animations[currentWeapon.Name .. "Down"]:Stop()
			end
		end
	end
end

-- Input functions
local function GetFireDirection()
	local crosshairPos = Crosshair.AbsolutePosition * 2 / 2
	local crosshairSizeX = Crosshair.AbsoluteSize.X / 2
	local crosshairSizeY = Crosshair.AbsoluteSize.Y / 2

	local ray = currentCamera:ScreenPointToRay(
		crosshairPos.X + crosshairSizeX,
		crosshairPos.Y + crosshairSizeY
	)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 5000, raycastParams)

	if not raycastResult then
		return ray.Origin + ray.Direction * 5000
	else
		return raycastResult.Position, raycastResult.Instance
	end
end

local function FireWeapon(targetPosition, fireMode)
	if currentWeapon and firePoint and effectPoint and humanoid.Health > 0 then
		-- Hedef kontrolü ekle
		local hitPos, hitPart = GetFireDirection()
		if hitPart and hitPart:IsA("BasePart") then -- Daha doğru tip kontrolü
			local targetCharacter = hitPart:FindFirstAncestorOfClass("Model")
			if targetCharacter then
				local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
				if targetPlayer and not CanDamage(player, targetPlayer) then
					return -- Zarar veremezse işlemi durdur
				end
			end
		end

		-- Orijinal ateş etme kodları...
		coroutine.wrap(PlayBarrelEffects)()

		if viewModel then
			viewmodelAnimations.Fire:Play()
			viewmodelAnimations.Fire:AdjustWeight(100)
		end

		if animations[currentWeapon.Name .. "Fire"] then
			local fireAnim = animations[currentWeapon.Name .. "Fire"]
			fireAnim:Play(0.2)
			fireAnim:AdjustWeight(100)
		end

		weaponData.Ammo = weaponData.Ammo - 1

		-- Cast bullet
		if viewModel then
			local weaponModel = viewModel:FindFirstChild(currentWeapon.Name)
			if weaponModel then
				local grip = weaponModel:FindFirstChild("Grip")
				if grip then
					local effectPointVM = grip:FindFirstChild("EfektPoint")
					if effectPointVM then
						SilahClient.CastBullet(targetPosition, firePoint, player, character, fireMode, effectPointVM)
					end
				end
			end
		else
			SilahClient.CastBullet(targetPosition, firePoint, player, character, fireMode, effectPoint)
		end

		FireRemote:FireServer(targetPosition, currentWeapon, fireMode)

		-- Auto reload if empty
		if weaponData.Ammo == 0 then
			ReloadWeapon()
		end
	end

	wait(weaponData.Speed)
end

-- Input connections
mouse.Button1Down:Connect(function()
	if not UserInputService.TouchEnabled and currentWeapon and weaponData and weaponGrip and firePoint and not isReloading and not isLowered then
		if weaponData.Ammo > 0 then
			isFiring = true

			if weaponData.Type == "Auto" then
				if not fireCooldown then
					while isFiring and not isReloading and weaponData.Ammo > 0 do
						fireCooldown = true
						FireWeapon(mouse.Hit.Position, "Auto")
					end
					fireCooldown = false
				end
			elseif weaponData.Type == "Single" then
				if not fireCooldown then
					fireCooldown = true
					FireWeapon(mouse.Hit.Position, "Single")
					fireCooldown = false
				end
			elseif weaponData.Type == "Shotgun" and not fireCooldown then
				fireCooldown = true
				FireWeapon(mouse.Hit.Position, "Shotgun")
				fireCooldown = false
			end
		else
			ReloadWeapon()
		end
	end
end)

mouse.Button1Up:Connect(function()
	if not UserInputService.TouchEnabled then
		isFiring = false
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and currentWeapon and weaponData then
		if input.KeyCode == Enum.KeyCode.R then
			coroutine.wrap(ReloadWeapon)()
		elseif input.KeyCode == Enum.KeyCode.Q then
			if weaponData.Scope then
				ToggleScope()
			end
		elseif input.KeyCode == Enum.KeyCode.F then
			ToggleLowerWeapon()
		end
	end
end)

-- Remote event handlers
FireRemote.OnClientEvent:Connect(function(shooter, effectModel, hitPosition, fireMode)
	if shooter and effectModel and hitPosition then
		local replicateEffects = player:FindFirstChild("PlayerScripts"):FindFirstChild("ReplicateEfekts")

		if not replicateEffects then
			replicateEffects = Instance.new("BoolValue", player:FindFirstChild("PlayerScripts"))
			replicateEffects.Name = "ReplicateEfekts"
		end

		if replicateEffects and replicateEffects.Value then
			if shooter ~= player then
				local shooterCharacter = shooter.Character
				local shooterRoot = shooterCharacter:FindFirstChild("HumanoidRootPart")

				if (humanoidRootPart.Position - hitPosition).Magnitude < 100 or 
					(humanoidRootPart.Position - shooterRoot.Position).Magnitude < 100 then
					SilahClient.CastBullet(hitPosition, effectModel, shooter, shooterCharacter, fireMode, nil)
				end
			else
				aimbotCount = aimbotCount + 1
				if weaponData and aimbotCount > 400 then
					KickRemote:FireServer()
				end
			end
		end
	end
end)

DamageRemote.OnClientEvent:Connect(function(attacker, target, damage, hitPart, weaponName, isHeadshot)
	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	local targetPlayer = Players:GetPlayerFromCharacter(target)

	if attackerPlayer and targetPlayer and CanDamage(attackerPlayer, targetPlayer) then
		SilahClient.UIEfekts(attacker, target, damage, hitPart, weaponName, isHeadshot)
	end
end)

YetkilerRemote.OnClientEvent:Connect(function(authorityLevels, groupId)
	-- Store authority data
end)

-- Viewmodel update function
local function UpdateViewmodel(deltaTime)
	local camPart = viewModel and viewModel:FindFirstChild("CamPart")

	if camPart then
		local weaponModel = viewModel:FindFirstChild(currentWeapon.Name)

		if weaponModel then
			-- Reset transparency
			for _, part in pairs(weaponModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 0
				elseif (part:IsA("Texture") or part:IsA("Decal")) and tonumber(part.Name) then
					part.Transparency = tonumber(part.Name)
				end
			end
		end

		-- Calculate movement
		local velocity = humanoidRootPart.Velocity
		local mouseDelta = UserInputService:GetMouseDelta()

		-- Apply sway
		springSystem.Sway:shove(Vector3.new(
			mouseDelta.X / 500,
			mouseDelta.Y / 500
			))

		-- Apply walk cycle
		local walkCycleOffset = Vector3.new(
			math.sin(tick() * 12) * 0.02,
			math.sin(tick() * 5) * 0.02,
			math.sin(tick() * 5) * 0.02
		)

		springSystem.WalkCycle:shove(walkCycleOffset / 25 * deltaTime * 60 * velocity.Magnitude)

		-- Update springs
		local swayOffset = springSystem.Sway:update(deltaTime)
		local walkOffset = springSystem.WalkCycle:update(deltaTime)

		-- Position viewmodel
		camPart.CFrame = currentCamera.CFrame:ToWorldSpace(cameraOffset.Value)
		camPart.CFrame = camPart.CFrame:ToWorldSpace(CFrame.new(walkOffset.X / 2, walkOffset.Y / 2, 0))
		camPart.CFrame = camPart.CFrame * CFrame.Angles(0, -swayOffset.X, swayOffset.Y)
		camPart.CFrame = camPart.CFrame * CFrame.Angles(walkOffset.X, 0, walkOffset.Y)
	end
end

-- Kontrol remote function
KontrolRemote.OnClientInvoke = function(part, position, origin)
	local testPart = Instance.new("Part")
	testPart.Anchored = true
	testPart.CanCollide = false
	testPart.Transparency = 1
	testPart.Size = part.Size * 2
	testPart.Position = position
	testPart.Parent = currentCamera

	local direction = (position - origin).Unit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace:WaitForChild("Map"), testPart, part}

	local raycastResult = workspace:Raycast(origin, direction * 10000, raycastParams)

	testPart:Destroy()

	if raycastResult and (raycastResult.Instance == testPart or raycastResult.Instance == part) then
		return true
	end
end

-- Main game loop
RunService.RenderStepped:Connect(function(deltaTime)
	-- Update back weapon position
	if character:FindFirstChild("ArkaSilah") then
		local backWeapon = character:FindFirstChild("ArkaSilah")
		local grip = backWeapon:FindFirstChild("Grip")

		if grip and (grip.Position - humanoidRootPart.Position).Magnitude > 3 then
			backWeapon:SetPrimaryPartCFrame(humanoidRootPart.CFrame)
		end
	end

	-- Update current weapon
	if currentWeapon and weaponData then
		-- Handle first person vs third person
		if head.LocalTransparencyModifier == 1 then
			if not viewModel then
				EquipFPSWeapon(currentWeapon)
			end

			-- Hide weapon in first person
			for _, part in pairs(currentWeapon:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 1
				elseif (part:IsA("Texture") or part:IsA("Decal")) and part.Transparency ~= 1 then
					part.Name = part.Transparency
					part.Transparency = 1
				end
			end

			UpdateViewmodel(deltaTime)
		else
			-- Show weapon in third person
			for _, part in pairs(currentWeapon:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 0
				elseif (part:IsA("Texture") or part:IsA("Decal")) and tonumber(part.Name) then
					part.Transparency = tonumber(part.Name)
				end
			end

			-- Clean up viewmodel
			if viewModel then
				viewModel:Destroy()
				viewModel = nil
			end
		end

		-- Update UI
		if AmmoLabel and MaxAmmoLabel then
			AmmoLabel.Text = weaponData.Ammo
			MaxAmmoLabel.Text = weaponData.MaxAmmo
		end

		if not isScoped then
			if cameraOffset.Value == CFrame.new(0, 0, 5) then
				cameraOffset.Value = CFrame.new(0, -0.2, 0)
			end

			UpdateCrosshair()

			-- Play idle animation
			if animations[currentWeapon.Name .. "Idle"] then
				local idleAnim = animations[currentWeapon.Name .. "Idle"]
				if not idleAnim.IsPlaying then
					idleAnim:Play()
					idleAnim:GetMarkerReachedSignal("Son"):Wait()
					idleAnim:AdjustSpeed(0)
					idleAnim:AdjustWeight(5)
				end
			end
		else
			cameraOffset.Value = CFrame.new(0, 0, 5)
			UpdateScope()
		end
	end
end)

-- Mobile button connections
LowerButton.Activated:Connect(function()
	ToggleLowerWeapon()
end)

FireButton.InputBegan:Connect(function()
	if UserInputService.TouchEnabled and currentWeapon and weaponData and weaponGrip and firePoint and not isReloading and weaponData.Ammo > 0 and not isLowered then
		isFiring = true

		if weaponData.Type == "Auto" then
			if not fireCooldown then
				while isFiring and not isReloading and weaponData.Ammo > 0 do
					fireCooldown = true
					local target = GetFireDirection()
					FireWeapon(target, "Auto")
				end
				fireCooldown = false
			end
		elseif weaponData.Type == "Single" then
			if not fireCooldown then
				fireCooldown = true
				local target = GetFireDirection()
				FireWeapon(target, "Single")
				fireCooldown = false
			end
		elseif weaponData.Type == "Shotgun" and not fireCooldown then
			fireCooldown = true
			local target = GetFireDirection()
			FireWeapon(target, "Shotgun")
			fireCooldown = false
		end
	elseif currentWeapon and weaponData.Ammo <= 0 then
		ReloadWeapon()
	end
end)

FireButton.InputEnded:Connect(function()
	isFiring = false
end)

ReloadButton.Activated:Connect(function()
	ReloadWeapon()
end)

ScopeButton.Activated:Connect(function()
	if currentWeapon and weaponData then
		ToggleScope()
	end
end)

-- Additional effect handlers
local FireEffectEvent = SilahRemotes:WaitForChild("FireEffectEvent")
local MermiIzleriEvent = SilahRemotes:WaitForChild("MermiIzleriEvent")

FireEffectEvent.OnClientEvent:Connect(function(position, effect)
	if effect then
		local clonedEffect = effect:Clone()
		clonedEffect.Parent = workspace
		clonedEffect:SetPrimaryPartCFrame(CFrame.new(position))
		Debris:AddItem(clonedEffect, 5)
	end
end)

MermiIzleriEvent.OnClientEvent:Connect(function(position, effect)
	if effect then
		local clonedEffect = effect:Clone()
		clonedEffect.Parent = workspace
		clonedEffect:SetPrimaryPartCFrame(CFrame.new(position))
		Debris:AddItem(clonedEffect, 10)
	end
end)

-- Reset aimbot counter periodically
while true do
	wait(10)
	aimbotCount = 0
end
