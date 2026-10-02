local TARGET_PLACE = 107780766224326
local BASE = (_G.__EggBase or "http://127.0.0.1:34877/") .. "studio/"

return function(names)
	if game.PlaceId ~= TARGET_PLACE then
		print("WRONG_PLACE " .. game.Name)
		return false
	end
	for _, name in names do
		local source = game:GetService("HttpService"):GetAsync(BASE .. name .. ".lua?t=" .. tostring(os.clock()), true)
		local chunk, err = loadstring(source, name)
		if not chunk then
			error(err)
		end
		chunk()
	end
	return true
end
