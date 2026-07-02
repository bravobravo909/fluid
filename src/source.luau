--!strict
const graph = require("./graph")
const store = require("./store")
local function notify(v)
    if typeof(v) == "table" and table.isfrozen(v) and store.strict then
        warn("Use snapshot() for frozen tables")
    end
end
export type Source<T> = (() -> T) & ((value: T) -> T)

local function source<T>(initial: T): Source<T>
    notify(initial)
    local node = graph.createNode(nil , initial)
    return function(...): T
        if select("#", ...) == 0 then
            local scope = graph.getScope()
            if scope then
                graph.registerDependency(node, scope)
            end
            return node.value
        end

        local v = ... :: T
        notify(v)
        if typeof(node.value) ~= "table" or table.isfrozen(node.value) then
            if node.value == v then
                return v
            end
        end
        node.value = v
        graph.notifySubs(node)
        return v
    end
end


return source :: (<T>(initial_value: T) -> Source<T>) & (<T>() -> Source<T>)