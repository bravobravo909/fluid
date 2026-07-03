const cleanup = require("../cleanup")
const action = require("./action")


local function changed<T>(property: string, callback: (T) -> ())
    return action.create(function(instance)
        local con = instance:GetPropertyChangedSignal(property):Connect(function()
            callback((instance :: any)[property])
        end)

        cleanup(function()
            con:Disconnect()
        end)

        callback((instance :: any)[property])
    end)
end

return changed
