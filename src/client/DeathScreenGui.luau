local function createDeathScreenGui(parent: Instance): ScreenGui
	local deathScreen = Instance.new("ScreenGui")
	deathScreen.Name = "DeathScreen"
	deathScreen.ResetOnSpawn = false
	deathScreen.IgnoreGuiInset = true
	deathScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	deathScreen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	deathScreen.DisplayOrder = 100
	deathScreen.Enabled = true
	deathScreen.Parent = parent

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.45
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Visible = false
	frame.Parent = deathScreen

	local overlay = Instance.new("ImageLabel")
	overlay.Name = "ImageLabel"
	overlay.BackgroundTransparency = 1
	overlay.Image = "rbxassetid://11475237538"
	overlay.ImageColor3 = Color3.fromRGB(146, 146, 146)
	overlay.ImageTransparency = 0.15
	overlay.Position = UDim2.fromScale(0, 0)
	overlay.ScaleType = Enum.ScaleType.Stretch
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Parent = frame

	local skull = Instance.new("ImageLabel")
	skull.Name = "SkullIcon"
	skull.BackgroundTransparency = 1
	skull.Image = "rbxassetid://11475392683"
	skull.AnchorPoint = Vector2.new(0.5, 0)
	skull.Position = UDim2.fromScale(0.5, 0.18)
	skull.ScaleType = Enum.ScaleType.Fit
	skull.Size = UDim2.fromOffset(184, 196)
	skull.Parent = overlay

	local title = Instance.new("TextLabel")
	title.Name = "TitleText"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.Text = "YOU DIED"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 60
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.48)
	title.Size = UDim2.fromOffset(400, 60)
	title.Parent = overlay

	local quote = Instance.new("TextLabel")
	quote.Name = "QuoteText"
	quote.BackgroundTransparency = 1
	quote.Font = Enum.Font.FredokaOne
	quote.Text =
		"\"Many of life's failures are people who did not realize how close they were to success when they gave up.\""
	quote.TextColor3 = Color3.fromRGB(255, 255, 255)
	quote.TextSize = 18
	quote.TextWrapped = true
	quote.AnchorPoint = Vector2.new(0.5, 0.5)
	quote.Position = UDim2.fromScale(0.5, 0.58)
	quote.Size = UDim2.fromOffset(500, 80)
	quote.Parent = overlay

	local timer = Instance.new("TextLabel")
	timer.Name = "TimerText"
	timer.BackgroundTransparency = 1
	timer.Font = Enum.Font.FredokaOne
	timer.Text = "Respawning in 3"
	timer.TextColor3 = Color3.fromRGB(255, 255, 255)
	timer.TextSize = 24
	timer.AnchorPoint = Vector2.new(0.5, 0.5)
	timer.Position = UDim2.fromScale(0.5, 0.72)
	timer.Size = UDim2.fromOffset(300, 50)
	timer.Parent = overlay

	return deathScreen
end

return createDeathScreenGui
