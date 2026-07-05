local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local ZombieAI = require(script.Parent.Parent.ZombieAI)
local DestroyService = require(script.Parent.Parent.ZombieAI.DestroyService)

local ZOMBIE_TAG = "Zombie"
local SPAWN_CFRAME = CFrame.new(-10, 3, 10)
local ARMS_LOOP_INTERVAL = 2
local LAST_ATTACKER_ATTRIBUTE = "LastAttackerUserId"

local ZombieService = Knit.CreateService({
	Name = "ZombieService",
	Client = {},
})

local currencyService: any = nil

local function getKillRewardPlayer(zombie: Model): Player?
	local killerUserId = zombie:GetAttribute(LAST_ATTACKER_ATTRIBUTE)
	if typeof(killerUserId) == "number" then
		local player = Players:GetPlayerByUserId(killerUserId)
		if player then
			return player
		end
	end

	local humanoid = zombie:FindFirstChildOfClass("Humanoid")
	local creator = humanoid and humanoid:FindFirstChild("creator")
	if creator and creator:IsA("ObjectValue") and creator.Value and creator.Value:IsA("Player") then
		return creator.Value
	end

	return nil
end

local function playArmsLoop(zombie: Model): ()
	task.spawn(function()
		while zombie.Parent do
			local ok, track = pcall(function()
				return zombie.Humanoid:LoadAnimation(zombie.Animations.Arms)
			end)
			if ok then
				track:Play()
			end
			task.wait(ARMS_LOOP_INTERVAL)
		end
	end)
end

-- Recursively fades and queues every part of the corpse for delayed cleanup, matching the
-- original catalog model's death behavior.
local function queueCorpseCleanup(instance: Instance): ()
	for _, child in instance:GetChildren() do
		queueCorpseCleanup(child)
	end

	local delay = if instance:IsA("BasePart") then math.random(5, 10) else 11
	DestroyService:AddItem(instance, delay)
end

local function spawnZombie(cframe: CFrame): Model
	local template = ServerStorage:FindFirstChild("ZombieTemplate")
	if not template then
		warn("ZombieService: ServerStorage.ZombieTemplate not found -- cannot spawn zombie")
		return nil :: any
	end

	local zombie = template:Clone()
	zombie:PivotTo(cframe)
	CollectionService:AddTag(zombie, ZOMBIE_TAG)
	zombie.Parent = Workspace

	playArmsLoop(zombie)

	local ai = ZombieAI.new(zombie)

	zombie.Humanoid.Died:Connect(function()
		ai.Stop()

		local killer = getKillRewardPlayer(zombie)
		if killer and currencyService then
			currencyService:AwardZombieKill(killer)
		end

		queueCorpseCleanup(zombie)
	end)

	return zombie
end

function ZombieService:KnitStart()
	currencyService = Knit.GetService("CurrencyService")
	spawnZombie(SPAWN_CFRAME)
end

function ZombieService:KnitInit() end

return ZombieService
