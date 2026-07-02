const graph = require("./graph")
const source = require("./source")
--// this took way too long

function thread<T>(callback: (set: (T) -> ()) -> ()): () -> T
	local scope = graph.assertScope()
	local valueNode = source(nil :: T)
	local activeThread: thread? = nil
	
	local function set(newValue: T)
		valueNode(newValue)
	end
	
	local effectNode
    effectNode = graph.createNode(scope, nil, function()
		activeThread = task.spawn(function()
			graph.pushScope(effectNode)			
			local ok, err = pcall(callback, set)			
			graph.popScope()
			if not ok then
				warn(`async error: {err}`)
			end
		end)
		graph.pushCleanup(effectNode, function()
			if activeThread then
				task.cancel(activeThread)
			end
		end)
	end)
	
	graph.evaluateNode(effectNode)
	
	
	return valueNode
end

return thread
