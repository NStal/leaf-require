exports.name = "qubi"
test "require a module without .js ../sub/module",()->
    ok require("../sub/madoka").name is "madoka"
    