const graph = require("./graph")
const store = require("./store")


local function batch(setter: () -> ())
    local alreadyBatching = store.batching
    local from

    if not alreadyBatching then
        store.batching = true
        from = graph.getUpdateQueueLength()
    end

    local ok, err: string? = xpcall(setter, debug.traceback)

    if not alreadyBatching then
        store.batching = false
        graph.flushQueue(from)
    end

    if not ok then error(`error occured while batching updates: {err}`, 0) end
end

return batch
