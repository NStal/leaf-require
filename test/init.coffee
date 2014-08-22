context = new LeafRequire({root:"./"})
context.debug = true
context.enableCache = true
context.use "index.js","ana.js","bob.js"
context.use "root.js","sub/qubi.js","sub/madoka.js"
context.version = Math.random().toString()
context.load ()->
    console.log "loaded"
    context.require("index.js")
    context.require("root.js")
    test "shoudl be able to get latest version",()->
        ok context.getLastVersion() is context.version
