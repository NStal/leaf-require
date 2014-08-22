counter = 0
exports.name = "ana"
it "require a module at same folder with a required module",(done)->
    counter++
    if counter is 2
        throw new Error "recursive require"
    console.assert require("bob.js").name is "bob"
    done()

