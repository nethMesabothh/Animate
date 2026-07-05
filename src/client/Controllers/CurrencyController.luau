local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Shared = ReplicatedStorage.Shared
local CurrencyFormat = require(Shared.CurrencyFormat)
local EconomyConfig = require(Shared.EconomyConfig)

local CurrencyController = Knit.CreateController({
	Name = "CurrencyController",
})

local RENDER_STEP_NAME = "UpdateCurrency"
local ANIMATION_DURATION = 1
local POP_SCALE = 1.2
local WAIT_SECONDS = 30

local player = Players.LocalPlayer
local displayedValue = 0

local cashConnection: RBXScriptConnection? = nil
local boundTextLabel: TextLabel? = nil
local boundUiScale: UIScale? = nil

local function disconnectCash(): ()
	if cashConnection then
		cashConnection:Disconnect()
		cashConnection = nil
	end

	boundTextLabel = nil
	boundUiScale = nil
end

local function animateValueChange(textLabel: TextLabel, targetValue: number): ()
	local startValue = displayedValue
	local startTime = os.clock()

	local function step()
		local elapsedTime = os.clock() - startTime
		local alpha = math.clamp(elapsedTime / ANIMATION_DURATION, 0, 1)
		displayedValue = startValue + (targetValue - startValue) * alpha
		textLabel.Text = CurrencyFormat.format(displayedValue)

		if alpha >= 1 then
			RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
		end
	end

	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Last.Value, step)
end

local function playPopAnimation(uiScale: UIScale): ()
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local enlargeTween = TweenService:Create(uiScale, tweenInfo, { Scale = POP_SCALE })
	local shrinkTween = TweenService:Create(uiScale, tweenInfo, { Scale = 1 })

	enlargeTween:Play()
	enlargeTween.Completed:Connect(function()
		shrinkTween:Play()
	end)
end

local function refreshDisplay(animate: boolean): ()
	if not boundTextLabel then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild(EconomyConfig.LeaderstatName)
	if not cash or not cash:IsA("IntValue") then
		return
	end

	if animate and cash.Value ~= displayedValue then
		animateValueChange(boundTextLabel, cash.Value)
		if boundUiScale then
			playPopAnimation(boundUiScale)
		end
	else
		displayedValue = cash.Value
		boundTextLabel.Text = CurrencyFormat.format(cash.Value)
	end
end

local function bindCashDisplay(textLabel: TextLabel, cash: IntValue): ()
	disconnectCash()

	local uiScale = textLabel:FindFirstChild("UIScale") :: UIScale?
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "UIScale"
		uiScale.Scale = 1
		uiScale.Parent = textLabel
	end

	boundTextLabel = textLabel
	boundUiScale = uiScale

	cashConnection = cash:GetPropertyChangedSignal("Value"):Connect(function()
		refreshDisplay(true)
	end)

	refreshDisplay(false)
end

local function tryBind(): boolean
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return false
	end

	local topBar = playerGui:FindFirstChild("TopBar")
	if not topBar then
		return false
	end

	local cashDisplay = topBar:FindFirstChild("CashDisplay")
	local textLabel = cashDisplay and cashDisplay:FindFirstChild("TextLabel")
	if not textLabel or not textLabel:IsA("TextLabel") then
		return false
	end

	if boundTextLabel == textLabel then
		refreshDisplay(false)
		return true
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild(EconomyConfig.LeaderstatName)
	if not cash or not cash:IsA("IntValue") then
		return false
	end

	bindCashDisplay(textLabel, cash)
	return true
end

local function setupGui(): ()
	local playerGui = player:WaitForChild("PlayerGui")
	local leaderstats = player:WaitForChild("leaderstats", WAIT_SECONDS)
	if not leaderstats then
		warn("CurrencyController: leaderstats not found")
		return
	end

	leaderstats:WaitForChild(EconomyConfig.LeaderstatName, WAIT_SECONDS)

	if tryBind() then
		return
	end

	playerGui:WaitForChild("TopBar", WAIT_SECONDS)
	tryBind()
end

local function onCharacterAdded(_character: Model): ()
	disconnectCash()
	task.defer(setupGui)
end

function CurrencyController:KnitStart()
	task.defer(setupGui)

	player.CharacterAdded:Connect(onCharacterAdded)

	local playerGui = player:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TopBar" and child:IsA("ScreenGui") then
			task.defer(tryBind)
		end
	end)

	player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			task.defer(tryBind)
		end
	end)
end

function CurrencyController:KnitInit() end

return CurrencyController
