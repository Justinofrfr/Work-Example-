local HttpService = game:GetService("HttpService")

local source = HttpService:GetAsync("http://127.0.0.1:34877/studio/ZFight.lua?t=" .. tostring(os.clock()), true)
local fixed = {}
for _ = 1, 10 do
	local hits = loadstring(source)()
	if #hits == 0 then
		break
	end
	local pass = {}
	for _, pair in hits do
		local a, b = pair[1], pair[2]
		local small = a.Size.X * a.Size.Y * a.Size.Z <= b.Size.X * b.Size.Y * b.Size.Z and a or b
		if not pass[small] then
			pass[small] = true
			fixed[small] = true
			small.Size = Vector3.new(math.max(small.Size.X - 0.2, 0.05), math.max(small.Size.Y - 0.2, 0.05), math.max(small.Size.Z - 0.2, 0.05))
		end
	end
end
local count = 0
for _ in fixed do
	count += 1
end
print("ZFight fixed parts", count)
