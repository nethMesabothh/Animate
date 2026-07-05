local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local SPAWN_POINT_NAME = "Mystical Spawn Point"
local SPAWN_HEIGHT_OFFSET = 3

local SpawnService = Knit.CreateService({
	Name = "SpawnService",
	Client = {},
})

local function findMysticalSpawn(): Instance?
	return Workspace:FindFirstChild(SPAWN_POINT_NAME)
end

local function getSpawnCFrame(): CFrame?
	local spawnPoint = findMysticalSpawn()
	if not spawnPoint then
		return nil
	end

	local spawnLocation = spawnPoint:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		local surfaceCFrame = spawnLocation.CFrame * CFrame.new(0, spawnLocation.Size.Y * 0.5, 0)
		return surfaceCFrame * CFrame.new(0, SPAWN_HEIGHT_OFFSET, 0)
	end

	if spawnPoint:IsA("BasePart") then
		return spawnPoint.CFrame + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0)
	end

	if spawnPoint:IsA("Model") then
		return spawnPoint:GetPivot() + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0)
	end

	return nil
end

local function configureSpawnLocations()
	local mysticalSpawn = findMysticalSpawn()
	if not mysticalSpawn then
		warn(`[SpawnService] "{SPAWN_POINT_NAME}" was not found in Workspace`)
		return
	end

	local primarySpawn = mysticalSpawn:FindFirstChildWhichIsA("SpawnLocation", true)
	if primarySpawn then
		primarySpawn.Enabled = true
		primarySpawn.Neutral = true
		primarySpawn.AllowTeamChangeOnTouch = false
		primarySpawn.Duration = 0
	end

	for _, instance in Workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") and instance ~= primarySpawn then
			instance.Enabled = false
		end
	end
end

local function moveCharacterToSpawn(character: Model)
	local spawnCFrame = getSpawnCFrame()
	if not spawnCFrame then
		return
	end

	character:PivotTo(spawnCFrame)
end

local function onCharacterAdded(character: Model)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoidRootPart then
		return
	end

	moveCharacterToSpawn(character)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function SpawnService:KnitStart()
	configureSpawnLocations()

	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function SpawnService:KnitInit() end

return SpawnService
