local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local Flash = require(Shared.Flash)
local Packets = require(Shared.Packets)
local CursorOverride = require(Shared.CursorOverride)

local Assets = ReplicatedStorage.Assets
local Animations = Assets.Animations

local MovementLocked = ReplicatedStorage.MovementLocked

local BowController = Knit.CreateController({
	Name = "BowController",
})

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
	HoldThreshold = 0.2,
	FastHoldThreshold = 0.2,
	FastShotCooldown = 1,

	AimFOV = 40,
	DefaultFOV = 70,
	FOVTweenTime = 0.3,

	AimWalkSpeed = 1,
}

local State = {
	Aiming = false,
	Holding = false,
	FastAiming = false,
	FastShotFired = false,

	MouseDownTime = 0,
	FastMouseDownTime = 0,
	LastFastShotTime = 0,

	OriginalWalkSpeed = 16,
	CurrentFOVTween = nil :: Tween?,
}

local Humanoid: Humanoid? = nil
local Sounds: { [string]: Sound } = nil
local Tracks: { [string]: AnimationTrack } = nil
local Equipped = false

local function LoadAnimation(animation: Animation): AnimationTrack
	local animator = Humanoid:FindFirstChildOfClass("Animator") :: Animator
	return animator:LoadAnimation(animation)
end

local function setAiming(isAiming: boolean): ()
	if isAiming then
		CursorOverride.Push()
	else
		CursorOverride.Pop()
	end

	-- Bow Aim/Hold and the movement Idle/Walk/Run tracks all play at the same default Action
	-- priority, so without this they'd blend together instead of the bow pose winning cleanly.
	MovementLocked:Fire(isAiming)
end

local function TweenFOV(TargetFOV: number): ()
	if State.CurrentFOVTween then
		State.CurrentFOVTween:Cancel()
	end

	State.CurrentFOVTween = TweenService:Create(
		Camera,
		TweenInfo.new(Settings.FOVTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = TargetFOV }
	)

	State.CurrentFOVTween:Play()
end

local function StartAim(): ()
	State.Aiming = true
	Humanoid.WalkSpeed = Settings.AimWalkSpeed
	setAiming(true)

	Tracks.Aim:Play()
	Sounds.Hold:Play()
	TweenFOV(Settings.AimFOV)
end

local function StopAim(Fired: boolean): ()
	Tracks.Aim:Stop()
	Tracks.Hold:Stop()
	Sounds.Hold:Stop()

	Humanoid.WalkSpeed = State.OriginalWalkSpeed
	setAiming(false)

	if Fired then
		Sounds.Release:Play()
		Tracks.Shot:Play()
		Packets.Shoot:Fire(Camera.CFrame.LookVector)
	else
		Sounds.Cancel:Play()
	end

	State.Aiming = false
	State.Holding = false
	TweenFOV(Settings.DefaultFOV)
end

local function StartFastAim(): ()
	if tick() - State.LastFastShotTime < Settings.FastShotCooldown then
		return
	end

	State.FastAiming = true
	State.FastShotFired = false
	Humanoid.WalkSpeed = Settings.AimWalkSpeed
	setAiming(true)

	Tracks.Aim:Play()
	Sounds.Hold:Play()
	TweenFOV(Settings.AimFOV + 20)

	Tracks.FastShot:Play()

	Tracks.FastShot:GetMarkerReachedSignal("Shoot"):Once(function()
		if not State.FastAiming then
			return
		end

		State.FastShotFired = true
		State.LastFastShotTime = tick()

		Sounds.Hold:Stop()
		Sounds.Release:Play()

		Flash:Play(Player.Character)
		Packets.Shoot:Fire(Camera.CFrame.LookVector)

		State.FastAiming = false
		Humanoid.WalkSpeed = State.OriginalWalkSpeed
		setAiming(false)
		TweenFOV(Settings.DefaultFOV)
	end)
end

local function StopFastAim(): ()
	Tracks.Aim:Stop()
	Sounds.Hold:Stop()

	Humanoid.WalkSpeed = State.OriginalWalkSpeed
	setAiming(false)

	if not State.FastShotFired then
		Tracks.FastShot:Stop()
		Sounds.Cancel:Play()
	end

	State.FastAiming = false
	TweenFOV(Settings.DefaultFOV)
end

-- The CustomInventory toolbox addon auto-detects Tools via Character/Backpack.ChildAdded, but it
-- connects that listener to whatever character reference it captures at script-start -- which can
-- be the transient pre-R6-swap character (see RigTypeService), silently missing our bow. Hooking
-- our own (reliably correct) character reference's ChildAdded and registering explicitly sidesteps
-- that timing mismatch entirely.
local function registerWithInventory(tool: Instance): ()
	local playerGui = Player:FindFirstChild("PlayerGui")
	local customInventory = playerGui and playerGui:FindFirstChild("CustomInventory")
	local controllerScript = customInventory and customInventory:FindFirstChild("InventoryController")
	if not controllerScript then
		return
	end

	require(controllerScript.SETTINGS):newTool(tool)
end

local function onCharacterAdded(character: Model)
	Humanoid = character:WaitForChild("Humanoid") :: Humanoid
	State.OriginalWalkSpeed = Humanoid.WalkSpeed

	local animationAssets = {
		Aim = Animations["Bow Aim"] :: Animation,
		Hold = Animations["Bow Aim Hold"] :: Animation,
		Shot = Animations["Bow Aim Shot"] :: Animation,
		FastShot = Animations["Bow Fast Shot"] :: Animation,
	}

	Tracks = {
		Aim = LoadAnimation(animationAssets.Aim),
		Hold = LoadAnimation(animationAssets.Hold),
		Shot = LoadAnimation(animationAssets.Shot),
		FastShot = LoadAnimation(animationAssets.FastShot),
	}

	Tracks.Aim.Stopped:Connect(function()
		if State.Aiming then
			State.Holding = true
			Tracks.Hold:Play()
			Flash:Play(character)
			Sounds.Ready:Play()
		end
	end)

	-- CustomInventory's own Character/Backpack.ChildAdded detection already registers the tool
	-- automatically (confirmed via its own debug trace) -- this is just a redundant safety net.
	local existingTool = character:FindFirstChild("Bow")
	if existingTool then
		registerWithInventory(existingTool)
	end
	character.ChildAdded:Connect(function(child: Instance)
		if child.Name == "Bow" and child:IsA("Tool") then
			registerWithInventory(child)
		end
	end)
end

local function onEquipStateChanged(isEquipped: boolean): ()
	Equipped = isEquipped

	if not isEquipped then
		if State.Aiming then
			StopAim(false)
		end
		if State.FastAiming then
			StopFastAim()
		end
	end

	Knit.GetController("ShiftLockController"):SetForced(isEquipped)
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	if not Equipped then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		State.MouseDownTime = tick()
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.FastMouseDownTime = tick()
	end
end

local function onInputEnded(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if State.Aiming then
			StopAim(State.Holding)
		end

		State.MouseDownTime = 0
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if State.FastAiming then
			StopFastAim()
		end

		State.FastMouseDownTime = 0
	end
end

function BowController:KnitStart()
	Sounds = {
		Cancel = SoundService:WaitForChild("Cancel") :: Sound,
		Hold = SoundService:WaitForChild("Bow Hold") :: Sound,
		Release = SoundService:WaitForChild("Bow Release") :: Sound,
		Ready = SoundService:WaitForChild("Bow Ready") :: Sound,
	}

	if Player.Character then
		onCharacterAdded(Player.Character)
	end
	Player.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	Packets.EquipState.OnClientEvent:Connect(onEquipStateChanged)

	RunService.RenderStepped:Connect(function()
		if not Humanoid then
			return
		end

		if State.MouseDownTime > 0 and not State.Aiming and not State.FastAiming then
			if tick() - State.MouseDownTime >= Settings.HoldThreshold then
				StartAim()
			end
		end

		if State.FastMouseDownTime > 0 and not State.FastAiming and not State.Aiming then
			if tick() - State.FastMouseDownTime >= Settings.FastHoldThreshold then
				StartFastAim()
			end
		end
	end)
end

function BowController:KnitInit() end

return BowController
