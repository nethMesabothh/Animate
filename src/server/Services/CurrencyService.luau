local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local EconomyConfig = require(Shared.EconomyConfig)

local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {},
})

local cashValues: { [Player]: IntValue } = {}

local function getOrCreateCash(player: Player): IntValue
	local existing = cashValues[player]
	if existing then
		return existing
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cash = leaderstats:FindFirstChild(EconomyConfig.LeaderstatName)
	if not cash then
		cash = Instance.new("IntValue")
		cash.Name = EconomyConfig.LeaderstatName
		cash.Value = EconomyConfig.StartingCash
		cash.Parent = leaderstats
	end

	cashValues[player] = cash :: IntValue
	return cash :: IntValue
end

function CurrencyService:GetCash(player: Player): number
	return getOrCreateCash(player).Value
end

function CurrencyService:AddCash(player: Player, amount: number): ()
	if amount <= 0 then
		return
	end

	getOrCreateCash(player).Value += amount
end

function CurrencyService:AwardZombieKill(player: Player): ()
	self:AddCash(player, EconomyConfig.ZombieKillReward)
end

function CurrencyService:KnitStart()
	for _, player in Players:GetPlayers() do
		getOrCreateCash(player)
	end

	Players.PlayerAdded:Connect(getOrCreateCash)
	Players.PlayerRemoving:Connect(function(player: Player)
		cashValues[player] = nil
	end)
end

function CurrencyService:KnitInit() end

return CurrencyService
