local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Shared").Util.Signal)

local Settings = {
	Values = {
		Music = true,
		Sfx = true,
		Effects = "High",
		Shake = true,
	},
	Order = { "Music", "Sfx", "Effects", "Shake" },
	Labels = {
		Music = "Music",
		Sfx = "Sound Effects",
		Effects = "Effects Quality",
		Shake = "Camera Shake",
	},
	Cycles = {
		Effects = { "High", "Low", "Off" },
	},
	Changed = Signal.new(),
}

function Settings:Get(key)
	return self.Values[key]
end

function Settings:Toggle(key)
	local cycle = self.Cycles[key]
	if cycle then
		local index = table.find(cycle, self.Values[key]) or 0
		self.Values[key] = cycle[index % #cycle + 1]
	else
		self.Values[key] = not self.Values[key]
	end
	self.Changed:Fire(key, self.Values[key])
	return self.Values[key]
end

function Settings:EffectScale()
	local quality = self.Values.Effects
	return quality == "High" and 1 or quality == "Low" and 0.5 or 0
end

return Settings
