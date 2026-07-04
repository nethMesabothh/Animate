export type CharacterStyle = {
	WalkAnimationId: string,
	RunAnimationId: string,
}

-- Roblox Catalog Animations (https://create.roblox.com/docs/animation/using#catalog-animations).
-- Add new styles here and tag a platform Part with matching CharacterStylePlatform
-- attribute Style = "<key>" -- nothing else needs to change.
local CharacterStyleCatalog: { [string]: CharacterStyle } = {
	Ninja = {
		WalkAnimationId = "rbxassetid://656121766",
		RunAnimationId = "rbxassetid://656118852",
	},
	Mage = {
		-- Uses the Levitation bundle: a floaty gait reads as "mage" better than the Mage bundle's own walk/run.
		WalkAnimationId = "rbxassetid://616013216",
		RunAnimationId = "rbxassetid://616010382",
	},
	Superhero = {
		WalkAnimationId = "rbxassetid://616122287",
		RunAnimationId = "rbxassetid://616117076",
	},
}

return CharacterStyleCatalog
