local queue = {}

function queue:push(item)
	rawset(self, #self+1, item)
end

function queue:pop()
	local i = self[1]
	table.remove(self, 1)
	return i
end

function queue:peek()
	return self[1]
end

return function()
	return setmetatable({}, {__type="queue", __index=queue, __tostring=function(t)
		return "["..table.concat(t, ", ").."]"
	end})
end