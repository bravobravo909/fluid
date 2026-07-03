const graph = require("./graph")

local function effect<T>(fn: (value: T) -> T, initalValue: T)
	local scope = graph.assertStableScope()
	local node = graph.createNode(scope, initalValue, fn)
	graph.evaluateNode(node)	
end

return effect :: ((fn: () -> ()) -> ()) & (<T>(fn: (T) -> T, initial_value: T) -> ())