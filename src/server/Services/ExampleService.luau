local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local ExampleService = Knit.CreateService({
	Name = "ExampleService",
	Client = {},
})

function ExampleService.Client:Ping(_player: Player): string
	return "pong"
end

function ExampleService:KnitStart()
	print("ExampleService started")
end

function ExampleService:KnitInit()
end

return ExampleService
