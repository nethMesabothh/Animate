local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local clampMagnitude = require(Shared.ClampMagnitude)

local SmoothCameraController = Knit.CreateController({
	Name = "SmoothCameraController",
})

local Settings = {
	HorizontalSpeed = 20,
	VerticalSpeed = 5,
	MaxDistance = 8,
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local root: BasePart? = nil
local lockOnController: any = nil

local offsetXZ = Vector3.zero
local offsetY = Vector3.zero

local function onCharacterAdded(character: Model): ()
	root = character:WaitForChild("HumanoidRootPart") :: BasePart
end

local function onRenderStep(deltaTime: number): ()
	if not root then
		return
	end

	if lockOnController and lockOnController:IsLocked() then
		return
	end

	-- Offset the camera opposite the character's velocity so it lags behind movement slightly.
	offsetXZ -= Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z) * deltaTime
	offsetY -= Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) * deltaTime

	-- Clamp so fast movement doesn't push the character out of view.
	offsetXZ = clampMagnitude(offsetXZ, Settings.MaxDistance)
	offsetY = clampMagnitude(offsetY, Settings.MaxDistance)

	-- Lerp the offset back to zero so the camera doesn't get left behind permanently.
	offsetXZ = offsetXZ:Lerp(Vector3.zero, math.min(deltaTime * Settings.HorizontalSpeed, 1))
	offsetY = offsetY:Lerp(Vector3.zero, math.min(deltaTime * Settings.VerticalSpeed, 1))

	camera.CFrame += offsetXZ + offsetY
end

function SmoothCameraController:KnitStart()
	lockOnController = Knit.GetController("LockOnController")

	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	-- Runs just after Roblox's own camera update so the lag offset layers on top cleanly.
	RunService:BindToRenderStep("CameraSmoothing", Enum.RenderPriority.Camera.Value + 1, onRenderStep)
end

function SmoothCameraController:KnitInit() end

return SmoothCameraController
