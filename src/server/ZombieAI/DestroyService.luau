-- Delayed-destroy queue with a fade-out effect for Parts in their last second. Ported verbatim
-- from Roblox's official "Drooling Zombie" catalog model (ROBLOX_DestroyService).
local destroyService = {}

local destroyQueue: { { object: Instance, destroyTime: number } } = {}

function destroyService:AddItem(theObject: Instance, delay: number): ()
	local destroyObject = { object = theObject, destroyTime = os.time() + delay }
	for i, storedObject in destroyQueue do
		if storedObject.destroyTime > destroyObject.destroyTime then
			table.insert(destroyQueue, i, destroyObject)
			return
		end
	end
	table.insert(destroyQueue, destroyObject)
end

task.spawn(function()
	while true do
		local now = os.time()
		for _, storedObject in destroyQueue do
			if now >= storedObject.destroyTime then
				table.remove(destroyQueue, 1)
				if storedObject.object then
					storedObject.object:Destroy()
				end
			elseif now >= storedObject.destroyTime - 1 then
				if storedObject.object and storedObject.object:IsA("BasePart") then
					storedObject.object.Transparency += 1 / 30
				end
			else
				break
			end
		end
		task.wait()
	end
end)

return destroyService
