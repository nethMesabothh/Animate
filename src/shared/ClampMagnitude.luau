local function clampMagnitude(v3: Vector3, magnitude: number): Vector3
	if v3.Magnitude > magnitude then
		return v3.Unit * magnitude
	else
		return v3
	end
end

return clampMagnitude
