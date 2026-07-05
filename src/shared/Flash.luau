local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Flash = {}
Flash.__index = Flash

function Flash:Play(attacker: Model, duration: number)
	duration = duration or .3

	self.Highlight = Instance.new("Highlight", attacker)
	self.Highlight.Adornee = attacker
	self.Highlight.FillTransparency = 1
	self.Highlight.FillColor = Color3.new(1, 1, 1)
	self.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	self.Highlight.OutlineColor = Color3.new(1, 1, 1)
	self.Highlight.OutlineTransparency = 1

	local tweenIn = TweenService:Create(
		self.Highlight,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FillTransparency = 0.2 }
	)

	local tweenOut = TweenService:Create(
		self.Highlight,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ FillTransparency = 1 }
	)

	tweenIn:Play()

	tweenIn.Completed:Connect(function()
		tweenOut:Play()
	end)

	Debris:AddItem(self.Highlight, duration)
end

return Flash
