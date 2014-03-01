
exports.name = "bob"
test "require a module who required me",()->
    ok require("ana.js").name is "ana"

