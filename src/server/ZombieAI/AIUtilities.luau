-- Stateless AI utility functions. Ported verbatim from Roblox's official "Drooling Zombie"
-- catalog model (ROBLOX_AIUtilities).
local utility = {}

function utility:WideRayCast(start: Vector3, target: Vector3, offset: number, ignoreList: { Instance }): { BasePart }
	local parts = {}

	local ray = Ray.new(start, target - start)
	local part = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	if part then
		table.insert(parts, part)
	end

	local offsetVector = offset * (target - start):Cross(Vector3.FromNormalId(Enum.NormalId.Top)).Unit
	local ray2 = Ray.new(start + offsetVector, target - start + offsetVector)
	local part2 = game.Workspace:FindPartOnRayWithIgnoreList(ray2, ignoreList)
	if part2 then
		table.insert(parts, part2)
	end

	local ray3 = Ray.new(start - offsetVector, target - start - offsetVector)
	local part3 = game.Workspace:FindPartOnRayWithIgnoreList(ray3, ignoreList)
	if part3 then
		table.insert(parts, part3)
	end

	return parts
end

local maxForce = 15

function utility:GetRepulsionVector(unitPosition: Vector3, otherUnitsPositions: { Vector3 }): Vector3
	local repulsionVector = Vector3.zero
	for _, other in otherUnitsPositions do
		local fromOther = unitPosition - other
		fromOther = fromOther.Unit * 1000 / ((fromOther.Magnitude + 1) ^ 2)
		repulsionVector += fromOther
	end
	return repulsionVector * maxForce
end

function utility:GetClosestVisibleTarget(npcModel: Model, characters: { Model }, ignoreList: { Instance }, fieldOfView: number): Model?
	local closestTarget = nil
	local closestDistance = math.huge
	for _, character in characters do
		local toTarget = character.HumanoidRootPart.Position - npcModel.HumanoidRootPart.Position
		local toTargetWedge = toTarget * Vector3.new(1, 0, 1)
		local angle = math.acos(toTargetWedge:Dot(npcModel.HumanoidRootPart.CFrame.LookVector) / toTargetWedge.Magnitude)
		if math.deg(angle) < fieldOfView then
			local targetRay = Ray.new(npcModel.HumanoidRootPart.Position, toTarget)
			local part = game.Workspace:FindPartOnRayWithIgnoreList(targetRay, ignoreList)
			if part and part.Parent == character then
				if toTarget.Magnitude < closestDistance then
					closestTarget = character
					closestDistance = toTarget.Magnitude
				end
			end
		end
	end
	return closestTarget
end

local function isSpaceEmpty(position: Vector3): boolean
	local region = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2))
	return game.Workspace:IsRegion3Empty(region)
end

function utility:FindCloseEmptySpace(model: Model): Vector3?
	local count = 0
	repeat
		local xoff = math.random(5, 10) * (if math.random() > 0.5 then -1 else 1)
		local zoff = math.random(5, 10) * (if math.random() > 0.5 then -1 else 1)

		local targetPos = Vector3.new(
			model.HumanoidRootPart.Position.X + xoff,
			model.HumanoidRootPart.Position.Y,
			model.HumanoidRootPart.Position.Z + zoff
		)
		if isSpaceEmpty(targetPos) then
			return targetPos
		end

		targetPos += Vector3.new(0, 4, 0)
		if isSpaceEmpty(targetPos) then
			return targetPos
		end

		count += 1
	until count > 10
	return nil
end

return utility
