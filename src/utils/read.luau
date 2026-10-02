export type function CastIntoValue(value: type)
	local function get_return_for_fn(t: type)
		local values = t:returns()
		local head = values.head
		local tail = values.tail

		if head then
			local first = head[1]
			return first
		elseif tail then
			return tail
		else
			return types.singleton(nil)
		end
	end

	if value.tag == "union" then
		local components = value:components()
		local possible_outcomes = {}

		for _, v in components do
			if v.tag == "function" then
				table.insert(possible_outcomes, get_return_for_fn(v))
			else
				table.insert(possible_outcomes, v)
			end
		end

		return types.unionof(unpack(possible_outcomes))
	elseif value.tag == "function" then
		return get_return_for_fn(value)
	elseif value.tag == "intersection" then
		local options = {}
		for i, v in value:components() do
			options[i] = CastIntoValue(v)
		end

		return types.intersectionof(unpack(options))
	else
		return value
	end
end

export type function Read(t: type): type
	if t:is("union") then
		for _, component in t:components() do
			if not component:is("function") then
				return component
			end
		end
	end

	return if t:is("function") then (t:returns().head :: { type })[1] else t
end

local function read<T>(src: T | () -> T): Read<T>
	if typeof(src) == "function" then
		return (src :: () -> T)()
	else
		return src :: T
	end
end

return read
