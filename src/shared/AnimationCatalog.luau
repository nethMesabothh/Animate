export type AnimationEntry = {
	Id: string,
	Looped: boolean,
}

-- Add new animations here, grouped by category. Nothing else needs to change:
-- AnimationController builds the Animation instance at runtime from Id, so
-- there's no project.json/Studio tree entry to keep in sync.
local AnimationCatalog: { [string]: { [string]: AnimationEntry } } = {
	Emotes = {
		Meditate = { Id = "rbxassetid://85082658620597", Looped = true },
	},
}

return AnimationCatalog
