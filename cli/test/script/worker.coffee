common = require "./common"
self.addEventListener "message",(e)=>
    if e.data is common.getTestData()
        self.postMessage common.getTestData()
    else
        console.error "invalid message"
self.postMessage "ready"
