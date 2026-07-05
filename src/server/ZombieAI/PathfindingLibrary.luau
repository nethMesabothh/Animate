-- Pathfinding wrapper with target-change throttling. Ported verbatim from Roblox's official
-- "Drooling Zombie" catalog model (ROBLOX_PathfindingLibrary).
local PathfindingService = game:GetService("PathfindingService")
PathfindingService.EmptyCutoff = 0.3

local TargetOffsetMax = 10
local JumpThreshold = 1.5
local NextPointThreshold = 4

local PathfindingUtility = {}

function PathfindingUtility.new()
	local this = {}

	local lastTargetPos = Vector3.new(math.huge, math.huge, math.huge)
	local path: Path? = nil
	local currentPointIndex = 1

	function this:MoveToTarget(character: Model, target: Vector3): ()
		local targetOffset = (lastTargetPos - target).Magnitude
		if targetOffset > TargetOffsetMax then
			local startPoint = character.HumanoidRootPart.Position
			local humanoidState = character.Humanoid:GetState()
			if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
				local ray = Ray.new(character.HumanoidRootPart.Position, Vector3.new(0, -100, 0))
				local hitPart, hitPoint = game.Workspace:FindPartOnRay(ray, character)
				if hitPart then
					startPoint = hitPoint
				end
			end

			local newTarget = target
			local ray = Ray.new(target + Vector3.new(0, -3, 0), Vector3.new(0, -100, 0))
			local hitPart, hitPoint = game.Workspace:FindPartOnRay(ray, character)
			if hitPart and (hitPoint - target).Magnitude > 4 then
				newTarget = newTarget * Vector3.new(1, 0, 1) + Vector3.new(0, 3, 0)
			end

			path = PathfindingService:ComputeSmoothPathAsync(startPoint, newTarget, 500)
			currentPointIndex = 1
			lastTargetPos = target
		end

		if path then
			local points = path:GetPointCoordinates()
			if currentPointIndex < #points then
				local currentPoint = points[currentPointIndex]
				local distance = (character.HumanoidRootPart.Position - currentPoint).Magnitude
				if distance < NextPointThreshold then
					currentPointIndex += 1
				end

				character.Humanoid:MoveTo(points[currentPointIndex])
				if points[currentPointIndex].Y - character.HumanoidRootPart.Position.Y > JumpThreshold then
					character.Humanoid.Jump = true
				end
			else
				character.Humanoid:MoveTo(target)
			end
		end
	end

	return this
end

return PathfindingUtility
