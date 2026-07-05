local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local Packets = require(Shared.Packets)

local Assets = ReplicatedStorage.Assets
local Models = Assets.Models

local ArrowHitSound = SoundService["Arrow Hit"]

local Settings = {
	["Travel Time"] = 5,
	["Gravity Delay"] = 1,

	["Start CFrame Offset"] = CFrame.new(1, 1, -2),

	Speed = 90,
	Damage = 15,
}

local PICKUP_CFRAME = CFrame.new(5, 2, 0)

local BowService = Knit.CreateService({
	Name = "BowService",
	Client = {},
})

-- Each player who owns a bow gets one persistent Tool instance (so it shows up in the
-- CustomInventory hotbar/backpack UI) that toggles between Character (equipped, welded to Left
-- Arm) and Backpack (stowed via the inventory UI) -- there's no world-drop, equip/unequip only.
local playerTools: { [Player]: Tool } = {}
local worldPickup: Model? = nil

local function CreateArrow()
	local Arrow = Models.Arrow:Clone()

	Arrow.Parent = Workspace.Debris
	Arrow.Anchored = true
	Arrow.CanCollide = false

	return Arrow
end

local function isEquipped(Player: Player): boolean
	local tool = playerTools[Player]
	return tool ~= nil and tool.Parent == Player.Character
end

local function onShoot(Player: Player, LookDirection: Vector3)
	if typeof(LookDirection) ~= "Vector3" then
		return
	end

	if not isEquipped(Player) then
		return
	end

	local Hit = false

	local Character = Player.Character :: Model
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") :: Part

	local Arrow = CreateArrow() :: UnionOperation

	local StartCFrame = HumanoidRootPart.CFrame * Settings["Start CFrame Offset"]

	local Direction = LookDirection.Unit
	local Gravity = Vector3.new(0, -Workspace.Gravity * 1.15, 0)
	local StartPosition = StartCFrame.Position

	local Time = Instance.new("NumberValue")

	Time.Parent = Arrow
	Arrow.CFrame = StartCFrame

	Arrow.Touched:Connect(function(Part: BasePart)
		if Hit then
			return
		end

		if not Part:IsA("BasePart") then
			return
		end

		local Model = Part:FindFirstAncestorOfClass("Model")
		local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")

		Hit = true

		if Humanoid and Model ~= Character then
			local Sound = ArrowHitSound:Clone()

			Sound.Parent = Model.PrimaryPart

			Sound:Remove()
			Humanoid:TakeDamage(Settings.Damage)
		end

		Time:Destroy()
		Arrow:Destroy()
	end)

	Time.Changed:Connect(function(Value: number)
		local GravityTime = math.max(0, Value - 1)

		local Velocity = Direction * Settings.Speed + Gravity * GravityTime

		local Position = StartPosition
			+ Direction * Settings.Speed * Value
			+ 0.5 * Gravity * (GravityTime ^ 2)

		local OrientationOffset = CFrame.Angles(math.rad(-90), 0, 0)

		Arrow.CFrame = CFrame.lookAt(Position, Position + Velocity) * OrientationOffset
	end)

	TweenService
		:Create(Time, TweenInfo.new(Settings["Travel Time"], Enum.EasingStyle.Linear), { Value = Settings["Travel Time"] })
		:Play()

	Debris:AddItem(Time, Settings["Travel Time"])
end

local function attachVisual(visual: Model, Character: Model): ()
	local leftArm = Character:FindFirstChild("Left Arm")
	if not leftArm then
		-- Character may still be mid-spawn (R6 swap from RigTypeService, or limbs not yet
		-- replicated) -- wait briefly rather than silently failing to equip.
		leftArm = Character:WaitForChild("Left Arm", 3)
		if not leftArm then
			warn(Character.Name, "could not equip bow: no Left Arm found on character")
			return
		end
	end

	local RootPart = visual:FindFirstChild("RootPart") :: BasePart?
	if not RootPart then
		warn("could not equip bow: visual model is missing RootPart")
		return
	end

	local Weld = visual:FindFirstChild("Weld") :: Weld?
	if not Weld then
		-- detachVisual destroys the Weld when unequipping, so it needs recreating here on
		-- every subsequent equip -- it only exists on the very first attach otherwise.
		Weld = Instance.new("Weld")
		Weld.Name = "Weld"
	end

	local Body = visual.PT_Bow_01_a_body
	local BodyMotor = Body.PT_Bow_01_a_bodyMotor6D

	local String = visual.PT_Bow_01_a_string
	local StringMotor = String.PT_Bow_01_a_stringMotor6D

	RootPart.Anchored = false
	RootPart.CanCollide = false

	Weld.Parent = leftArm
	Weld.Part0 = leftArm
	Weld.Part1 = RootPart

	BodyMotor.Part0 = RootPart
	BodyMotor.Part1 = Body

	StringMotor.Part0 = RootPart
	StringMotor.Part1 = String
end

local function detachVisual(visual: Model): ()
	local weld = visual:FindFirstChild("Weld")
	if weld then
		weld:Destroy()
	end
end

local function createBowTool(Player: Player): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Bow"
	tool.RequiresHandle = false
	tool.CanBeDropped = false

	local visual = Models.Bow:Clone()
	visual.Name = "BowVisual"
	visual.Parent = tool

	tool.Equipped:Connect(function()
		local Character = tool.Parent
		if Character and Character:IsA("Model") then
			attachVisual(visual, Character)
		end
		Packets.EquipState:FireClient(Player, true)
	end)

	tool.Unequipped:Connect(function()
		detachVisual(visual)
		Packets.EquipState:FireClient(Player, false)
	end)

	return tool
end

local function createWorldPickup(): ()
	if worldPickup then
		return
	end

	local Bow = Models.Bow:Clone()
	Bow.Name = "BowPickup"
	Bow:PivotTo(PICKUP_CFRAME)

	local RootPart = Bow.RootPart :: BasePart
	RootPart.Anchored = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = "Bow"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = RootPart

	prompt.Triggered:Connect(function(Player: Player)
		if playerTools[Player] then
			return
		end

		local Character = Player.Character
		if not Character then
			return
		end

		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if not Humanoid then
			return
		end

		Bow:Destroy()
		worldPickup = nil

		local tool = createBowTool(Player)
		playerTools[Player] = tool
		Humanoid:EquipTool(tool)
	end)

	Bow.Parent = Workspace
	worldPickup = Bow
end

local function onCharacterAdded(Player: Player, Character: Model): ()
	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	if Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		-- RigTypeService swaps this character out for a fresh R6 model right after spawn,
		-- which fires CharacterAdded again -- skip the transient R15 character to avoid
		-- indexing "Left Arm", which only exists on R6.
		return
	end

	-- Re-equip automatically across respawns for players who already own the bow.
	local tool = playerTools[Player]
	if tool then
		Humanoid:EquipTool(tool)
	end
end

function BowService:KnitStart()
	Packets.Shoot.OnServerEvent:Connect(onShoot)

	Players.PlayerAdded:Connect(function(Player: Player)
		Player.CharacterAdded:Connect(function(Character)
			onCharacterAdded(Player, Character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(Player: Player)
		local tool = playerTools[Player]
		if tool then
			tool:Destroy()
		end
		playerTools[Player] = nil
	end)

	createWorldPickup()
end

function BowService:KnitInit() end

return BowService
