

local bind = require("./bind")
local types = require("./types")



local function try_create_instance(className: string | Instance): Instance
	local result: Instance
	if typeof(className) == "string" then
		result = Instance.new(className)
	else
		result = className:Clone()
	end

	return result
end

local function create<ClassName>(
	className: ClassName | keyof<types.Instances>
): (
	props: types.PropertiesFor<ClassName>
) -> index<types.Instances, ClassName>
	local inst = try_create_instance(className)
	return function(properties)
		return bind(inst, properties) :: any
	end
end


return create