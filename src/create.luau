const apply = require("./apply")
const defaults = require("./defaults")
const flags = require("./flags")
local types = require("./types")

local function create_constructor_for_class(class: string): ({ [unknown]: unknown }) -> Instance
	local function constructor(properties: { [unknown]: unknown }): Instance
		local ok, instance: Instance = pcall(Instance.new, class :: any)
		if not ok then
			error(`invalid class name {class}`, 0)
		end

		if flags.defaults then
			local default: { [string]: unknown }? = defaults[class]
			if default then
				for i, v in default do
					(instance :: any)[i] = v
				end
			end
		end

		return apply(instance, properties)
	end

	return constructor
end
local constructor_cache = {} :: { [string]: ({ [unknown]: unknown }) -> Instance }

local function create<T>(
	class_or_instance: T | keyof<types.Instances>
): (props: types.PropertiesFor<T>) -> types.GetInstance<T>
	if type(class_or_instance) ~= "string" and typeof(class_or_instance) ~= "Instance" then
		error("bad argument #1, expected string or instance, got " .. typeof(class_or_instance), 0)
	end

	local constructor: ({ [unknown]: unknown }) -> Instance
	if type(class_or_instance) == "string" then
		constructor = constructor_cache[class_or_instance]
		if not constructor then
			constructor = create_constructor_for_class(class_or_instance)
			constructor_cache[class_or_instance] = constructor
		end
	else
		constructor = function(props)
			local clone = assert(class_or_instance:Clone(), "attempt to clone a non-archivable instance")
			return apply(clone, props)
		end
	end

	return constructor
end

return create
