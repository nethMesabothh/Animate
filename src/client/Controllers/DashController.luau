local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local RunConfig = require(Shared.RunConfig)

local MovementLocked = ReplicatedStorage.MovementLocked

local DashController = Knit.CreateController({
	Name = "DashController",
})

local player = Players.LocalPlayer
local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil
local animator: Animator? = nil
local dashTracks: { [string]: AnimationTrack? } = {}

local isMovementLocked = false
local onCooldown = false

local function getDashDirection(): Vector3
	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude > 0.1 then
		return moveDirection.Unit
	end

	-- Not pressing a movement key -- dash the way the character is currently facing instead of
	-- doing nothing.
	local lookVector = rootPart.CFrame.LookVector
	return Vector3.new(lookVector.X, 0, lookVector.Z).Unit
end

-- Picks which of the four directional dash poses best matches the dash direction relative to
-- which way the character is currently facing (not world space) -- e.g. dashing to your left
-- while facing north plays the "Left" pose even though the world-space direction is west.
local function classifyDashDirection(direction: Vector3): string
	local forwardDot = direction:Dot(rootPart.CFrame.LookVector)
	local rightDot = direction:Dot(rootPart.CFrame.RightVector)

	if math.abs(forwardDot) >= math.abs(rightDot) then
		return if forwardDot >= 0 then "Forward" else "Backward"
	else
		return if rightDot >= 0 then "Right" else "Left"
	end
end

local function loadDashTrack(entry: typeof(RunConfig.DashForward), name: string): AnimationTrack?
	if entry.Id == "" then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = entry.Id

	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = entry.Looped
	return track
end

local function performDash(): ()
	if isMovementLocked or onCooldown or not humanoid or not rootPart then
		return
	end

	onCooldown = true
	task.delay(RunConfig.DashCooldown, function()
		onCooldown = false
	end)

	local direction = getDashDirection()

	local track = dashTracks[classifyDashDirection(direction)]
	if track then
		track:Play()
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "DashVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = direction * RunConfig.DashSpeed
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = attachment

	task.delay(RunConfig.DashDuration, function()
		attachment:Destroy()
	end)
end

local function onCharacterAdded(character: Model): ()
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	animator = humanoid:WaitForChild("Animator") :: Animator
	onCooldown = false

	dashTracks = {
		Forward = loadDashTrack(RunConfig.DashForward, "DashForward"),
		Backward = loadDashTrack(RunConfig.DashBackward, "DashBackward"),
		Left = loadDashTrack(RunConfig.DashLeft, "DashLeft"),
		Right = loadDashTrack(RunConfig.DashRight, "DashRight"),
	}
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= RunConfig.DashKey then
		return
	end

	performDash()
end

function DashController:KnitStart()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(onInputBegan)

	MovementLocked.Event:Connect(function(locked: boolean)
		isMovementLocked = locked
	end)
end

function DashController:KnitInit() end

return DashController
