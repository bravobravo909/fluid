const graph = require("./graph")
local refs = {}
local function scope<T...>(fn: (destroy: () -> ()) -> T...): (() -> (), T...) 
    local node = graph.createNode(graph.assertScope(), nil, nil, true)
    refs[node] = true
    local function destroy()
        if not refs[node] then return end
        refs[node] = nil
        graph.destroy(node)
    end
    graph.pushScope(node)
    local data = { fn(destroy) }
    graph.popScope()
    return destroy, unpack(data)
end

return scope