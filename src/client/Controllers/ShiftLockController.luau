local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local CursorOverride = require(Shared.CursorOverride)

local ShiftLockController = Knit.CreateController({
	Name = "ShiftLockController",
})

local CAMERA_OFFSET = Vector3.new(1.75, 0, 0)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil
local locked = false

local function setLocked(isLocked: boolean): ()
	if isLocked == locked then
		return
	end
	locked = isLocked

	if isLocked then
		CursorOverride.Push()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		humanoid.AutoRotate = false
		humanoid.CameraOffset = CAMERA_OFFSET
	else
		CursorOverride.Pop()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		humanoid.AutoRotate = true
		humanoid.CameraOffset = Vector3.zero
	end
end

local function onCharacterAdded(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	locked = false
end

-- Shift lock is entirely driven by the bow's equip state -- no manual toggle. Equipping the bow
-- always locks the camera; dropping/unequipping it always frees it, no exceptions.
function ShiftLockController:SetForced(isForced: boolean): ()
	setLocked(isForced)
end

function ShiftLockController:KnitStart()
	if Player.Character then
		onCharacterAdded(Player.Character)
	end
	Player.CharacterAdded:Connect(onCharacterAdded)

	RunService.RenderStepped:Connect(function()
		if not locked or not rootPart then
			return
		end

		local lookVector = Camera.CFrame.LookVector
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flatLook.Magnitude > 0 then
			rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatLook)
		end
	end)
end

function ShiftLockController:KnitInit() end

return ShiftLockController
