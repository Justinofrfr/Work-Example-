local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ Handlers = {} }, Signal)
end

function Signal:Connect(handler)
	local handlers = self.Handlers
	handlers[handler] = true
	return {
		Disconnect = function()
			handlers[handler] = nil
		end,
	}
end

function Signal:Fire(...)
	for handler in self.Handlers do
		task.spawn(handler, ...)
	end
end

return Signal
