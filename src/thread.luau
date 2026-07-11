const graph = require("./graph")
const source = require("./source")
--// this took way too long

function thread<T>(callback: (set: (T) -> ()) -> ()): () -> T
	local scope = graph.assert_stable_scope()
	local value_node = source(nil :: T)
	local active_thread: thread? = nil

	local function set(newValue: T)
		value_node(newValue)
	end

	local effect_node
	effect_node = graph.create_node(scope, function()
		active_thread = task.spawn(function()
			graph.push_scope(effect_node)
			local ok, err = pcall(callback, set)
			graph.pop_scope()
			if not ok then
				warn(`thread error: {err}`)
			end
		end)
		graph.push_cleanup(effect_node, function()
			if active_thread then
				task.cancel(active_thread)
			end
		end)
	end, nil)

	graph.evaluate_node(effect_node)

	return value_node
end

return thread
