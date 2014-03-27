context = new LeafRequire({root:"./"})
context.debug = true
context.use "index.js","ana.js","bob.js"
context.use "root.js","sub/qubi.js","sub/madoka.js"
context.load ()->
    console.log "loaded"
    context.require("index.js")
    context.require("root.js")
