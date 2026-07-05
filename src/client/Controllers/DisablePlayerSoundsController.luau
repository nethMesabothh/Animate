local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local DisablePlayerSoundsController = Knit.CreateController({
	Name = "DisablePlayerSoundsController",
})

local player = Players.LocalPlayer

local function onCharacterAdded(character: Model): ()
	for _, obj in character:GetDescendants() do
		if obj:IsA("Sound") then
			obj:Destroy()
		end
	end

	character.DescendantAdded:Connect(function(descendant: Instance)
		if descendant:IsA("Sound") then
			-- Deferred so we don't fight the engine mid-setup while it's still parenting in.
			task.defer(function()
				if descendant.Parent then
					descendant:Destroy()
				end
			end)
		end
	end)
end

function DisablePlayerSoundsController:KnitStart()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

function DisablePlayerSoundsController:KnitInit() end

return DisablePlayerSoundsController
