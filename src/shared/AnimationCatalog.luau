export type AnimationEntry = {
	Id: string,
	Looped: boolean,
	Anchor: boolean?,
	Vfx: string?,
	Speed: number?,
}

-- Add new animations here, grouped by category. Nothing else needs to change:
-- AnimationController builds the Animation instance at runtime from Id, so
-- there's no project.json/Studio tree entry to keep in sync.
--
-- Anchor = true freezes HumanoidRootPart for the duration of the emote (released when it's
-- stopped/toggled off) -- for stationary poses like meditating, so you can't slide or fall
-- mid-pose. Leave unset/false for emotes that should still let you move.
--
-- Vfx names a template under ReplicatedStorage.VFX to clone and weld to HumanoidRootPart for
-- the emote's duration (e.g. an aura). Leave unset for emotes with no attached effect.
local AnimationCatalog: { [string]: { [string]: AnimationEntry } } = {
	Emotes = {
		-- 12001987048 (from the toolbox kit) isn't actually usable here -- the experience
		-- has no permission to that asset (it belongs to the kit's original creator).
		-- Back to your own uploaded animation, now with Anchor.
		Meditate = {
			Id = "rbxassetid://109064120694832",
			Looped = true,
			Anchor = true,
			Vfx = "OverchargeHandEffect",
		},
	},
}

return AnimationCatalog
