const graph = require("./graph")
local function untrack<T..., R...>(callback: (T...) -> R..., ...: T...): R...
    local scope = graph.getScope()

    if scope and not scope.static then
        scope.static = true
        local result = { callback(...) }
        scope.static = false
        return table.unpack(result)
    end

    return callback(...) 
end

return untrack