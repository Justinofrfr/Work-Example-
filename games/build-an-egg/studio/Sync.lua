local HttpService = game:GetService("HttpService")

local BASE = "http://127.0.0.1:34877/"

local roots = {
	{ Path = "src/shared/", Parent = game:GetService("ReplicatedStorage"), Name = "Shared" },
	{ Path = "src/server/", Parent = game:GetService("ServerScriptService"), Name = "Server" },
	{ Path = "src/client/", Parent = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), Name = "Client" },
}

local function fetch(path)
	return HttpService:GetAsync(BASE .. path .. "?t=" .. tostring(os.clock()), true)
end

local function list(path)
	local items = {}
	for href in fetch(path):gmatch('href="([^"?]+)"') do
		if not href:find("^%.") and not href:find("^/") then
			table.insert(items, href)
		end
	end
	return items
end

local function classify(fileName)
	local name = fileName:match("^(.-)%.server%.luau?$")
	if name then
		return name, "Script"
	end
	name = fileName:match("^(.-)%.client%.luau?$")
	if name then
		return name, "LocalScript"
	end
	name = fileName:match("^(.-)%.luau?$")
	if name then
		return name, "ModuleScript"
	end
	return nil
end

local stats = { Written = 0, Removed = 0 }

local function ensure(parent, name, className)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName ~= className then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		existing = Instance.new(className)
		existing.Name = name
		existing.Parent = parent
	end
	return existing
end

local function syncFolder(path, instance)
	local seen = {}
	for _, entry in list(path) do
		if entry:sub(-1) == "/" then
			local name = entry:sub(1, -2)
			seen[name] = true
			syncFolder(path .. entry, ensure(instance, name, "Folder"))
		else
			local name, className = classify(entry)
			if name then
				seen[name] = true
				local scriptInstance = ensure(instance, name, className)
				local source = fetch(path .. entry)
				if scriptInstance.Source ~= source then
					if className == "ModuleScript" then
						local replacement = Instance.new("ModuleScript")
						replacement.Name = name
						for _, child in scriptInstance:GetChildren() do
							child.Parent = replacement
						end
						scriptInstance:Destroy()
						scriptInstance = replacement
						scriptInstance.Parent = instance
					end
					scriptInstance.Source = source
					stats.Written += 1
				end
			end
		end
	end
	for _, child in instance:GetChildren() do
		if not seen[child.Name] and (child:IsA("LuaSourceContainer") or child:IsA("Folder")) then
			child:Destroy()
			stats.Removed += 1
		end
	end
end

for _, root in roots do
	local ok, err = pcall(function()
		list(root.Path)
	end)
	if ok then
		syncFolder(root.Path, ensure(root.Parent, root.Name, "Folder"))
	else
		warn("skip " .. root.Path .. " " .. tostring(err))
	end
end

print(("Sync done: %d written, %d removed"):format(stats.Written, stats.Removed))
