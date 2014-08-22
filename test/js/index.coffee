window.mainLoaded = true
it "require a module from the same folder",(done)->
    console.assert require("ana.js").name is "ana"
    done()
    
    