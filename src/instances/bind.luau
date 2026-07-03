local graph = require("../graph")
const action = require("./action")


type PropertyPair<T> = {
	tag: "property",
	name: string,
	value: T,
}

type ReactivePropertyPair<T> = {
	tag: "reactiveProperty",
	name: string,
	value: () -> T,
}

type EventPair<T...> = {
	tag: "event",
	name: string,
	event: (T...) -> (),
}

type ActionPair = {
	tag: "action",
	action: never, --// TODO: Implement actions
}

type ChildPair = {
	tag: "child",
	value: Instance,
}

type ReactiveChildPair = {
	tag: "reactiveChild",
	value: () -> Instance | { Instance },
}

type Pair =
	| ReactivePropertyPair<unknown>
	| PropertyPair<unknown>
	| EventPair<unknown>
	| ReactiveChildPair
	| ActionPair
	| ChildPair

local function setProperty(inst: Instance, property: string, ...)
	if select("#", ...) == 0 then 
		return
	end
	local v = ...
	(inst :: any)[property] = v
end

local function getProperty(inst: Instance, property: string): any
	return (inst :: any)[property]
end

local function bindProperty<T>(inst: Instance, property: string, value: () -> T)
	local propertyNode = graph.createNode(graph.assertStableScope(), nil, function()
		setProperty(inst, property, value())
		return nil
	end)

	graph.evaluateNode(propertyNode)
end

local function bindEvent(inst: Instance, eventName: string, func: <T...>(T...) -> ())
	local event = (inst :: any)[eventName] :: RBXScriptSignal
	local connection = event:Connect(func :: any)

	graph.pushCleanup(graph.assertStableScope(), function()
		connection:Disconnect()
	end)
end

type Result = Instance | { Result } | () -> Result

local function reactiveChildEffect(
	inst: Instance,
	func: () -> Result,
	sets: {
		new: { [Instance]: true },
		current: { [Instance]: true },
	}
)
	local newChildSet = sets.new
	local currentChildSet = sets.current
	local sourceResult = func()

	if not sourceResult then
		for oldInst in currentChildSet do
			oldInst.Parent = nil
		end

		return sets
	end

	local function processChild(child: Result)
		if typeof(child) == "Instance" then
			newChildSet[child] = true

			if currentChildSet[child] then
				currentChildSet[child] = nil
				return
			end

			child.Parent = inst
			return
		end

		if typeof(child) == "function" then
			local children: { new: { [Instance]: true }, current: { [Instance]: true } } =
				{ new = {}, current = {} }

			local scope = graph.assertStableScope()
			graph.createNode(scope, children, function(value)
				return reactiveChildEffect(inst, child, value)
			end)

			graph.pushCleanup(scope, function()
				for child in children.current do
					child.Parent = nil
				end
			end)

			return
		end

		for _, child in child do
			processChild(child)
		end

		return
	end

	processChild(sourceResult)

	for child in currentChildSet do
		child.Parent = nil
	end

	table.clear(currentChildSet)
	sets.current, sets.new = newChildSet, currentChildSet

	return sets
end

local function bindReactiveChild(inst: Instance, func: () -> Result)

	local node = graph.assertStableScope()

	local children: { new: { [Instance]: true }, current: { [Instance]: true } } =
		{ new = {}, current = {} }

	local propertyNode = graph.createNode(node :: any, children, function(value)
		return reactiveChildEffect(inst, func, value)
	end)

	graph.evaluateNode(propertyNode)
end

local function evaluate(
	inst: Instance,
	props: { [unknown & number]: unknown },
	existingArray: { Pair }?
): { Pair }
	local resultingArray: { Pair } = existingArray or {}

	for key, value in props do
		local valueIsAction = action.isAction(value :: any)

		if type(key) == "number" and type(value) == "table" and valueIsAction then
			table.insert(resultingArray, {
				tag = "action",
				action = value,
			})
		elseif type(key) == "number" and type(value) == "table" and not valueIsAction then
			evaluate(inst, value :: any, resultingArray)
		elseif type(key) == "number" and type(value) == "function" then
			table.insert(resultingArray, {
				tag = "reactiveChild",
				value = value,
			})
		elseif type(key) == "string" and typeof(getProperty(inst, key)) == "RBXScriptSignal" then
			table.insert(resultingArray, {
				tag = "event",
				name = key,
				event = value,
			})
		elseif
			type(key) == "string"
			and typeof(getProperty(inst, key)) ~= "RBXScriptSignal"
			and type(value) == "function"
		then
			table.insert(resultingArray, {
				tag = "reactiveProperty",
				name = key,
				value = value,
			})
		elseif
			type(key) == "string"
			and typeof(getProperty(inst, key)) ~= "RBXScriptSignal"
			and type(value) ~= "function"
		then
			table.insert(resultingArray, {
				tag = "property",
				name = key,
				value = value,
			})
		elseif typeof(value) == "Instance" then
			table.insert(resultingArray, {
				tag = "child",
				value = value,
			})
		end
	end

	return resultingArray
end

local function bind(inst: Instance, props: { [unknown & number]: unknown })
	local pairings = evaluate(inst, props)
	local parent: (ReactivePropertyPair<Instance> | PropertyPair<Instance>)? = nil

	for _, pairing in pairings do
		if
			(pairing.tag == "property" or pairing.tag == "reactiveProperty")
			and pairing.name == "Parent"
		then
			parent = pairing :: any
			continue
		end

		if pairing.tag == "property" then
			task.defer(setProperty, inst, pairing.name, pairing.value)
		elseif pairing.tag == "reactiveProperty" then
			bindProperty(inst, pairing.name, pairing.value)
		elseif pairing.tag == "event" then
			bindEvent(inst, pairing.name, pairing.event)
		elseif pairing.tag == "child" then
			task.defer(function()
				pairing.value.Parent = inst
			end)
		elseif pairing.tag == "reactiveChild" then
			bindReactiveChild(inst, pairing.value)
		elseif pairing.tag == "action" then
			pairing.action.callback(inst)
		else
			error("unreachable")
		end
	end

	if parent and parent.tag == "reactiveProperty" then
		bindProperty(inst, "Parent", parent.value)
	elseif parent and parent.tag == "property" then
		setProperty(inst, "Parent", parent.value)
	end

	return inst
end

return bind