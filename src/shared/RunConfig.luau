local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationCatalog = require(ReplicatedStorage.Shared.AnimationCatalog)

type AnimationEntry = AnimationCatalog.AnimationEntry

local RunConfig = {}

-- \\ SETTINGS \\

RunConfig.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
RunConfig.RunSpeed = 20 -- Speed while running
RunConfig.SprintSpeed = 25 -- Speed while sprinting

RunConfig.WalkFov = workspace.Camera.FieldOfView
RunConfig.RunFov = 80 -- Camera FieldOfView while running
RunConfig.SprintFov = 85 -- Camera FieldOfView while sprinting

RunConfig.CanRun = true -- If the player is able to run
RunConfig.CanSprint = false -- If the player is able to sprint

RunConfig.RunKey = Enum.KeyCode.LeftShift -- The key to press to run
RunConfig.TransitionSpeed = 0.5 -- Time it takes to go from walking to running
RunConfig.SprintTransitionSpeed = 3 -- Time it takes before you start sprinting

RunConfig.JumpCooldown = 1 -- Seconds between ground jumps (see DoubleJumpController)

RunConfig.DashKey = Enum.KeyCode.Q -- Always dashes, even while locked on (see DashController)
RunConfig.DashSpeed = 75 -- Studs/sec applied for the dash's duration
RunConfig.DashDuration = 0.2 -- How long the dash velocity is sustained
RunConfig.DashCooldown = 1.2 -- Seconds before another dash can be triggered

-- Same { Id, Looped } shape as AnimationCatalog.Emotes -- swap Id here to replace any of these
-- animations later, exactly like swapping Meditate's.
--
-- PENDING: Sprint/DoubleJump are still R15 catalog animations and won't play correctly now that
-- characters are R6 (see RigTypeService). Replace with published IDs from the R6 animation pack
-- (Nugget's Animation pack V1) as they're exported.
--
-- Walk/Run/Idle/Jump are only ever overridden with the Bow* poses while the bow is equipped (see
-- MovementController/DoubleJumpController) -- unequipped, none of these are overridden at all, so
-- Roblox's own default Animate script drives walk/run/idle/jump exactly like a fresh character.
RunConfig.BowIdle = { Id = "rbxassetid://125407639122182", Looped = true } :: AnimationEntry
RunConfig.BowWalk = { Id = "rbxassetid://92035509749293", Looped = true, Speed = 0.5 } :: AnimationEntry
RunConfig.BowRun = { Id = "rbxassetid://92035509749293", Looped = true } :: AnimationEntry

RunConfig.Sprint = { Id = "rbxassetid://107046618160957", Looped = true } :: AnimationEntry
RunConfig.DoubleJump = { Id = "rbxassetid://656117878", Looped = false } :: AnimationEntry

-- !!WARNING: DO NOT CHANGE!! --
RunConfig.Walking = false
RunConfig.Running = false
RunConfig.Sprinting = false

return RunConfig
