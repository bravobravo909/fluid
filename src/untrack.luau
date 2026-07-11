local graph = require("./graph")
type Node<T> = graph.Node<T>
local get_scope = graph.get_scope

local function untrack<T..., R...>(source: (T...) -> R..., ...: T...): R...
	local scope = get_scope()

	if scope then
		-- sources are only tracked if the node in scope has an effect
		local effect = scope.effect
		scope.effect = false

		local data = { xpcall(source, debug.traceback, ...) }

		scope.effect = effect :: () -> ()

		if not data[1] then
			error(data[2], 0)
		end
		table.remove(data, 1)
		return table.unpack(data)
	else
		return source(...)
	end
end

return untrack :: (<T>(fn: () -> T) -> T) & ((fn: () -> ()) -> ())
