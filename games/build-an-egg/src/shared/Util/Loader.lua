local Loader = {}

function Loader.Load(folder: Instance, context: { [string]: any }?)
	local modules = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			modules[child.Name] = require(child)
		end
	end
	for _, module in modules do
		if type(module) == "table" and type(module.Init) == "function" then
			module:Init(modules, context)
		end
	end
	for name, module in modules do
		if type(module) == "table" and type(module.Start) == "function" then
			task.spawn(function()
				local ok, err = pcall(module.Start, module)
				if not ok then
					warn(("[Loader] %s failed to start: %s"):format(name, tostring(err)))
				end
			end)
		end
	end
	return modules
end

return Loader
