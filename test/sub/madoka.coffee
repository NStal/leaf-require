exports.name = "madoka"
test "require a module from parent folder",()->
    ok require("../root.js").name is "root"