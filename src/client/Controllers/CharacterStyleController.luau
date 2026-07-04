local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local CharacterStyleCatalog = require(Shared.CharacterStyleCatalog)

local StyleChanged = ReplicatedStorage.StyleChanged

local CharacterStyleController = Knit.CreateController({
	Name = "CharacterStyleController",
})

local player = Players.LocalPlayer
local currentStyle: string? = nil

local function onPlatformTouched(platform: BasePart, hit: BasePart)
	local character = player.Character
	if not character or not hit:IsDescendantOf(character) then
		return
	end

	local styleName = platform:GetAttribute("Style")
	local style = styleName and CharacterStyleCatalog[styleName]
	if not style or styleName == currentStyle then
		return
	end

	currentStyle = styleName
	StyleChanged:Fire(styleName, style.WalkAnimationId, style.RunAnimationId)
end

local function bindPlatform(platform: Instance)
	if not platform:IsA("BasePart") then
		return
	end
	platform.Touched:Connect(function(hit)
		onPlatformTouched(platform, hit)
	end)
end

function CharacterStyleController:KnitStart()
	for _, platform in CollectionService:GetTagged("CharacterStylePlatform") do
		bindPlatform(platform)
	end
	CollectionService:GetInstanceAddedSignal("CharacterStylePlatform"):Connect(bindPlatform)
end

function CharacterStyleController:KnitInit() end

return CharacterStyleController
