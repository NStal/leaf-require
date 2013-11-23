console.log "Main loaded"

console.log "require test1"
test1 = require("test1.js")
console.log "require test2"
test2 = require("test2.js")
console.log "require test3"
test3 = require("test3.js")

test1.callMe()
test2.callMe()
test3.callMe()

console.log "require test1 again"
nextTest1 = require("test1.js")
console.log "nothing should happen.."
nextTest1.callMe()
