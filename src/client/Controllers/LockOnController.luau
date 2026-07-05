local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local LockOnConfig = require(Shared.LockOnConfig)
local Packets = require(Shared.Packets)

local LockOnController = Knit.CreateController({
	Name = "LockOnController",
})

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local character: Model? = nil
local humanoid: Humanoid? = nil
local humanoidRootPart: BasePart? = nil

local locked = false
local currentTarget: BasePart? = nil
local savedCameraType: Enum.CameraType? = nil

local availableTargets: { BasePart } = {}
local threatArrows: { [BasePart]: ImageLabel } = {}

local screenGui: ScreenGui? = nil
local reticleBillboard: BillboardGui? = nil
local reticleImage: ImageLabel? = nil
local currentHighlight: Highlight? = nil

local inputConnection: RBXScriptConnection? = nil
local deathConnection: RBXScriptConnection? = nil

local targetRefreshTimer = 0
local smoothedCameraPosition: Vector3? = nil
local smoothedLookPosition: Vector3? = nil

local shiftLockController: any = nil

local function safeDisconnect(connection: RBXScriptConnection?): ()
	if connection then
		connection:Disconnect()
	end
end

local function getRoot(model: Model?): BasePart?
	if not model then
		return nil
	end

	return model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getTargetPoint(targetRoot: BasePart): Vector3
	return targetRoot.Position + Vector3.new(0, LockOnConfig.TargetLookHeight, 0)
end

local function hasLineOfSight(targetRoot: BasePart): boolean
	if not humanoidRootPart then
		return false
	end

	local origin = humanoidRootPart.Position
	local direction = getTargetPoint(targetRoot) - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(origin, direction, params)
	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(targetRoot.Parent)
end

local function isValidTarget(root: BasePart?): boolean
	if not root or not root:IsA("BasePart") or not root.Parent then
		return false
	end

	if not character or not humanoidRootPart then
		return false
	end

	if root == humanoidRootPart then
		return false
	end

	local model = root.Parent
	if model == character then
		return false
	end

	if not CollectionService:HasTag(model, LockOnConfig.TargetTag) then
		return false
	end

	local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	local distance = (humanoidRootPart.Position - root.Position).Magnitude
	if distance > LockOnConfig.MaxDistance then
		return false
	end

	if LockOnConfig.RequireLineOfSight and not hasLineOfSight(root) then
		return false
	end

	return true
end

local function gatherTargets(): ()
	table.clear(availableTargets)

	if not humanoidRootPart then
		return
	end

	for _, model in CollectionService:GetTagged(LockOnConfig.TargetTag) do
		if model:IsA("Model") then
			local root = getRoot(model)
			if root and isValidTarget(root) then
				table.insert(availableTargets, root)
			end
		end
	end

	table.sort(availableTargets, function(a, b)
		local da = (humanoidRootPart.Position - a.Position).Magnitude
		local db = (humanoidRootPart.Position - b.Position).Magnitude
		return da < db
	end)
end

local function createScreenGui(): ()
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("LockOnThreatIndicators")
	if old then
		old:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LockOnThreatIndicators"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
end

local function removeReticle(): ()
	if reticleBillboard then
		reticleBillboard:Destroy()
	end

	reticleBillboard = nil
	reticleImage = nil
end

local function removeHighlight(): ()
	if currentHighlight then
		currentHighlight:Destroy()
	end

	currentHighlight = nil
end

local function clearThreatArrows(): ()
	for _, arrow in threatArrows do
		if arrow then
			arrow:Destroy()
		end
	end

	table.clear(threatArrows)
end

local function resetCameraSmoothing(): ()
	smoothedCameraPosition = nil
	smoothedLookPosition = nil
end

local function restoreCameraType(): ()
	if savedCameraType then
		camera.CameraType = savedCameraType
		savedCameraType = nil
	end
end

function LockOnController:Unlock(): ()
	if not locked and not currentTarget then
		return
	end

	locked = false
	currentTarget = nil
	targetRefreshTimer = 0

	removeReticle()
	removeHighlight()
	clearThreatArrows()
	resetCameraSmoothing()
	restoreCameraType()

	if humanoid then
		humanoid.AutoRotate = true
	end

	camera.FieldOfView = LockOnConfig.DefaultFov

	if shiftLockController then
		shiftLockController:Refresh()
	end
end

local function createReticle(target: BasePart): ()
	if not LockOnConfig.EnableReticle then
		return
	end

	removeReticle()

	reticleBillboard = Instance.new("BillboardGui")
	reticleBillboard.Name = "LockOnReticle"
	reticleBillboard.AlwaysOnTop = true
	reticleBillboard.LightInfluence = 0
	reticleBillboard.ResetOnSpawn = false
	reticleBillboard.Size = UDim2.fromOffset(LockOnConfig.ReticleSize, LockOnConfig.ReticleSize)
	reticleBillboard.StudsOffsetWorldSpace = Vector3.new(0, LockOnConfig.TargetLookHeight, 0)
	reticleBillboard.Parent = target

	reticleImage = Instance.new("ImageLabel")
	reticleImage.Name = "Reticle"
	reticleImage.BackgroundTransparency = 1
	reticleImage.AnchorPoint = Vector2.new(0.5, 0.5)
	reticleImage.Position = UDim2.fromScale(0.5, 0.5)
	reticleImage.Size = UDim2.fromScale(1, 1)
	reticleImage.Image = LockOnConfig.ReticleImage
	reticleImage.ImageColor3 = LockOnConfig.ReticleColor
	reticleImage.ImageTransparency = LockOnConfig.ReticleTransparency
	reticleImage.ScaleType = Enum.ScaleType.Fit
	reticleImage.Parent = reticleBillboard
end

local function createHighlight(target: BasePart): ()
	if not LockOnConfig.EnableHighlight then
		return
	end

	removeHighlight()

	currentHighlight = Instance.new("Highlight")
	currentHighlight.Name = "LockOnHighlight"
	currentHighlight.Adornee = target.Parent
	currentHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	currentHighlight.FillColor = LockOnConfig.HighlightFill
	currentHighlight.OutlineColor = LockOnConfig.HighlightOutline
	currentHighlight.FillTransparency = LockOnConfig.HighlightFillTransparency
	currentHighlight.OutlineTransparency = LockOnConfig.HighlightOutlineTransparency
	currentHighlight.Parent = target.Parent
end

local function setCurrentTarget(target: BasePart): ()
	if not isValidTarget(target) then
		LockOnController:Unlock()
		return
	end

	currentTarget = target
	createReticle(target)
	createHighlight(target)
end

local function scoreTarget(root: BasePart): number
	if not humanoidRootPart then
		return -1
	end

	local offset = root.Position - humanoidRootPart.Position
	local distance = offset.Magnitude
	if distance > LockOnConfig.MaxDistance then
		return -1
	end

	local lookDirection = camera.CFrame.LookVector
	local dot = lookDirection:Dot(offset.Unit)
	local angleScore = (dot + 1) / 2
	local distanceScore = 1 - distance / LockOnConfig.MaxDistance

	return angleScore * LockOnConfig.AngleWeight + distanceScore * LockOnConfig.DistanceWeight
end

local function findBestTarget(): BasePart?
	gatherTargets()

	local bestTarget: BasePart? = nil
	local bestScore = -1

	for _, target in availableTargets do
		local score = scoreTarget(target)
		if score > bestScore then
			bestScore = score
			bestTarget = target
		end
	end

	return bestTarget
end

local function switchTarget(direction: number): ()
	gatherTargets()

	if #availableTargets <= 1 then
		return
	end

	local currentIndex = table.find(availableTargets, currentTarget)
	if not currentIndex then
		setCurrentTarget(availableTargets[1])
		return
	end

	local newIndex = currentIndex + direction
	if newIndex > #availableTargets then
		newIndex = 1
	elseif newIndex < 1 then
		newIndex = #availableTargets
	end

	setCurrentTarget(availableTargets[newIndex])
end

local function getOrCreateArrow(target: BasePart): ImageLabel
	local existing = threatArrows[target]
	if existing then
		return existing
	end

	local arrow = Instance.new("ImageLabel")
	arrow.Name = "ThreatArrow"
	arrow.BackgroundTransparency = 1
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(LockOnConfig.ArrowSize, LockOnConfig.ArrowSize)
	arrow.Image = LockOnConfig.ArrowImage
	arrow.ImageColor3 = LockOnConfig.ArrowColor
	arrow.ImageTransparency = 0
	arrow.ScaleType = Enum.ScaleType.Fit
	arrow.Visible = false
	arrow.ZIndex = 50
	arrow.Parent = screenGui

	threatArrows[target] = arrow
	return arrow
end

local function cleanupDeadArrows(): ()
	for target, arrow in threatArrows do
		if not isValidTarget(target) then
			if arrow then
				arrow:Destroy()
			end
			threatArrows[target] = nil
		end
	end
end

local function updateThreatArrows(): ()
	if not LockOnConfig.EnableThreatArrows or not screenGui then
		return
	end

	cleanupDeadArrows()

	for _, target in availableTargets do
		if not isValidTarget(target) then
			continue
		end

		local arrow = getOrCreateArrow(target)

		if LockOnConfig.HideArrowForCurrentTarget and target == currentTarget then
			arrow.Visible = false
			continue
		end

		local screenPos, onScreen = camera:WorldToViewportPoint(target.Position)
		if onScreen and screenPos.Z > 0 then
			arrow.Visible = false
			continue
		end

		arrow.Visible = true

		local viewportSize = camera.ViewportSize
		local center = viewportSize / 2
		local point = Vector2.new(screenPos.X, screenPos.Y)

		if screenPos.Z < 0 then
			point = center - (point - center)
		end

		local direction = point - center
		if direction.Magnitude < 0.001 then
			direction = Vector2.new(0, -1)
		else
			direction = direction.Unit
		end

		local edgeX = math.clamp(
			center.X + direction.X * LockOnConfig.ArrowDistanceFromCenter,
			LockOnConfig.ArrowEdgePadding,
			viewportSize.X - LockOnConfig.ArrowEdgePadding
		)

		local edgeY = math.clamp(
			center.Y + direction.Y * LockOnConfig.ArrowDistanceFromCenter,
			LockOnConfig.ArrowEdgePadding,
			viewportSize.Y - LockOnConfig.ArrowEdgePadding
		)

		arrow.Position = UDim2.fromOffset(edgeX, edgeY)

		local angle = math.atan2(direction.Y, direction.X)
		arrow.Rotation = math.deg(angle) + 90

		local distance = (humanoidRootPart.Position - target.Position).Magnitude
		local scale = math.clamp(1 + (1 - distance / LockOnConfig.MaxDistance) * 0.45, 1, 1.45)
		arrow.Size = UDim2.fromOffset(LockOnConfig.ArrowSize * scale, LockOnConfig.ArrowSize * scale)
	end
end

local function updateCamera(dt: number): ()
	if not locked then
		return
	end

	if not currentTarget or not isValidTarget(currentTarget) then
		LockOnController:Unlock()
		return
	end

	if not humanoidRootPart then
		return
	end

	targetRefreshTimer += dt
	if targetRefreshTimer >= LockOnConfig.TargetRefreshRate then
		targetRefreshTimer = 0
		gatherTargets()
	end

	local rootPos = humanoidRootPart.Position
	local targetPos = getTargetPoint(currentTarget)

	local flatDirection = Vector3.new(targetPos.X - rootPos.X, 0, targetPos.Z - rootPos.Z)
	if flatDirection.Magnitude <= 0.001 then
		return
	end

	flatDirection = flatDirection.Unit

	local right = flatDirection:Cross(Vector3.yAxis)
	if right.Magnitude <= 0.001 then
		right = Vector3.new(1, 0, 0)
	else
		right = right.Unit
	end

	local desiredCameraPosition = rootPos
		- flatDirection * LockOnConfig.BackOffset
		+ right * LockOnConfig.SideOffset
		+ Vector3.new(0, LockOnConfig.HeightOffset, 0)

	if not smoothedCameraPosition then
		smoothedCameraPosition = desiredCameraPosition
	end

	if not smoothedLookPosition then
		smoothedLookPosition = targetPos
	end

	local cameraAlpha = 1 - math.exp(-LockOnConfig.CameraSmoothness * 60 * dt)

	smoothedCameraPosition = smoothedCameraPosition:Lerp(desiredCameraPosition, cameraAlpha)
	smoothedLookPosition = smoothedLookPosition:Lerp(targetPos, cameraAlpha)

	camera.CFrame = CFrame.lookAt(smoothedCameraPosition, smoothedLookPosition)

	if LockOnConfig.RotateCharacterToTarget then
		local goal = CFrame.lookAt(rootPos, rootPos + flatDirection)
		humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(goal, LockOnConfig.RotationSmoothness)
	end

	if reticleImage then
		if LockOnConfig.ReticleRotates then
			reticleImage.Rotation = (reticleImage.Rotation + LockOnConfig.ReticleRotationSpeed * dt) % 360
		end

		if LockOnConfig.ReticlePulse then
			local pulse = 1 + math.sin(os.clock() * LockOnConfig.ReticlePulseSpeed) * LockOnConfig.ReticlePulseAmount
			reticleImage.Size = UDim2.fromScale(pulse, pulse)
		else
			reticleImage.Size = UDim2.fromScale(1, 1)
		end
	end

	camera.FieldOfView = camera.FieldOfView
		+ (LockOnConfig.LockedFov - camera.FieldOfView) * LockOnConfig.FovSmoothness

	updateThreatArrows()
end

local function lock(): ()
	local target = findBestTarget()
	if not target or not humanoid then
		return
	end

	if not savedCameraType then
		savedCameraType = camera.CameraType
	end

	locked = true
	camera.CameraType = Enum.CameraType.Scriptable

	-- Refresh shift-lock first -- while un-applying it forces AutoRotate back to true, and our
	-- own AutoRotate setting below (needed for RotateCharacterToTarget) must be the last word.
	if shiftLockController then
		shiftLockController:Refresh()
	end

	humanoid.AutoRotate = not LockOnConfig.RotateCharacterToTarget

	setCurrentTarget(target)
	gatherTargets()
end

local function setupInput(): ()
	safeDisconnect(inputConnection)

	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == LockOnConfig.LockKey then
			if locked then
				LockOnController:Unlock()
			else
				lock()
			end
			return
		end

		if locked then
			if input.KeyCode == LockOnConfig.SwitchTargetKey
				or input.UserInputType == LockOnConfig.SwitchTargetMouse
			then
				switchTarget(1)
			end
		end
	end)
end

local function setupCharacter(newCharacter: Model): ()
	local newHumanoid = newCharacter:WaitForChild("Humanoid") :: Humanoid
	if newHumanoid.RigType ~= Enum.HumanoidRigType.R6 then
		-- RigTypeService swaps this transient character out for a fresh R6 model and refires
		-- CharacterAdded -- skip it here to avoid binding to a character that's about to be
		-- destroyed (its RootPart/PrimaryPart may not even be set up yet).
		return
	end

	LockOnController:Unlock()

	character = newCharacter
	humanoid = newHumanoid
	humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	camera = Workspace.CurrentCamera
	camera.FieldOfView = LockOnConfig.DefaultFov

	createScreenGui()
	clearThreatArrows()
	resetCameraSmoothing()

	safeDisconnect(deathConnection)
	deathConnection = humanoid.Died:Connect(function()
		LockOnController:Unlock()
	end)

	setupInput()
end

function LockOnController:IsLocked(): boolean
	return locked
end

function LockOnController:GetCurrentTarget(): BasePart?
	return currentTarget
end

function LockOnController:GetAimDirection(): Vector3?
	if not locked or not currentTarget or not isValidTarget(currentTarget) or not humanoidRootPart then
		return nil
	end

	-- The arrow is spawned and flies from the player's root position on the server (see
	-- BowService.onShoot), not from the camera -- which while locked on sits well off to the
	-- side/back/above the player for the over-the-shoulder framing. Aiming from the camera's
	-- position would compute a direction that visibly diverges from the target once applied from
	-- the player's actual launch point, worse the closer the target is.
	local origin = humanoidRootPart.Position
	local targetPos = getTargetPoint(currentTarget)
	local direction = targetPos - origin

	if direction.Magnitude < 0.001 then
		return nil
	end

	return direction.Unit
end

function LockOnController:KnitStart()
	shiftLockController = Knit.GetController("ShiftLockController")

	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)

	Packets.EquipState.OnClientEvent:Connect(function(isEquipped: boolean)
		if not isEquipped then
			LockOnController:Unlock()
		end
	end)

	RunService:BindToRenderStep("LockOnCamera", Enum.RenderPriority.Camera.Value, updateCamera)
end

function LockOnController:KnitInit() end

return LockOnController
