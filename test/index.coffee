window.mainLoaded = true
test "require a module from the same folder",()->
    ok require("ana.js").name is "ana"
    
    