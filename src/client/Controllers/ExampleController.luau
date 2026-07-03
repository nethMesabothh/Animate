local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local ExampleController = Knit.CreateController({
	Name = "ExampleController",
})

function ExampleController:KnitStart()
	local ExampleService = Knit.GetService("ExampleService")
	print(ExampleService:Ping())
end

function ExampleController:KnitInit()
end

return ExampleController
