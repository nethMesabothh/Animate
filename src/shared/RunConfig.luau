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
-- Walk/Run/Idle are overridden with the Bow* poses while the bow is equipped, and with the
-- Default* poses otherwise (see MovementController) -- Jump still isn't overridden at all
-- (DoubleJumpController), so a single jump always uses Roblox's own default jump animation.
RunConfig.BowIdle = { Id = "rbxassetid://125407639122182", Looped = true } :: AnimationEntry
RunConfig.BowWalk = { Id = "rbxassetid://92035509749293", Looped = true, Speed = 0.5 } :: AnimationEntry
RunConfig.BowRun = { Id = "rbxassetid://92035509749293", Looped = true } :: AnimationEntry

-- Walk/Run are the user's own uploaded animations (accessible to this experience). Idle is still
-- the MovementSystem kit's original ID, which this experience doesn't have permission to play --
-- pending a replacement.
RunConfig.DefaultIdle = { Id = "rbxassetid://100096780667742", Looped = true } :: AnimationEntry
RunConfig.DefaultWalk = { Id = "rbxassetid://117512434153808", Looped = true } :: AnimationEntry
RunConfig.DefaultRun = { Id = "rbxassetid://111953528060130", Looped = true } :: AnimationEntry

RunConfig.Sprint = { Id = "rbxassetid://107046618160957", Looped = true } :: AnimationEntry
RunConfig.DoubleJump = { Id = "rbxassetid://656117878", Looped = false } :: AnimationEntry

-- Directional dash poses (published from the "Animations by BannBanX" kit, Workspace["Open Me"]) --
-- picked by DashController based on which way you're actually moving when you dash.
RunConfig.DashForward = { Id = "rbxassetid://105194699663346", Looped = false } :: AnimationEntry -- W
RunConfig.DashBackward = { Id = "rbxassetid://120386356213545", Looped = false } :: AnimationEntry -- S
RunConfig.DashLeft = { Id = "rbxassetid://88473733306679", Looped = false } :: AnimationEntry -- A
RunConfig.DashRight = { Id = "rbxassetid://73525223133763", Looped = false } :: AnimationEntry -- D

-- !!WARNING: DO NOT CHANGE!! --
RunConfig.Walking = false
RunConfig.Running = false
RunConfig.Sprinting = false

return RunConfig
