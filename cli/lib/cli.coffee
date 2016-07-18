pathModule = require("path")
crypto = require("crypto")
fs = require("fs")
wrench = require("wrench")

program = require("commander").usage("[option] <js-folder-root>")
    .option("-o,--output-file <path>","specify the output require configs")
    .option("-r,--root <root patah>","specifty the generated files root name")
    .option("-f,--force-overwrite","force overwrite the file rather than try merging it")
    .option("--excludes <folder or file>","exclude certain folder or file by matching the starts, split by ','")
    .option("--includes <folder or file>","includes certain folder or file by matching the starts, split by ',', this option will overwrite the excludes.")
    .option("--enable-debug","enable debug mode in config")
    .option("--enable-cache","enable cache in config")
    .option("--set-version <version>","set version for the config")
    .option("--main <main module>","set entry module for the --compile mode")
    .option("--stand-alone","compile all required package into it the config file")
    .option("-c,--compile","compile into a single runnable bundle.js")
    .option("-t,--context <context name>","specify the global context name")
    .parse(process.argv)
outputFile = program.outputFile
outputFormat = "json"
indentCount = 4
if program.compile
    program.standAlone = true
standAlone = program.standAlone
contextName = program.context or "GlobalContext"
jsIncludePath = program.args[0] or "./"
excludes = (program.excludes or "").split(",").map((item)->item.trim()).filter (item)->item
includes = (program.includes or "").split(",").map((item)->item.trim()).filter (item)->item
version = program.setVersion or null
mainModule = program.main or null
enableDebug = program.enableDebug and true or false
if outputFormat is "json" and outputFile and not program.forceOverwrite and fs.existsSync outputFile
    try
        config = JSON.parse fs.readFileSync outputFile,"utf8"
    catch e
        console.error "outputFile #{outputFile} exists, but is not a valid json."
        console.error "don't overwrite it."
        process.exit(1)
else
    config = {}
config.name = config.name or "leaf-require"
config.js = {}
config.debug = config.debug or enableDebug
config.cache = config.cache or program.enableCache or false
if mainModule
    config.js.main = mainModule
if version
    config.version = version
files = wrench.readdirSyncRecursive jsIncludePath
fileWhiteList = [/\.js$/i]
files = files.filter (file)->
    filePath = pathModule.resolve pathModule.join jsIncludePath,file
    for include in includes
        includePath = pathModule.resolve include
        if filePath is includePath or filePath.indexOf(includePath+"/") is 0
            for white in fileWhiteList
                if white.test file
                    return true
            return false
    for exclude in excludes
        excludePath = pathModule.resolve exclude
        if filePath is excludePath or filePath.indexOf(excludePath+"/") is 0
            return false
    for white in fileWhiteList
        if white.test file
            return true
    return false
files = files.map (file)->
    content = fs.readFileSync (pathModule.join jsIncludePath,file),"utf8"
    hash = crypto.createHash("md5").update(content).digest("hex").substring(0,6)
    result = {
        path:file
        hash:hash
    }
    if program.standAlone
        result.scriptContent = content
    return result
config.js.root = program.root or ""
config.js.files = files
config.contextName = contextName or "GlobalContext"
#if program.compile
#
#    moduleTemplate = fs.readFileSync (pathModule.resolve __dirname,"../module.template.js"),"utf8"
#    standAloneTemplate = fs.readFileSync (pathModule.resolve __dirname,"../standalone.template.js"),"utf8"
#    moduleContentArray = []
#    for file in files
#        moduleContentArray.push(moduleTemplate
#            .replace(/{{contextName}}/g,contextName)
#            .replace(/{{currentModulePath}}/g,file.path)
#            .replace("{{currentModuleContent}}",file.scriptContent)
#        )
#    javascriptContent = standAloneTemplate.replace(/{{contextName}}/g,contextName).replace("{{modules}}",moduleContentArray.join("\n")).replace(/{{mainModule}}/g,"\"#{mainModule}\"" or "null")
#    content = javascriptContent

if program.compile
    LeafRequire = (require "./leaf-require.coffee").LeafRequire
    content = LeafRequire.BundleBuilder.fromStandAloneConfig(config).generateBundle()
else
    content = JSON.stringify config,null,indentCount
if outputFile
    fs.writeFileSync outputFile,content
else
    console.log content
process.exit(0)
