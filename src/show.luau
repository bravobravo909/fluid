const effect = require("./effect")
const _scope = require("./scope")
local function show<T>(source: () -> boolean, scope: () -> T): () -> T?
	local cleanup 
    local output = source()
    effect(function()
        if cleanup then
            cleanup()
            output(nil)
        end
        if source() then
            local clean, out = _scope(scope)
            cleanup = clean 
            output(out)
        end
    end)

    return output
end


return show