common = require "./common"
worker = GlobalContext.createDedicateWorker([
    "worker"
    "common"
],{
    contextName:"WorkerContext"
    entryFunction:()->
        WorkerContext.require("worker")
})
worker.addEventListener "message",(e)->
    if e.data is "ready"
        console.log "worker ready"
        worker.postMessage common.getTestData()
        return
    if e.data is common.getTestData()
        alert "Work works!"
        return
