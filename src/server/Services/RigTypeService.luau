local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Forces every character to rebuild as R6 right after spawning, regardless of the player's own
-- avatar type preference. Studio's "Avatar Type" game setting only affects what a fresh
-- Play-Solo session defaults to and isn't reliably scriptable, so this is the actual
-- authoritative switch -- it works the same in Studio and in the published game.
--
-- Humanoid.RigType is read-only and ApplyDescription can't change rig type either (its second
-- argument is AssetTypeVerification, not a rig type) -- the only way to actually get an R6 body
-- is to build a fresh model via CreateHumanoidModelFromDescription and swap it in as the
-- player's Character.
local RigTypeService = Knit.CreateService({
	Name = "RigTypeService",
	Client = {},
})

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return
	end

	local ok, description = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok or not description then
		return
	end

	local newCharacter = Players:CreateHumanoidModelFromDescription(
		description,
		Enum.HumanoidRigType.R6,
		Enum.AssetTypeVerification.Default
	)
	newCharacter.Name = player.Name
	newCharacter:PivotTo(character:GetPivot())
	newCharacter.Parent = Workspace

	player.Character = newCharacter
	character:Destroy()
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

function RigTypeService:KnitStart()
	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function RigTypeService:KnitInit() end

return RigTypeService
