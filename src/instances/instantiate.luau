const graph = require("../graph")
const types = require("./types")
local function instantiate<T>(className: (T | keyof<types.Instances>)): types.GetInstance<T>
    local scope = graph.assertScope()
    local inst: Instance
    if typeof(className) == "string" then
        inst = Instance.new(className)
    else
        inst = className:Clone()
    end
    graph.pushCleanup(scope, function()
        inst:Destroy()
    end)
    return inst 
end 
return instantiate