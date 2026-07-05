local UserInputService = game:GetService("UserInputService")

-- Reference-counted so multiple systems (bow aiming, shift lock) can request the same
-- locked-camera cursor without one clearing it out from under the other.
local CursorOverride = {}

local ICON = "rbxassetid://9102463858"
local count = 0

function CursorOverride.Push(): ()
	count += 1
	UserInputService.MouseIcon = ICON
end

function CursorOverride.Pop(): ()
	count = math.max(0, count - 1)
	if count == 0 then
		UserInputService.MouseIcon = ""
	end
end

return CursorOverride
