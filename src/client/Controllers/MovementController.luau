local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local RunConfig = require(Shared.RunConfig)
local Packets = require(Shared.Packets)

local MovementLocked = ReplicatedStorage.MovementLocked

local MovementController = Knit.CreateController({
	Name = "MovementController",
})

local player = Players.LocalPlayer
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local camera: Camera? = nil
local mobileGui: ScreenGui? = nil
local idleTrack: AnimationTrack? = nil
local walkTrack: AnimationTrack? = nil
local runTrack: AnimationTrack? = nil
local sprintTrack: AnimationTrack? = nil
local walkEntry: typeof(RunConfig.BowWalk)? = nil
local isMovementLocked = false
local bowEquipped = false
local sprintTimerThread: thread? = nil

local function loadTrack(entry: typeof(RunConfig.BowWalk), animationName: string): AnimationTrack
	local animation = Instance.new("Animation")
	animation.Name = animationName
	animation.AnimationId = entry.Id

	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = entry.Looped
	return track
end

-- Idle/Walk/Run are only ever loaded while the bow is equipped -- unequipped, none of them exist
-- at all, so Roblox's own default Animate script drives walk/run/idle exactly like a fresh
-- character (matching the request to keep stock Roblox animations when not holding the bow).
local function reloadMovementTracks(): ()
	-- AnimationTrack:Destroy() doesn't reliably stop a track that's actively playing -- without
	-- an explicit Stop() first, the animation can keep looping on the Animator even after the
	-- Lua-side track object is gone (observed: dropping the bow left the Bow Idle/Walk/Run
	-- animation stuck playing forever, especially if it happened mid-run).
	if idleTrack then
		idleTrack:Stop(0)
		idleTrack:Destroy()
		idleTrack = nil
	end
	if walkTrack then
		walkTrack:Stop(0)
		walkTrack:Destroy()
		walkTrack = nil
	end
	if runTrack then
		runTrack:Stop(0)
		runTrack:Destroy()
		runTrack = nil
	end

	if bowEquipped then
		walkEntry = RunConfig.BowWalk
		walkTrack = loadTrack(RunConfig.BowWalk, "WalkAnimation")
		runTrack = loadTrack(RunConfig.BowRun, "RunAnimation")
		idleTrack = loadTrack(RunConfig.BowIdle, "IdleAnimation")
	else
		walkEntry = nil
	end

	-- Fully reset movement state on any equip change so switching mid-run/mid-sprint doesn't
	-- leave a stale Running/Sprinting flag, WalkSpeed, or camera FOV behind from the animation
	-- set that just got replaced.
	RunConfig.Running = false
	RunConfig.Sprinting = false
	humanoid.WalkSpeed = RunConfig.WalkSpeed
	if camera then
		camera.FieldOfView = RunConfig.WalkFov
	end
	if sprintTimerThread then
		task.cancel(sprintTimerThread)
		sprintTimerThread = nil
	end
end

local function Walk()
	RunConfig.Running = false
	RunConfig.Sprinting = false

	TweenService
		:Create(
			humanoid,
			TweenInfo.new(RunConfig.TransitionSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ WalkSpeed = RunConfig.WalkSpeed }
		)
		:Play()
	TweenService
		:Create(
			camera,
			TweenInfo.new(RunConfig.TransitionSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ FieldOfView = RunConfig.WalkFov }
		)
		:Play()

	if runTrack then
		runTrack:Stop()
	end
	if sprintTrack then
		sprintTrack:Stop()
	end

	if sprintTimerThread then
		task.cancel(sprintTimerThread)
		sprintTimerThread = nil
	end
end

local function Sprint()
	if RunConfig.Walking and RunConfig.Running and RunConfig.CanSprint then
		RunConfig.Sprinting = true

		TweenService
			:Create(
				humanoid,
				TweenInfo.new(RunConfig.TransitionSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ WalkSpeed = RunConfig.SprintSpeed }
			)
			:Play()
		TweenService
			:Create(
				camera,
				TweenInfo.new(RunConfig.TransitionSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ FieldOfView = RunConfig.SprintFov }
			)
			:Play()
		-- sprintTrack:Play() -- temporarily disabled to test Bow Run animation in isolation
	end
end

local function Run()
	if isMovementLocked then
		return
	end

	if RunConfig.Walking and RunConfig.CanRun then
		RunConfig.Running = true

		TweenService
			:Create(
				humanoid,
				TweenInfo.new(RunConfig.TransitionSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ WalkSpeed = RunConfig.RunSpeed }
			)
			:Play()
		TweenService
			:Create(
				camera,
				TweenInfo.new(RunConfig.TransitionSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ FieldOfView = RunConfig.RunFov }
			)
			:Play()
		if runTrack then
			runTrack:Play()
		end
		if walkTrack then
			walkTrack:Stop()
		end

		sprintTimerThread = task.delay(RunConfig.SprintTransitionSpeed, function()
			if RunConfig.Running then
				Sprint()
			end
		end)
	end
end

local function onCharacterAdded(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	camera = workspace.CurrentCamera

	-- RigTypeService replaces player.Character with a freshly built R6 model (rather than the
	-- character spawning through the normal engine pipeline), so the camera doesn't automatically
	-- follow it -- it's left pointed at the previous (now-destroyed) character's Humanoid.
	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom

	if sprintTrack then
		sprintTrack:Destroy()
	end
	sprintTrack = loadTrack(RunConfig.Sprint, "SprintAnimation")

	bowEquipped = false
	reloadMovementTracks()
end

local function onEquipStateChanged(isEquipped: boolean): ()
	-- Tool Equipped/Unequipped can fire more than once for a single logical equip/drop action,
	-- so EquipState sometimes arrives repeated with the same value -- reloading every time would
	-- stack duplicate Idle/Walk/Run tracks on top of each other instead of replacing them.
	if bowEquipped == isEquipped then
		return
	end

	bowEquipped = isEquipped
	if humanoid and animator then
		reloadMovementTracks()
	end
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	if input.KeyCode == RunConfig.RunKey then
		Run()
	end
end

local function onInputEnded(input: InputObject)
	if input.KeyCode == RunConfig.RunKey then
		Walk()
	end
end

function MovementController:KnitStart()
	mobileGui = player:WaitForChild("PlayerGui"):WaitForChild("MobileGui") :: ScreenGui

	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	Packets.EquipState.OnClientEvent:Connect(onEquipStateChanged)

	mobileGui.RunButton.MouseButton1Down:Connect(Run)
	mobileGui.RunButton.MouseButton1Up:Connect(Walk)

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		mobileGui.Enabled = true
	end

	RunService.RenderStepped:Connect(function()
		if isMovementLocked or not humanoid then
			return
		end

		if humanoid.MoveDirection.Magnitude > 0 then
			RunConfig.Walking = true
			if idleTrack then
				idleTrack:Stop()
			end

			-- Explicitly override the core walk/run blend so normal walking always reads as a
			-- clean walk gait instead of whatever mix the default Animate script picks -- only
			-- while the bow is equipped; unequipped, walkTrack is nil and Roblox's default
			-- Animate script handles it on its own.
			if walkTrack and not RunConfig.Running and not walkTrack.IsPlaying then
				walkTrack:Play()
				walkTrack:AdjustSpeed(walkEntry and walkEntry.Speed or 1)
			end
		else
			RunConfig.Walking = false
			if walkTrack then
				walkTrack:Stop()
			end

			if RunConfig.Running then
				Walk()
			end

			if idleTrack and not idleTrack.IsPlaying then
				idleTrack:Play()
			end
		end
	end)

	-- Fired by AnimationController while an Anchor = true emote (like Meditate) is active, so we
	-- don't play walk/run over top of the emote's pose while the character is held in place.
	MovementLocked.Event:Connect(function(locked: boolean)
		isMovementLocked = locked
		if locked then
			if runTrack then
				runTrack:Stop()
			end
			if sprintTrack then
				sprintTrack:Stop()
			end
			if walkTrack then
				walkTrack:Stop()
			end
			if idleTrack then
				idleTrack:Stop()
			end
		end
	end)
end

function MovementController:KnitInit() end

return MovementController
