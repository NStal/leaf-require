
exports.name = "bob"
it "require a module who required me",(done)->
    console.assert require("ana.js").name is "ana"
    done()

