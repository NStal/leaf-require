counter = 0
exports.name = "ana"
test "require a module at same folder with a required module",()->
    counter++
    if counter is 2
        throw new Error "recursive require"
    ok require("bob.js").name is "bob"

