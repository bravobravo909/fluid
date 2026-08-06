local flags = require("./flags")
local untrack = require("./untrack")
local function deepFreeze(t: { [any]: any })
	table.freeze(t)
	for key, value in t do
		if typeof(value) == "table" then
			deepFreeze(value)
		end
	end
end
local function edit<T>(src: () -> T, received: (T) -> T)
	local value = untrack(src)
	if typeof(value) ~= "table" then
		return
	end

	local newValue = received(value)
	if typeof(newValue) ~= "table" then
		return
	end
	if flags.strict then
		deepFreeze(newValue)
	end
	src(newValue)
end

return edit
