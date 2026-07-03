local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

for _, module in script.Controllers:GetChildren() do
	if module:IsA("ModuleScript") then
		require(module)
	end
end

Knit.Start():catch(warn)
