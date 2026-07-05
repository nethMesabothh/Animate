--!strict

local Packet = require(script.Packet)

return {
	Shoot = Packet("Shoot", Packet.Any),
	EquipState = Packet("EquipState", Packet.Boolean8),
}
