local LockOnConfig = {}

-- Input
LockOnConfig.LockKey = Enum.KeyCode.E
LockOnConfig.SwitchTargetKey = Enum.KeyCode.Q
LockOnConfig.SwitchTargetMouse = Enum.UserInputType.MouseButton3

-- Targeting
LockOnConfig.TargetTag = "Zombie"
LockOnConfig.MaxDistance = 300
LockOnConfig.TargetRefreshRate = 0.15
LockOnConfig.RequireLineOfSight = false

-- Scoring weights for find-closest (angle vs distance, should sum to 1)
LockOnConfig.AngleWeight = 0.6
LockOnConfig.DistanceWeight = 0.4

-- Camera
LockOnConfig.CameraSmoothness = 0.16
LockOnConfig.SideOffset = 7
LockOnConfig.HeightOffset = 3
LockOnConfig.BackOffset = 13
LockOnConfig.TargetLookHeight = 0

LockOnConfig.DefaultFov = 70
LockOnConfig.LockedFov = 76
LockOnConfig.FovSmoothness = 0.08

-- Character rotation while locked
LockOnConfig.RotateCharacterToTarget = true
LockOnConfig.RotationSmoothness = 0.18

-- Highlight
LockOnConfig.EnableHighlight = true
LockOnConfig.HighlightFill = Color3.fromRGB(255, 55, 55)
LockOnConfig.HighlightOutline = Color3.fromRGB(255, 255, 255)
LockOnConfig.HighlightFillTransparency = 1
LockOnConfig.HighlightOutlineTransparency = 0

-- Reticle
LockOnConfig.EnableReticle = true
LockOnConfig.ReticleImage = "rbxassetid://9563783593"
LockOnConfig.ReticleSize = 175
LockOnConfig.ReticleColor = Color3.fromRGB(255, 255, 255)
LockOnConfig.ReticleTransparency = 0.05
LockOnConfig.ReticleRotates = true
LockOnConfig.ReticleRotationSpeed = 45
LockOnConfig.ReticlePulse = true
LockOnConfig.ReticlePulseAmount = 0.08
LockOnConfig.ReticlePulseSpeed = 3

-- Threat arrows
LockOnConfig.EnableThreatArrows = true
LockOnConfig.ArrowImage = "rbxassetid://121233462379046"
LockOnConfig.ArrowSize = 34
LockOnConfig.ArrowColor = Color3.fromRGB(255, 255, 255)
LockOnConfig.ArrowDistanceFromCenter = 185
LockOnConfig.ArrowEdgePadding = 55
LockOnConfig.HideArrowForCurrentTarget = true

return LockOnConfig
