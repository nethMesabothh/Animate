-- Naive full-workspace humanoid scan, refreshed every 3 seconds. Ported verbatim from Roblox's
-- official "Drooling Zombie" catalog model (ROBLOX_HumanoidList).
local humanoidList = {}
local storage = {}

function humanoidList:GetCurrent()
	return storage
end

local function findHumanoids(object: Instance, list: { Humanoid })
	if object then
		if object:IsA("Humanoid") then
			table.insert(list, object)
		end

		for _, child in object:GetChildren() do
			findHumanoids(child, list)
		end
	end
end

task.spawn(function()
	while true do
		local newStorage = {}
		findHumanoids(game.Workspace, newStorage)
		storage = newStorage
		task.wait(3)
	end
end)

return humanoidList
