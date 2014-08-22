exports.name = "root"
test "require a module from a sub folder",()->
    ok require("sub/qubi.js").name is "qubi"
    