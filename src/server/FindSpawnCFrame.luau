local Workspace = game:GetService("Workspace")

local SPAWN_POINT_NAME = "Mystical Spawn Point"

-- Returns a CFrame anchored to the map's actual spawn area, so world-relative offsets (bow
-- pickup, zombie spawn point, etc.) land somewhere sensible no matter which place this code is
-- currently synced into -- rather than a hardcoded absolute coordinate tuned for one specific map.
local function findSpawnCFrame(): CFrame
	local mysticalSpawn = Workspace:FindFirstChild(SPAWN_POINT_NAME)
	if mysticalSpawn then
		local spawnLocation = mysticalSpawn:FindFirstChildWhichIsA("SpawnLocation", true)
		if spawnLocation then
			return spawnLocation.CFrame
		end
		if mysticalSpawn:IsA("BasePart") then
			return mysticalSpawn.CFrame
		end
		if mysticalSpawn:IsA("Model") then
			return mysticalSpawn:GetPivot()
		end
	end

	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		return spawnLocation.CFrame
	end

	return CFrame.new(0, 5, 0)
end

return findSpawnCFrame
