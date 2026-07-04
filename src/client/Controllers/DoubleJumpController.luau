local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local CharacterStyleCatalog = require(Shared.CharacterStyleCatalog)

local StyleChanged = ReplicatedStorage.StyleChanged

local DoubleJumpController = Knit.CreateController({
	Name = "DoubleJumpController",
})

local player = Players.LocalPlayer
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local jumpTrack: AnimationTrack? = nil
local doubleJumpTrack: AnimationTrack? = nil

-- Only true once we've confirmed (after a short delay) that the first jump has settled into a
-- genuine Freefall, matching Roblox's own double-jump example -- ChangeState(Jumping) is ignored
-- if fired too early, while the engine is still mid-ascent of the first jump.
local doubleJumpArmed = false

-- True only for the single StateChanged firing caused by our own ChangeState(Jumping) retrigger
-- below, so that branch doesn't clobber the double-jump animation with the single-jump one.
local isPerformingDoubleJump = false

-- Matches RunConfig's default style (Ninja) until a class platform fires StyleChanged.
local currentStyle = CharacterStyleCatalog.Ninja

local function loadTrack(animationId: string, animationName: string): AnimationTrack
	local animation = Instance.new("Animation")
	animation.Name = animationName
	animation.AnimationId = animationId

	local track = animator:LoadAnimation(animation)
	-- Above walk/run (Action) so the jump pose reads clearly even if a move key is still held mid-air.
	track.Priority = Enum.AnimationPriority.Action2
	track.Looped = false
	return track
end

local function loadJumpTracks()
	if jumpTrack then
		jumpTrack:Stop()
		jumpTrack:Destroy()
	end
	if doubleJumpTrack then
		doubleJumpTrack:Stop()
		doubleJumpTrack:Destroy()
	end

	jumpTrack = loadTrack(currentStyle.JumpAnimationId, "JumpAnimation")
	doubleJumpTrack = loadTrack(currentStyle.DoubleJumpAnimationId, "DoubleJumpAnimation")
end

local function onCharacterAdded(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	doubleJumpArmed = false
	loadJumpTracks()

	humanoid.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Jumping then
			if not isPerformingDoubleJump and jumpTrack then
				jumpTrack:Play()
			end
			isPerformingDoubleJump = false

			if not doubleJumpArmed then
				task.wait(0.2)
				if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
					doubleJumpArmed = true
				end
			end
		elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			doubleJumpArmed = false
			-- Non-looped tracks hold their last frame forever once finished instead of releasing
			-- on their own, so both jump poses must be stopped explicitly once we're grounded again.
			if jumpTrack then
				jumpTrack:Stop()
			end
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

	if not humanoid or not doubleJumpArmed then
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

	StyleChanged.Event:Connect(function(_styleName: string, style: typeof(currentStyle))
		currentStyle = style
		if animator then
			loadJumpTracks()
		end
	end)
end

function DoubleJumpController:KnitInit() end

return DoubleJumpController
