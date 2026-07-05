local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local RunConfig = require(Shared.RunConfig)

local MovementLocked = ReplicatedStorage.MovementLocked

local DoubleJumpController = Knit.CreateController({
	Name = "DoubleJumpController",
})

local player = Players.LocalPlayer
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local doubleJumpTrack: AnimationTrack? = nil

-- Only true once we've confirmed (after a short delay) that the first jump has settled into a
-- genuine Freefall, matching Roblox's own double-jump example -- ChangeState(Jumping) is ignored
-- if fired too early, while the engine is still mid-ascent of the first jump.
local doubleJumpArmed = false

-- True only for the single StateChanged firing caused by our own ChangeState(Jumping) retrigger
-- below, so that branch doesn't clobber the double-jump animation with the single-jump one.
local isPerformingDoubleJump = false

-- Fired by AnimationController while an Anchor = true emote (like Meditate) is active, so
-- pressing jump doesn't play a jump pose over top of the emote while the character is held in place.
local isMovementLocked = false

local function loadTrack(entry: typeof(RunConfig.DoubleJump), animationName: string): AnimationTrack
	local animation = Instance.new("Animation")
	animation.Name = animationName
	animation.AnimationId = entry.Id

	local track = animator:LoadAnimation(animation)
	-- Above walk/run (Action) so the jump pose reads clearly even if a move key is still held mid-air.
	track.Priority = Enum.AnimationPriority.Action2
	track.Looped = entry.Looped
	return track
end

local function onCharacterAdded(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	doubleJumpArmed = false

	if doubleJumpTrack then
		doubleJumpTrack:Stop()
		doubleJumpTrack:Destroy()
	end

	doubleJumpTrack = loadTrack(RunConfig.DoubleJump, "DoubleJumpAnimation")

	humanoid.StateChanged:Connect(function(_old, new)
		if isMovementLocked then
			return
		end

		-- The first jump uses Roblox's own default jump animation (no override) -- only the
		-- double jump needs a custom pose, since that's not a stock Humanoid ability.
		if new == Enum.HumanoidStateType.Jumping then
			local wasDoubleJump = isPerformingDoubleJump
			isPerformingDoubleJump = false

			-- Only the natural first jump (from the ground) should ever arm the double jump --
			-- our own ChangeState(Jumping) retrigger for the double jump itself also lands in this
			-- branch, and must NOT re-arm another one, or jumping becomes unlimited.
			if not wasDoubleJump and not doubleJumpArmed then
				task.wait(0.2)
				if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
					doubleJumpArmed = true
				end
			end
		elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			doubleJumpArmed = false
			-- Non-looped tracks hold their last frame forever once finished instead of releasing
			-- on their own, so the double jump pose must be stopped explicitly once we're grounded.
			if doubleJumpTrack then
				doubleJumpTrack:Stop()
			end
		end
	end)
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.Space then
		return
	end

	if isMovementLocked or not humanoid or not doubleJumpArmed then
		return
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
		isPerformingDoubleJump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		doubleJumpArmed = false

		if doubleJumpTrack then
			doubleJumpTrack:Play()
		end
	end
end

function DoubleJumpController:KnitStart()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(onInputBegan)

	MovementLocked.Event:Connect(function(locked: boolean)
		isMovementLocked = locked
		if locked then
			if doubleJumpTrack then
				doubleJumpTrack:Stop()
			end
		end
	end)
end

function DoubleJumpController:KnitInit() end

return DoubleJumpController
