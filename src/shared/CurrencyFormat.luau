local CurrencyFormat = {}

function CurrencyFormat.format(value: number): string
	local decimalPlaces = 2

	if value < 1000 then
		return tostring(math.floor(value + 0.5))
	end

	local abbreviations = { "", "K", "M", "B", "T" }
	local exponent = math.floor(math.log(math.max(1, math.abs(value)), 1000))
	local suffix = abbreviations[1 + exponent] or ("e+" .. exponent)
	local normalized = math.floor(value * ((10 ^ decimalPlaces) / (1000 ^ exponent))) / (10 ^ decimalPlaces)

	return string.format("%." .. decimalPlaces .. "f%s", normalized, suffix)
end

return CurrencyFormat
