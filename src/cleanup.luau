const graph = require("./graph")
--// thx vide yet again
local function helper(obj: any)
    return
        if typeof(obj) == "RBXScriptConnection" then function() obj:Disconnect() end
        elseif type(obj) == "thread" then function() task.cancel(obj) end
        elseif typeof(obj) == "Instance" then function() obj:Destroy() end
        elseif obj.destroy then function() obj:destroy() end
        elseif obj.disconnect then function() obj:disconnect() end
        elseif obj.Destroy then function() obj:Destroy() end
        elseif obj.Disconnect then function() obj:Disconnect() end
        else error "cannot cleanup given object"
end

local function cleanup(callback: () -> ())
    local scope = graph.assertScope()
    if type(callback) == "function" then
        graph.pushCleanup(scope, callback)
    else
        graph.pushCleanup(scope, helper(callback))
    end
end


type Destroyable = { destroy: (any) -> () } | { Destroy: (any) -> () }
type Disconnectable = { disconnect: (any) -> () } | { Disconnect: (any) -> () }

return cleanup ::
    ( (callback: () -> ()) -> () ) &
    ( (thread: thread) -> () ) &
    ( (instance: Destroyable) -> () ) &
    ( (connection: Disconnectable) -> () ) &
    ( (instance: Instance) -> () ) &
    ( (connection: RBXScriptConnection) -> () )
