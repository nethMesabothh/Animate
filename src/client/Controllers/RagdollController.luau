local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local RagdollController = Knit.CreateController({
	Name = "RagdollController",
})

local Settings = {
	CleanupTime = 4, -- How long the ragdoll body sticks around after death.
}

-- Limb socket data relative to the Torso, R6-specific (Right Arm/Left Arm/Right Leg/Left Leg).
local AttachmentData = {
	RA = { "Right Arm", CFrame.new(0, 0.5, 0), CFrame.new(1.5, 0.5, 0) },
	LA = { "Left Arm", CFrame.new(0, 0.5, 0), CFrame.new(-1.5, 0.5, 0) },
	RL = { "Right Leg", CFrame.new(0, 0.5, 0), CFrame.new(0.5, -1.5, 0) },
	LL = { "Left Leg", CFrame.new(0, 0.5, 0), CFrame.new(-0.5, -1.5, 0) },
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function createCollisionPart(): BasePart
	local part = Instance.new("Part")
	part.Name = "CP"
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.new(1, 1.5, 1)
	part.Transparency = 1
	return part
end

local function onDied(character: Model): ()
	character.Archivable = true
	local ragdoll = character:Clone()
	character.Archivable = false

	-- Strip the real character down to just the Humanoid -- the clone becomes the visible corpse.
	for _, obj in character:GetChildren() do
		if not obj:IsA("Humanoid") then
			obj:Destroy()
		end
	end

	-- Remove anything that would keep the clone rigid or scripted: ForceFields, the root part's
	-- joints, Motor6Ds/Welds (except the head attachment), scripts, particles.
	local function scan(instances: { Instance })
		for _, inst in instances do
			scan(inst:GetChildren())
			if
				inst:IsA("ForceField")
				or inst.Name == "HumanoidRootPart"
				or ((inst:IsA("Weld") or inst:IsA("Motor6D")) and inst.Name ~= "HeadWeld" and inst.Name ~= "AttachementWeld")
			then
				inst:Destroy()
			end
		end
	end
	scan(ragdoll:GetChildren())

	local function scanClean(inst: Instance)
		for _, obj in inst:GetChildren() do
			scanClean(obj)
			if
				obj:IsA("Script")
				or obj:IsA("LocalScript")
				or ((obj:IsA("Weld") or obj:IsA("Motor6D")) and obj.Name ~= "AttachementWeld")
				or obj:IsA("ForceField")
				or obj:IsA("ParticleEmitter")
			then
				obj:Destroy()
			elseif obj:IsA("BasePart") then
				obj.AssemblyLinearVelocity = Vector3.zero
				obj.AssemblyAngularVelocity = Vector3.zero
				if obj.Parent and obj.Parent:IsA("Accessory") then
					obj.CanCollide = false
				end
			end
		end
	end
	scanClean(ragdoll)

	local ragdollHumanoid = ragdoll:FindFirstChildOfClass("Humanoid")
	if not ragdollHumanoid then
		ragdoll:Destroy()
		return
	end
	ragdollHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	ragdollHumanoid.PlatformStand = true
	ragdollHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	ragdollHumanoid.Name = "RagdollHumanoid"

	local torso = ragdoll:FindFirstChild("Torso") :: BasePart?
	if torso then
		torso.AssemblyLinearVelocity = Vector3.new(math.random(), 0.0000001, math.random()).Unit * 5
			+ Vector3.new(0, 0.15, 0)

		local head = ragdoll:FindFirstChild("Head") :: BasePart?
		if head then
			camera.CameraSubject = head

			local headWeld = Instance.new("Weld")
			headWeld.Part0 = torso
			headWeld.Part1 = head
			headWeld.C0 = CFrame.new(0, 1.5, 0)
			headWeld.Parent = torso
		end

		for tag, data in AttachmentData do
			local limbName, limbOffset, torsoOffset = data[1], data[2], data[3]
			local limb = ragdoll:FindFirstChild(limbName) :: BasePart?
			if limb then
				local limbAttachment = Instance.new("Attachment")
				limbAttachment.Name = tag
				limbAttachment.CFrame = limbOffset
				limbAttachment.Parent = limb

				local torsoAttachment = Instance.new("Attachment")
				torsoAttachment.Name = tag
				torsoAttachment.CFrame = torsoOffset
				torsoAttachment.Parent = torso

				local socket = Instance.new("BallSocketConstraint")
				socket.Name = tag .. "_SOCKET"
				socket.Attachment0 = torsoAttachment
				socket.Attachment1 = limbAttachment
				socket.Radius = 0
				socket.Parent = torso

				limb.CanCollide = false

				local collisionPart = createCollisionPart()
				local weld = Instance.new("Weld")
				weld.C0 = CFrame.new(0, -0.25, 0)
				weld.Part0 = limb
				weld.Part1 = collisionPart
				weld.Parent = collisionPart
				collisionPart.Parent = ragdoll
			end
		end
	end

	ragdoll.Parent = workspace
	Debris:AddItem(ragdoll, Settings.CleanupTime)

	ragdollHumanoid.MaxHealth = 100
	ragdollHumanoid.Health = ragdollHumanoid.MaxHealth
end

local function onCharacterAdded(character: Model): ()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		onDied(character)
	end)
end

function RagdollController:KnitStart()
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

function RagdollController:KnitInit() end

return RagdollController
