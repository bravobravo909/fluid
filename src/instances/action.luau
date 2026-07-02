local actionMetaSymbol = table.freeze({})

export type Identity = setmetatable<{
	callback: (inst: Instance) -> (),
	priority: number,
}, typeof(actionMetaSymbol)>

local action = {
	metatable = actionMetaSymbol,
}

function action.isAction(action: unknown): boolean
	return type(action) == "table" and (getmetatable(action :: any) == actionMetaSymbol)
end

function action.create(callback: (inst: Instance) -> (), priority: number?): Identity
	return setmetatable({
		callback = callback,
		priority = priority or 1,
	}, actionMetaSymbol)
end

return action