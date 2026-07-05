local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local DeathScreenConfig = require(Shared.DeathScreenConfig)

local DeathScreenService = Knit.CreateService({
	Name = "DeathScreenService",
	Client = {},
})

function DeathScreenService:KnitStart()
	Players.RespawnTime = DeathScreenConfig.RespawnTime
end

function DeathScreenService:KnitInit() end

return DeathScreenService
