local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.Short(value: number): string
	value = tonumber(value) or 0
	if value < 1000 then
		return tostring(math.floor(value))
	end
	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local text = value >= 100 and ("%.0f"):format(value) or value >= 10 and ("%.1f"):format(value) or ("%.2f"):format(value)
	text = text:gsub("%.?0+$", "")
	return text .. SUFFIXES[index]
end

function Format.Percent(fraction: number): string
	return ("%.1f%%"):format(math.clamp(fraction, 0, 1) * 100)
end

return Format
