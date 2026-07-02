const graph = require("./graph")

local function derive<T>(source: () -> T): () -> T
    local node = graph.createNode(graph.assertScope(), nil, source)
    graph.evaluateNode(node)

    return function()
        local scope = graph.getScope()
        if scope then
            graph.registerDependency(node, scope)
        end

        return node.value
    end
end

return derive
 