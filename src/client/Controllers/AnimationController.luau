local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local AnimationCatalog = require(Shared.AnimationCatalog)

local MEDITATE_ANIMATION = AnimationCatalog.Emotes.Meditate

local AnimationController = Knit.CreateController({
	Name = "AnimationController",
})

local player = Players.LocalPlayer
local animator: Animator? = nil

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	if input.KeyCode ~= Enum.KeyCode.M then
		return
	end

	if not animator then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = MEDITATE_ANIMATION.Id

	local track = animator:LoadAnimation(animation)
	track.Looped = MEDITATE_ANIMATION.Looped
	track:Play()
end

function AnimationController:KnitStart()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(onInputBegan)
end

function AnimationController:KnitInit() end

return AnimationController
