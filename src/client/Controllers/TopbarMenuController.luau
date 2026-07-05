local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Icon = require(Packages.TopbarPlus)
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local AnimationCatalog = require(Shared.AnimationCatalog)

local EmoteRequested = ReplicatedStorage.EmoteRequested

local TopbarMenuController = Knit.CreateController({
	Name = "TopbarMenuController",
})

local function buildEmoteDropdownItems(): { any }
	local emoteNames = {}
	for emoteName in AnimationCatalog.Emotes do
		table.insert(emoteNames, emoteName)
	end
	table.sort(emoteNames)

	local items = {}
	for _, emoteName in emoteNames do
		local emote = AnimationCatalog.Emotes[emoteName]
		local item = Icon.new()
			:setName(`Emote_{emoteName}`)
			:setLabel(emoteName)
			:oneClick()
			:bindEvent("selected", function()
				EmoteRequested:Fire(emoteName, emote)
			end)

		table.insert(items, item)
	end

	return items
end

function TopbarMenuController:KnitStart()
	Icon.new()
		:setName("EmoteMenu")
		:setLabel("Emotes")
		:modifyTheme({ { "Dropdown", "MaxIcons", 4 } })
		:modifyChildTheme({ { "Widget", "MinimumWidth", 140 } })
		:setDropdown(buildEmoteDropdownItems())
end

function TopbarMenuController:KnitInit() end

return TopbarMenuController
