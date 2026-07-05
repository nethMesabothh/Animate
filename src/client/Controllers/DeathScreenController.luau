local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local DeathScreenConfig = require(Shared.DeathScreenConfig)

local createDeathScreenGui = require(script.Parent.Parent.DeathScreenGui)

local DeathScreenController = Knit.CreateController({
	Name = "DeathScreenController",
})

local player = Players.LocalPlayer

local overlayFrame: Frame? = nil
local timerText: TextLabel? = nil
local countdownGeneration = 0
local deathScreenGui: ScreenGui? = nil

local function hideScreen(): ()
	if overlayFrame then
		overlayFrame.Visible = false
	end
end

-- Snapshots every transparency-like property on frame and its descendants (the death screen's
-- final, designed-in values), so fadeIn can drop them all to invisible and tween back up.
local FADE_PROPERTIES = { "BackgroundTransparency", "ImageTransparency", "TextTransparency" }

local function collectFadeTargets(root: Instance): { [Instance]: { [string]: number } }
	local targets = {}

	local function scan(inst: Instance)
		local props = {}
		for _, propName in FADE_PROPERTIES do
			local ok, value = pcall(function()
				return (inst :: any)[propName]
			end)
			if ok and typeof(value) == "number" then
				props[propName] = value
			end
		end
		if next(props) then
			targets[inst] = props
		end

		for _, child in inst:GetChildren() do
			scan(child)
		end
	end
	scan(root)

	return targets
end

local function fadeIn(frame: Frame): ()
	local targets = collectFadeTargets(frame)

	for inst, props in targets do
		for propName in props do
			(inst :: any)[propName] = 1
		end
	end

	frame.Visible = true

	for inst, props in targets do
		TweenService
			:Create(inst, TweenInfo.new(DeathScreenConfig.FadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
			:Play()
	end
end

local function resolveGui(): boolean
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return false
	end

	local deathScreen = playerGui:FindFirstChild("DeathScreen")
	if not deathScreen or not deathScreen:IsA("ScreenGui") then
		return false
	end

	local frame = deathScreen:FindFirstChild("Frame")
	local imageLabel = frame and frame:FindFirstChild("ImageLabel")
	local timer = imageLabel and imageLabel:FindFirstChild("TimerText")

	if not frame or not frame:IsA("Frame") or not timer or not timer:IsA("TextLabel") then
		return false
	end

	deathScreenGui = deathScreen
	overlayFrame = frame
	timerText = timer
	return true
end

local function ensureGui(): ()
	if resolveGui() then
		hideScreen()
		return
	end

	local playerGui = player:WaitForChild("PlayerGui")

	-- Prefer StarterGui clone; wait briefly in case it is still replicating.
	local existing = playerGui:WaitForChild("DeathScreen", 2)
	if existing and existing:IsA("ScreenGui") and resolveGui() then
		hideScreen()
		return
	end

	if existing then
		existing:Destroy()
	end

	createDeathScreenGui(playerGui)
	resolveGui()
	hideScreen()
end

local function runCountdown(): ()
	if not overlayFrame or not timerText then
		ensureGui()
		if not overlayFrame or not timerText then
			warn("DeathScreenController: could not show death screen")
			return
		end
	end

	countdownGeneration += 1
	local generation = countdownGeneration

	if deathScreenGui then
		deathScreenGui.Enabled = true
	end
	fadeIn(overlayFrame)

	for secondsLeft = DeathScreenConfig.RespawnTime, 0, -1 do
		if generation ~= countdownGeneration then
			return
		end

		timerText.Text = DeathScreenConfig.TimerPrefix .. secondsLeft
		task.wait(1)
	end

	if generation == countdownGeneration then
		hideScreen()
	end
end

local function onDied(): ()
	task.spawn(runCountdown)
end

local function onCharacterAdded(character: Model): ()
	countdownGeneration += 1
	hideScreen()

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		return
	end

	humanoid.Died:Connect(onDied)
end

function DeathScreenController:KnitStart()
	task.defer(ensureGui)

	if player.Character then
		onCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			ensureGui()
			onCharacterAdded(character)
		end)
	end)

	local playerGui = player:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "DeathScreen" and child:IsA("ScreenGui") then
			task.defer(function()
				resolveGui()
				hideScreen()
			end)
		end
	end)
end

function DeathScreenController:KnitInit() end

return DeathScreenController
