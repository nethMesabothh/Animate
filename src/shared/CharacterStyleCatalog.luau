export type CharacterStyle = {
	WalkAnimationId: string,
	RunAnimationId: string,
	JumpAnimationId: string,
	DoubleJumpAnimationId: string,
}

-- Roblox Catalog Animations (https://create.roblox.com/docs/animation/using#catalog-animations).
-- Add new styles here and tag a platform Part with matching CharacterStylePlatform
-- attribute Style = "<key>" -- nothing else needs to change.
--
-- DoubleJumpAnimationId starts as a copy of JumpAnimationId per style (same clip played
-- again on the second jump) -- swap in a distinct flip/aerial clip per style later.
local CharacterStyleCatalog: { [string]: CharacterStyle } = {
	Ninja = {
		WalkAnimationId = "rbxassetid://656121766",
		RunAnimationId = "rbxassetid://656118852",
		JumpAnimationId = "rbxassetid://656117878",
		DoubleJumpAnimationId = "rbxassetid://656117878",
	},
	Mage = {
		-- Uses the Levitation bundle throughout: a floaty gait/jump reads as "mage" better than the Mage bundle's own clips.
		WalkAnimationId = "rbxassetid://616013216",
		RunAnimationId = "rbxassetid://616010382",
		JumpAnimationId = "rbxassetid://616008936",
		DoubleJumpAnimationId = "rbxassetid://616008936",
	},
	Superhero = {
		WalkAnimationId = "rbxassetid://616122287",
		RunAnimationId = "rbxassetid://616117076",
		JumpAnimationId = "rbxassetid://616115533",
		DoubleJumpAnimationId = "rbxassetid://616115533",
	},
}

return CharacterStyleCatalog
