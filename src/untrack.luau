const graph = require("./graph")
local function untrack<T>(callback: () -> T): T
    local scope = graph.getScope()

    if scope and not scope.static then
        scope.static = true
        local result = callback()
        scope.static = false
        return result
    end

    return callback()
end

return untrack