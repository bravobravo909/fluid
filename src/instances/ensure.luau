const types = require("./types")
local function ensure<T>(class: T & keyof<types.Instances>, parent: Instance): index<types.Instances, T>
    local found = parent:FindFirstChildOfClass(class)
    if not found then
        found = Instance.new(class, parent)
    end
    return found
end

return ensure
