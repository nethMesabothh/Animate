-- Zombie AI: field-of-view + raycast target detection, pathfinding chase, arm-touch melee
-- damage. Ported from Roblox's official "Drooling Zombie" catalog model (ROBLOX_ZombieAI),
-- with requires rewritten from game.ServerStorage.X to sibling modules (script.X).
local CollectionService = game:GetService("CollectionService")

local HumanoidList = require(script.HumanoidList)
local AIUtilities = require(script.AIUtilities)

local ZOMBIE_TAG = "Zombie"

local ZombieAI = {}

ZombieAI.new = function(model: Model)
	local zombie = {}

	-- CONFIGURATION VARIABLES -- read from model.Configurations, falling back to defaults.
	local configTable = model.Configurations
	local configs = {}
	local function loadConfig(configName: string, defaultValue: number)
		local found = configTable:FindFirstChild(configName)
		configs[configName] = if found then found.Value else defaultValue
	end

	loadConfig("AttackRange", 3)
	loadConfig("FieldOfView", 180)
	loadConfig("AggroRange", 200)
	loadConfig("ChanceOfBoredom", 0.5)
	loadConfig("BoredomDuration", 10)
	loadConfig("Damage", 10)
	loadConfig("DamageCooldown", 1)

	local StateMachine = require(script.StateMachine).new()
	local PathLib = require(script.PathfindingLibrary).new()
	local ZombieTarget: Model? = nil
	local ZombieTargetLastLocation: Vector3? = nil

	local lastBored = os.time()

	-- STATE DEFINITIONS

	-- Idle: stays still. Refreshes the boredom timer on entry to allow a later random transition.
	local IdleState = StateMachine.NewState()
	IdleState.Name = "Idle"
	IdleState.Action = function() end
	IdleState.Init = function()
		lastBored = os.time()
	end

	-- Search: wanders to a random nearby empty spot, increasing the chance of spotting a target.
	local SearchState = StateMachine.NewState()
	SearchState.Name = "Search"
	local lastMoved = os.time()
	local searchTarget: Vector3? = nil
	SearchState.Action = function()
		local now = os.time()
		if now - lastMoved > 2 then
			lastMoved = now
			searchTarget = AIUtilities:FindCloseEmptySpace(model)
		end
		if searchTarget then
			PathLib:MoveToTarget(model, searchTarget)
		end
	end
	SearchState.Init = function()
		lastBored = os.time()
	end

	-- Pursue: target spotted, give chase (pathfinding while far, direct MoveTo once close).
	local PursueState = StateMachine.NewState()
	PursueState.Name = "Pursue"
	PursueState.Action = function()
		if ZombieTarget then
			local distance = (model.HumanoidRootPart.Position - ZombieTarget.HumanoidRootPart.Position).Magnitude
			if distance > configs["AttackRange"] + 5 then
				PathLib:MoveToTarget(model, ZombieTarget.HumanoidRootPart.Position)
			else
				model.Humanoid:MoveTo(ZombieTarget.HumanoidRootPart.Position)
			end
		end
	end

	-- Attack: keep closing on the target and replay the attack animation every 3s. Damage itself
	-- is applied via the arm Touched handlers below, not here.
	local AttackState = StateMachine.NewState()
	AttackState.Name = "Attack"
	local lastAttack = os.time()
	local attackTrack = model.Humanoid:LoadAnimation(model.Animations.Attack)
	AttackState.Action = function()
		model.Humanoid:MoveTo(ZombieTarget.HumanoidRootPart.Position)
		local now = os.time()
		if now - lastAttack > 3 then
			lastAttack = now
			attackTrack:Play()
		end
	end

	-- Hunt: lost sight of the target, head to its last known position until bored.
	local HuntState = StateMachine.NewState()
	HuntState.Name = "Hunt"
	HuntState.Action = function()
		if ZombieTargetLastLocation then
			PathLib:MoveToTarget(model, ZombieTargetLastLocation)
		end
	end
	HuntState.Init = function()
		lastBored = os.time() + configs["BoredomDuration"] / 2
	end

	-- CONDITION DEFINITIONS

	-- CanSeeTarget: true (and sets ZombieTarget) if a live, moving humanoid is within AggroRange,
	-- inside the field-of-view wedge, and has clear line of sight. Other zombies are excluded
	-- from being targets but included in the raycast ignore-list.
	local CanSeeTarget = StateMachine.NewCondition()
	CanSeeTarget.Name = "CanSeeTarget"
	CanSeeTarget.Evaluate = function()
		local humanoids = HumanoidList:GetCurrent()
		local zombies = {}
		local characters = {}
		for _, humanoid in humanoids do
			if humanoid and humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart") and humanoid.Health > 0 and humanoid.WalkSpeed > 0 then
				local rootPart = humanoid.Parent.HumanoidRootPart
				local distance = (model.HumanoidRootPart.Position - rootPart.Position).Magnitude
				if distance <= configs["AggroRange"] then
					if CollectionService:HasTag(humanoid.Parent, ZOMBIE_TAG) then
						table.insert(zombies, humanoid.Parent)
					else
						table.insert(characters, humanoid.Parent)
					end
				end
			end
		end

		local target = AIUtilities:GetClosestVisibleTarget(model, characters, zombies, configs["FieldOfView"])
		if target then
			ZombieTarget = target
			return true
		end
		return false
	end
	CanSeeTarget.TransitionState = PursueState

	local TargetDead = StateMachine.NewCondition()
	TargetDead.Name = "TargetDead"
	TargetDead.Evaluate = function()
		if ZombieTarget and ZombieTarget:FindFirstChildOfClass("Humanoid") then
			return ZombieTarget.Humanoid.Health <= 0
		end
		return true
	end
	TargetDead.TransitionState = IdleState

	local lastHealth = model.Humanoid.Health
	local GotDamaged = StateMachine.NewCondition()
	GotDamaged.Name = "GotDamaged"
	GotDamaged.Evaluate = function()
		if lastHealth > model.Humanoid.Health then
			lastHealth = model.Humanoid.Health
			return true
		end
		lastHealth = model.Humanoid.Health
		return false
	end
	GotDamaged.TransitionState = SearchState

	-- GotBored: random state change so idling zombies don't stand still forever.
	local GotBored = StateMachine.NewCondition()
	GotBored.Name = "GotBored"
	GotBored.Evaluate = function()
		local now = os.time()
		if now - lastBored > configs["BoredomDuration"] then
			local roll = math.random()
			if roll < configs["ChanceOfBoredom"] then
				lastBored = now
				GotBored.TransitionState = if GotBored.TransitionState == SearchState then IdleState else SearchState
				return true
			end
		end
		return false
	end
	GotBored.TransitionState = IdleState

	local WithinRange = StateMachine.NewCondition()
	WithinRange.Name = "WithinRange"
	WithinRange.Evaluate = function()
		if ZombieTarget then
			local distance = (model.HumanoidRootPart.Position - ZombieTarget.HumanoidRootPart.Position).Magnitude
			return distance < configs["AttackRange"]
		end
		return false
	end
	WithinRange.TransitionState = AttackState

	local OutsideRange = StateMachine.NewCondition()
	OutsideRange.Name = "OutsideRange"
	OutsideRange.Evaluate = function()
		if ZombieTarget then
			local distance = (model.HumanoidRootPart.Position - ZombieTarget.HumanoidRootPart.Position).Magnitude
			return distance > configs["AttackRange"]
		end
		return false
	end
	OutsideRange.TransitionState = PursueState

	table.insert(IdleState.Conditions, CanSeeTarget)
	table.insert(IdleState.Conditions, GotDamaged)
	table.insert(IdleState.Conditions, GotBored)

	table.insert(SearchState.Conditions, GotBored)
	table.insert(SearchState.Conditions, CanSeeTarget)

	table.insert(PursueState.Conditions, WithinRange)
	table.insert(PursueState.Conditions, TargetDead)

	table.insert(AttackState.Conditions, OutsideRange)
	table.insert(AttackState.Conditions, TargetDead)

	table.insert(HuntState.Conditions, GotBored)
	table.insert(HuntState.Conditions, CanSeeTarget)

	-- Arm-touch melee damage, independent of the Attack state's own animation-replay cooldown.
	local canHit = true
	local lastHit = os.time()
	local function handleHit(other: BasePart)
		if canHit then
			local enemy = other.Parent
			if enemy and not CollectionService:HasTag(enemy, ZOMBIE_TAG) and enemy:FindFirstChildOfClass("Humanoid") then
				local enemyHumanoid = enemy.Humanoid :: Humanoid
				if enemyHumanoid.WalkSpeed > 0 then
					enemyHumanoid.Health -= configs["Damage"]
					canHit = false
				end
			end
		else
			local now = os.time()
			if now - lastHit > configs["DamageCooldown"] then
				lastHit = now
				canHit = true
			end
		end
	end
	local leftArm = model:FindFirstChild("Left Arm") :: BasePart
	local rightArm = model:FindFirstChild("Right Arm") :: BasePart
	leftArm.Touched:Connect(handleHit)
	rightArm.Touched:Connect(handleHit)

	-- Zombie-zombie repulsion so they don't stack on top of each other while chasing the same
	-- target, applied through the RepulsionForce (BodyForce) baked into the template model.
	task.spawn(function()
		while true do
			task.wait()
			local humanoids = HumanoidList:GetCurrent()
			local nearbyPositions = {}
			for _, humanoid in humanoids do
				if humanoid and humanoid ~= model.Humanoid and humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart") then
					local rootPart = humanoid.Parent.HumanoidRootPart
					local distance = (model.HumanoidRootPart.Position - rootPart.Position).Magnitude
					if distance <= 2.5 then
						table.insert(nearbyPositions, rootPart.Position)
					end
				end
			end
			model.HumanoidRootPart.RepulsionForce.force = AIUtilities:GetRepulsionVector(model.HumanoidRootPart.Position, nearbyPositions)

			local debug = model.Configurations:FindFirstChild("Debug")
			local billboard = model:FindFirstChild("BillboardGui")
			if billboard then
				local label = billboard:FindFirstChild("TextLabel") :: TextLabel?
				if label then
					local isDebug = debug ~= nil and (debug :: BoolValue).Value
					label.Visible = isDebug
					if isDebug and StateMachine.CurrentState then
						label.Text = StateMachine.CurrentState.Name
					end
				end
			end
		end
	end)

	StateMachine.SwitchState(IdleState)

	zombie.Stop = function()
		StateMachine.SwitchState(nil)
	end

	return zombie
end

return ZombieAI
