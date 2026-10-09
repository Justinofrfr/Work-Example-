local parts = {}
local ids = {}
for _, d in workspace:GetDescendants() do
	if d:IsA("Part") and d.Shape == Enum.PartType.Block and d.Transparency < 0.9 then
		table.insert(parts, d)
		ids[d] = #parts
	end
end
local function faces(p)
	local cf, s = p.CFrame, p.Size / 2
	local list = {}
	for _, axis in { { cf.RightVector, s.X, s.Y, s.Z, cf.UpVector, cf.LookVector }, { cf.UpVector, s.Y, s.X, s.Z, cf.RightVector, cf.LookVector }, { cf.LookVector, s.Z, s.X, s.Y, cf.RightVector, cf.UpVector } } do
		for sign = -1, 1, 2 do
			local n = axis[1] * sign
			table.insert(list, { N = n, C = cf.Position + n * axis[2], A = axis[5], B = axis[6], HA = axis[3], HB = axis[4] })
		end
	end
	return list
end
local params = OverlapParams.new()
local counts, seen, total = {}, {}, 0
local hits = {}
for _, p in parts do
	local fa = faces(p)
	for _, q in workspace:GetPartBoundsInBox(p.CFrame, p.Size + Vector3.new(0.2, 0.2, 0.2), params) do
		local qi = ids[q]
		if qi and q ~= p then
			local a, b = math.min(ids[p], qi), math.max(ids[p], qi)
			local key = a * 1000000 + b
			if not seen[key] then
				seen[key] = true
				local hit = false
				for _, f in fa do
					for _, g in faces(q) do
						if f.N:Dot(g.N) > 0.9999 and math.abs((g.C - f.C):Dot(f.N)) < (workspace:GetAttribute("ZFightTolerance") or 0.02) then
							local d = g.C - f.C
							if math.abs(d:Dot(f.A)) < f.HA + g.HA - 0.05 and math.abs(d:Dot(f.B)) < f.HB + g.HB - 0.05 then
								hit = true
							end
						end
					end
				end
				if hit then
					total += 1
					local names = { p:GetFullName():gsub("Workspace%.", ""):gsub("%d+", "#"), (q:GetFullName():gsub("Workspace%.", ""):gsub("%d+", "#")) }
					table.sort(names)
					local k = names[1] .. "  <>  " .. names[2]
					counts[k] = (counts[k] or 0) + 1
					table.insert(hits, { p, q })
				end
			end
		end
	end
end
local out = {}
for k, v in counts do
	table.insert(out, { k, v })
end
table.sort(out, function(x, y)
	return x[2] > y[2]
end)
print("parts", #parts, "zfight pairs", total)
for i = 1, math.min(50, #out) do
	print(out[i][2], out[i][1])
end
return hits
