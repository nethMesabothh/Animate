local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local AnimationCatalog = require(Shared.AnimationCatalog)

local EmoteRequested = ReplicatedStorage.EmoteRequested
local MovementLocked = ReplicatedStorage.MovementLocked
local VfxFolder = ReplicatedStorage:WaitForChild("VFX")

local MEDITATE_ANIMATION = AnimationCatalog.Emotes.Meditate

local AnimationController = Knit.CreateController({
	Name = "AnimationController",
})

local player = Players.LocalPlayer
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local rootPart: BasePart? = nil
local activeEmoteTrack: AnimationTrack? = nil
local activeEmoteName: string? = nil
local anchoredRootPart: BasePart? = nil
local activeVfx: BasePart? = nil

local function onCharacterAdded(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	activeEmoteTrack = nil
	activeEmoteName = nil
	anchoredRootPart = nil
	-- The old character (and anything welded to it, including any active VFX clone) is
	-- destroyed by Roblox on respawn, so this reference would otherwise go stale.
	activeVfx = nil
end

local function spawnVfx(vfxName: string)
	local template = VfxFolder:FindFirstChild(vfxName)
	if not template or not rootPart then
		return
	end

	local vfx = template:Clone() :: BasePart
	vfx.CFrame = rootPart.CFrame
	vfx.Anchored = false
	vfx.CanCollide = false
	vfx.Massless = true
	vfx.Parent = rootPart.Parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = vfx
	weld.Parent = vfx

	local enableAttachment = vfx:FindFirstChild("Enable")
	local sound = enableAttachment and enableAttachment:FindFirstChildOfClass("Sound")
	if sound then
		sound:Play()
	end

	activeVfx = vfx

	-- "Enable" emitters are the activation burst; switch them off after a moment so they don't
	-- keep firing for the whole meditate duration. "Emit" emitters are the sustained aura and
	-- stay on until the emote ends (stopVfx below).
	task.delay(1, function()
		if activeVfx ~= vfx or not enableAttachment then
			return
		end
		for _, emitter in enableAttachment:GetChildren() do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = false
			end
		end
	end)
end

local function stopVfx()
	if not activeVfx then
		return
	end
	local vfx = activeVfx
	activeVfx = nil

	local emitAttachment = vfx:FindFirstChild("Emit")
	if emitAttachment then
		for _, emitter in emitAttachment:GetChildren() do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = false
			end
		end
	end

	-- Let already-emitted particles fade out naturally instead of popping the whole effect away.
	task.delay(2, function()
		vfx:Destroy()
	end)
end

local function stopActiveEmote()
	if activeEmoteTrack then
		activeEmoteTrack:Stop()
		activeEmoteTrack = nil
	end
	activeEmoteName = nil
	stopVfx()

	if anchoredRootPart then
		anchoredRootPart.Anchored = false
		anchoredRootPart = nil

		-- Hand animation control back to Roblox's default Animate script.
		if humanoid then
			humanoid.PlatformStand = false
		end

		-- Tell MovementController/DoubleJumpController it's safe to resume playing their own
		-- movement animations again.
		MovementLocked:Fire(false)
	end
end

local function isAirborne(): boolean
	if not humanoid then
		return false
	end
	local state = humanoid:GetState()
	return state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
end

local function playEmote(emoteName: string, emote: typeof(MEDITATE_ANIMATION))
	if not animator then
		return
	end

	-- Anchor = true emotes freeze you in place -- don't allow starting one mid-air, or you'd
	-- end up floating/frozen wherever you happened to be when the jump was interrupted.
	if emote.Anchor and activeEmoteName ~= emoteName and isAirborne() then
		return
	end

	-- Requesting the same emote again toggles it off instead of restarting it -- important for
	-- Anchor = true emotes, since that's the only way to release the anchor and move again.
	if activeEmoteName == emoteName then
		stopActiveEmote()
		return
	end

	stopActiveEmote()

	local animation = Instance.new("Animation")
	animation.Name = emoteName
	animation.AnimationId = emote.Id

	local track = animator:LoadAnimation(animation)
	track.Looped = emote.Looped
	track.Priority = Enum.AnimationPriority.Action
	track:Play()
	activeEmoteTrack = track
	activeEmoteName = emoteName

	if emote.Vfx then
		spawnVfx(emote.Vfx)
	end

	if emote.Anchor and rootPart then
		anchoredRootPart = rootPart
		anchoredRootPart.Anchored = true

		-- Roblox's default Animate script plays its own Jumping/Freefall poses at Core
		-- priority -- the highest tier, above even our Action2 jump animations -- so it would
		-- otherwise visually mask this emote entirely if triggered while airborne. PlatformStand
		-- hands animation control over to us completely until it's turned back off below.
		if humanoid then
			humanoid.PlatformStand = true
		end

		-- Tell other movement controllers to stop playing walk/run/jump animations (and stop
		-- reacting to movement/jump input) while this pose is held.
		MovementLocked:Fire(true)
	end
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	if input.KeyCode ~= Enum.KeyCode.M then
		return
	end

	playEmote("Meditate", MEDITATE_ANIMATION)
end

function AnimationController:KnitStart()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(onInputBegan)
	EmoteRequested.Event:Connect(function(emoteName: string, emote: typeof(MEDITATE_ANIMATION))
		playEmote(emoteName, emote)
	end)
end

function AnimationController:KnitInit() end

return AnimationController
