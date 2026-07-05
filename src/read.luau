const types = require("./instances/types")

local function read<T>(src: T | () -> T): types.Read<T>
    if typeof(src) == "function" then
        return (src :: () -> T)()
    else
        return src :: T
    end
end



return read