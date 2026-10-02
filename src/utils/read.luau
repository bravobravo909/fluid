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
	if t:is("function") then
		return (t:returns().head :: { type })[1]
	end

	if t:is("union") then
		local parts = {}
		local function add(part: type)
			if part:is("union") then
				for _, member in part:components() do
					add(member)
				end
				return
			end
			for _, existing in parts do
				if existing == part then
					return
				end
			end
			table.insert(parts, part)
		end

		for _, component in t:components() do
			if component:is("function") then
				local head = component:returns().head
				if head and head[1] then
					add(head[1])
				end
			else
				add(component)
			end
		end

		return if #parts == 1 then parts[1] else types.unionof(unpack(parts))
	end

	return t
end

local function read<T>(src: T | () -> T): Read<T>
	if typeof(src) == "function" then
		return (src :: () -> T)()
	else
		return src :: T
	end
end

return read
