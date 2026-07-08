--!strict
const store = require("./store")
--// bravobravo909, concept stolen from vide and a few helpers
export type Node<T> = {
	subs: { Node<T> },
	deps: { Node<T> },

	owner: Node<T> | false,
	owned: { Node<T> } | false,
	value: T,
	effect: ((T) -> T) | false,
	cleanups: { () -> () } | false,

	static: boolean
}

local scopes: { [thread]: {[number]: Node<unknown>, n: number} } = {}
local updateQueue = { n = 0 } :: { n: number, [number]: Node<any> }

--// thx vide
local function efn(err: string)
	local trace = debug.traceback(err, 2)

	if string.find(err, "^effect error stacktrace") then -- if effect error is nested
		trace = string.gsub("    " .. trace, "\n", function() -- indent entire error
			return "\n    "
		end)
	end

	trace ..= "\nsource update stacktrace:"
	return trace
end
local function ycall<T, U>(fn: ((T) -> U) | (() -> U), arg: T): (boolean, string | U)
	local thread = coroutine.create(xpcall)
	--local function efn(err: string) return debug.traceback(err, 3) end
	local resume_ok, run_ok, result = coroutine.resume(thread, fn, efn, arg)

	assert(resume_ok)

	if coroutine.status(thread) ~= "dead" then
		return false, debug.traceback(thread, "attempt to yield in reactive scope")
	end

	return run_ok, result
end

local function pushScope<T>(scope: Node<T>)
	if not scopes[coroutine.running()] then
		scopes[coroutine.running()] = { n = 0}
	end
	local thisScopes = scopes[coroutine.running()]
	table.insert(thisScopes, scope)
	thisScopes.n += 1
end

local function popScope()
	local thisScopes = scopes[coroutine.running()]
	if not thisScopes then return end
	table.remove(thisScopes)
	thisScopes.n -= 1

	if not scopes[coroutine.running()] then
		scopes[coroutine.running()] = nil
	end
end

local function getScope(): Node<unknown>?
	local scopes = scopes[coroutine.running()]
	if not scopes then
		return nil
	end
	return scopes[scopes.n]
end
local function assertScope()
	local scope = getScope()
	assert(scope, "Can only be performed in a scope")
	return scope
end


local function pushCleanup<T>(node: Node<T>, cleanup: () -> ())
	if node.cleanups then
		table.insert(node.cleanups, cleanup)
	else
		node.cleanups = { cleanup }
	end
end

local function flushCleanups<T>(node: Node<T>)
	if node.cleanups then
		for _, fn in node.cleanups do
			local ok, err = pcall(fn)
			if not ok then
				error(`cleanup error: {err}`, 0)
			end
		end

		table.clear(node.cleanups)
	end
end

local function findSwapPop<T>(t: { T }, v: T)
	local i = table.find(t, v) :: number
	local n = #t
	t[i] = t[n]
	t[n] = nil
end

local function unsubscribe<T>(node: Node<T>)
	local deps = node.deps
	if deps then
		for _, dep in deps do
			if dep.subs then
				findSwapPop(dep.subs, node)
			end
		end
		table.clear(deps)
	end
end

local function destroy<T>(node: Node<T>)
	if store.strict then
		for _, allScopes in scopes do
			if table.find(allScopes, node) then
				error("attempt to destroy an active scope", 0)
			end
		end
	end


	flushCleanups(node)
	unsubscribe(node)

	if node.owner then
		local owned = node.owner.owned
		if owned then
			table.remove(owned, table.find(owned, node))
			node.owner = false
		end
	end

	if node.owned then
		local owned = node.owned
		while owned[1] do
			destroy(owned[1])
		end
	end
end
local function destroyOwned<T>(node: Node<T>)
	if node.owned then
		local owned = node.owned
		while owned[1] do
			destroy(owned[1])
		end
	end
end



local function registerDependency(dependency: Node<unknown>, subscriber: Node<unknown>)
	if not subscriber.effect or subscriber.static then
		return
	end

	if table.find(subscriber.deps, dependency) then
		return
	end

	table.insert(subscriber.deps, dependency)

	if dependency.subs then
		table.insert(dependency.subs, subscriber)
	else
		dependency.subs = { subscriber }
	end
end
local function createNode<T>(currentScope: Node<unknown>?, value: T, effect: ((T) -> (T))?, static: boolean?)
	local node: Node<T> = {
		value = value,
		owner = if currentScope ~= nil then currentScope else false,
		effect = if effect ~= nil then effect else false,
		cleanups = false,
		owned = false,
		static = if static ~= nil then static else false,

		subs = {},
		deps = {},
	} :: Node<T>
	if currentScope then
		if currentScope.owned then
			table.insert(currentScope.owned, node)
		else
			currentScope.owned = { node }
		end
	end

	return node
end

local function assertStableScope(): Node<unknown>
    local scope = getScope()

    if not scope then
        local caller_name = debug.info(2, "n")
        return error(`cannot use {caller_name}() outside a stable or reactive scope`, 0)
    elseif scope.effect then
        error("cannot create a new reactive scope inside another reactive scope", 0)
    end

    return scope
end

local function evaluateNode(node: Node<unknown>)
	if node.effect then
		local oldValue = node.value

		flushCleanups(node)
		destroyOwned(node)


		pushScope(node)
		local ok, result
		if store.strict then
			ok, result = ycall(node.effect, oldValue)
			popScope()
			if not ok then
				error(`effect error stacktrace\n{result}`, 0)
			end
		else
			result = node.effect(oldValue)
			popScope()
			ok = true
		end

		if not ok then
			error(result, 0)
		end

		if node.static then
			node.effect = false
		end


		node.value = result
		return oldValue ~= result
	end
	return false
end



local function queueSubs<T>(node: Node<T>)
    local i = updateQueue.n
    while node.subs[1] do
        i += 1
        updateQueue[i] = node.subs[1]
        unsubscribe(node.subs[1])
    end
    updateQueue.n = i
end

local function getUpdateQueueLength()
    return updateQueue.n
end

local function flushQueue(from: number)
    local i = from + 1
    while i <= updateQueue.n do
        local node = updateQueue[i]
        if node.owner and evaluateNode(node) then
            queueSubs(node)
        end
        updateQueue[i] = false :: any
        i += 1
    end
    updateQueue.n = from
end

local function notifySubs(root: Node<unknown>)
    local n0 = updateQueue.n
	queueSubs(root)
	if store.batching then return end

    local i = n0 + 1
    while i <= updateQueue.n do
        local node = updateQueue[i]
        if node.owner and evaluateNode(node) then
            queueSubs(node)
        end
        updateQueue[i] = false :: any
        i += 1
    end

    updateQueue.n = n0
end
return {
	notifySubs = notifySubs,
	evaluateNode = evaluateNode,
	createNode = createNode,
	registerDependency = registerDependency,
	pushCleanup = pushCleanup,
	getScope = getScope,
	pushScope = pushScope,
	popScope = popScope,
	assertScope = assertScope,
	destroy = destroy,
	getUpdateQueueLength = getUpdateQueueLength,
	flushQueue = flushQueue,
	destroyOwned = destroyOwned,
	flushCleanups = flushCleanups,
	unsubscribe = unsubscribe,
	assertStableScope = assertStableScope
}
