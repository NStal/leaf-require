context = new LeafRequire({root:"./test/"})
context.use "a.js","b.js","c.js","main.js","sub/subA.js","sub/subB.js","rootA.js"
context.load ()->
    console.log "inited"
    context.require("main.js")
    context.require("sub/subA.js")