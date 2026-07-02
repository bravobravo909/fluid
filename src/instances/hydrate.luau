local bind = require("./bind")
local types = require("./types")




local function hydrate<T>(
	inst: T
): (
	props: types.PropertiesFor<T>
) -> types.GetInstance<T>
	return function(properties)
		return bind(inst, properties)
	end
end


return hydrate