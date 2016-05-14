# from http://www.grauw.nl/articles/resolve-uri.html
`
/**
 * Implementation of base URI resolving algorithm in rfc2396.
 * - Algorithm from section 5.2
 *   (ignoring difference between undefined and '')
 * - Regular expression from appendix B
 * - Tests from appendix C
 *
 * @param {string} uri the relative URI to resolve
 * @param {string} baseuri the base URI (must be absolute) to resolve against
 */

URI = function(){
    function resolveUri(sUri, sBaseUri) {
    if (sUri == '' || sUri.charAt(0) == '#') return sUri;
    var hUri = getUriComponents(sUri);
    if (hUri.scheme) return sUri;
    var hBaseUri = getUriComponents(sBaseUri);
    hUri.scheme = hBaseUri.scheme;
    if (!hUri.authority) {
        hUri.authority = hBaseUri.authority;
        if (hUri.path.charAt(0) != '/') {
        aUriSegments = hUri.path.split('/');
        aBaseUriSegments = hBaseUri.path.split('/');
        aBaseUriSegments.pop();
        var iBaseUriStart = aBaseUriSegments[0] == '' ? 1 : 0;
        for (var i in aUriSegments) {
            if (aUriSegments[i] == '..')
            if (aBaseUriSegments.length > iBaseUriStart) aBaseUriSegments.pop();
            else { aBaseUriSegments.push(aUriSegments[i]); iBaseUriStart++; }
            else if (aUriSegments[i] != '.') aBaseUriSegments.push(aUriSegments[i]);
        }
        if (aUriSegments[i] == '..' || aUriSegments[i] == '.') aBaseUriSegments.push('');
        hUri.path = aBaseUriSegments.join('/');
        }
    }
    var result = '';
    if (hUri.scheme   ) result += hUri.scheme + ':';
    if (hUri.authority) result += '//' + hUri.authority;
    if (hUri.path     ) result += hUri.path;
    if (hUri.query    ) result += '?' + hUri.query;
    if (hUri.fragment ) result += '#' + hUri.fragment;
    return result;
    }
    uriregexp = new RegExp('^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?');
    function getUriComponents(uri) {
    var c = uri.match(uriregexp);
    return { scheme: c[2], authority: c[4], path: c[5], query: c[7], fragment: c[9] };
    }
    var URI = {}
    URI.resolve = function(base,target){
        return resolveUri(target,base);
    }
    URI.normalize = function(url){
        return URI.resolve("",url);
    }
    return {URI:URI}
}()`

class Context
    @id = 0
    @instances = []
    # for inserted script to make reference to the context
    @getContext = (id)->
        return @instances[id]
    @_httpGet = (url,callback)->
        XHR = new XMLHttpRequest()
        XHR.open("GET",url,true)
        XHR.onreadystatechange = (err)=>
            if XHR.readyState is 4
                if XHR.status isnt 200
                    callback new Error "Network Error status code #{XHR.status}"
                    return
                callback null,XHR.responseText
            if XHR.readyState is 0
                callback new Error "Network Error"
        XHR.send()
    createDedicateWorker:(pathes,option = {})->
        bundle = new BundleBuilder({contextName:option.contextName or @globalName+"Worker"})
        for path in pathes
            bundle.addScript @getRequiredScript(path)
        if option.entryModule
            bundle.addEntryModule option.entryModule
        else if option.entryFunction
            bundle.addEntryFunction option.entryFunction
        return bundle.generateWorker()
    constructor:(option = {})->
        @id = Context.id++
        Context.instances[@id] = this

        @globalName = "LeafRequire"
        # one may overwrite localStoragePrefix to
        # avoid conflict of multiple use of leaf-require
        # on the same domain.
        @localStoragePrefix = option.localStoragePrefix or @globalName
        @dry = option.dry or false
        @ready = false
        @scripts = []
        @store = {files:{}}
        @init
            root:option.root
            version:option.version
            # you may use different project name to avoid conflict
            name:option.name
            debug:option.debug
    init:(option)->
        @root = option.root or @root or "./"
        if @root[@root.length - 1] isnt "/"
            @root += "/"
        @version = option.version or @version or "0.0.0"
        @name = option.name or @name or "leaf-require"
        @debug = option.debug or @name or false
        @enableSourceMap = option.enableSourceMap or @debug or false
    use:(files...)->
        for file in files
            @scripts.push new Script this,file

    _debug:(args...)->
        if @debug
            console.debug args...
    getScript:(path)->
        for script in @scripts
            if script.scriptPath is path
                return script
        if path.lastIndexOf(".js") isnt path.length - ".js".length
            for script in @scripts
                if script.scriptPath is path+".js"
                    return script
        return null
    # The require related method, may be invoked by compiled script
    getRequire:(path)->
        script = @getScript(path)
        return (_path)->
            return script.require(_path)
    setRequire:(path,module,exports,__require)->
        script = @getScript(path)
        script.setRequire(module,exports,__require)
    # END

    loadConfig:(config,callback = ()->)->

        # If config is a string, treat it as a config url.
        # unless treat it as a config json object
        if typeof config is "string"
            @setConfigRemote config,callback
        else
            try
                @setConfigSync(config)
                callback()
            catch e
                callback(e)
    # config is a file to restore context info
    # thus a context can be turn into a config file
    toConfig:()->
        return {
            name:@name
            version:@version
            debug:@debug
            js:{
                root:@root
                files:@scripts.map((script)->{hash:script.hash,path:script.path})
            }
        }
    setConfigRemote:(src,callback)->
        Context._httpGet src,(err,content)=>
            if err
                console.error err
                callback new Error "fail to get configs #{src} due to network error"
                return
            try
                config = JSON.parse content
                @setConfigSync config

                callback null
            catch e
                callback e
    setConfigSync:(config)->
        @hasConfiged = true
        js = config.js or {}
        files = js.files or []
#        console.debug "CONFIG",config
        @init
            name:config.name
            root:js.root
            version:config.version
            debug:config.debug
        for file in files
            @use file
        @store.config = config
    getRequiredScript:(path,fromScript)->
        url = URI.URI
        if fromScript
            realPath = url.resolve(fromScript.scriptPath,path)
        else
            realPath = url.normalize(path)
        if realPath.indexOf("/") is 0
            realPath = realPath.substring(1)
        script = @getScript(realPath)
        if not script
            throw new Error "module #{realPath} not found"
        return script
    require:(path,fromScript)->
        script = @getRequiredScript(path,fromScript)
        return script.beRequired()
    restoreCache:()->
        try
            @store = JSON.parse window.localStorage.getItem("#{@localStoragePrefix}/cache") or "{}"
        catch e
            @store = {}
        if @store.config
            @loadConfig @store.config
        @store.files ?= {}
        return
    isCacheAtomic:()->
        if not @store
            return false
        files = @store.files or {}
        for script in @scripts
            if script.hash and script.loadPath and files[script.loadPath] and files[script.loadPath].hash is script.hash
                continue
            else
                return false
        return true
    clearCache:(version)->
        window.localStorage.removeItem("#{@localStoragePrefix}/cache")
    compactCache:(option = {})->
        if @isCacheAtomic()
            return false
        if not @isReady
            return false
        if @hasConfiged or option.exportConfig
            @store.config = @toConfig()
        @store.files = {}
        for script in @scripts
            if not script.scriptContent
                return false
        for script in @script
            script._saveScriptContentToStore(script.scriptContent)
        return true

    load:(option = {},callback)->
        if typeof option is "function"
            callback = option
        loadFailure = false
        @scripts.forEach (script)=>
            script.load (err)=>
                if loadFailure
                    return
                if err
                    loadFailure = true
                    callback new Error "fail to load script #{script.loadPath}"
                    return
                allReady = @scripts.every (item)=>
                    if not item.isReady and not (item.dryReady and @dry)
                        return false
                    return true
                if allReady
                    @isReady = true
                    callback()
    saveCache:(option = {})->
        store = @store or {}
        if @hasConfiged or option.exportConfig
            store.config = @toConfig()
        @_debug "save cache",store,"#{@localStoragePrefix}/cache"
        window.localStorage.setItem "#{@localStoragePrefix}/cache",JSON.stringify store or {}
    saveCacheDelay:()->
        if @_saveCacheDelayTimer
            clearTimeout @_saveCacheDelayTimer
        @_saveCacheDelayTimer = setTimeout (()=>
            @saveCache()
            ),0
    clone:(option)->
        c = new Context(option)
        c.loadConfig @toConfig()
        c.scripts = @scripts.map (script)->script.clone(c)
        return c
class Script
    constructor:(@context,file)->
        url = URI.URI
        if typeof file is "string"
            @path = file
        else
            @path = file.path
            @hash = file.hash or null
        @scriptPath = url.normalize(@path)
        @loadPath = url.resolve(@context.root,file.loadPath or @path)
        @_debug = @context._debug.bind(this)
        if file.scriptContent
            @scriptContent = file.scriptContent
    clone:(context)->
        s = new Script(context,{
            @path,@hash,@loadPath
        })
        for prop in ["isReady","_module","_exports","_require","_isRequiring","exports","scriptContent"]
            s[prop] = @[prop]
        return s
    _restoreScriptContentFromStore:()->
        if @context.store and @context.store.files
            return @context.store.files[@loadPath]
        return null
    _saveScriptContentToStore:(content)->
        @_debug "save to #{@loadPath} with hash #{@hash} ??"
        @context.store.files[@loadPath] = {
            hash:@hash
            content:content
        }
    require:(path)->
        return @context.require path,this
    setRequire:(module,exports,__require)->
        @_module = module
        @_exports = exports
        @_require = __require
        @isReady = true
        if @_loadCallback
            @_loadCallback()
    beRequired:()->
        if @exports
            return @exports
        if @_isRequiring
            return @_module.exports
        @_isRequiring = true
        @_require()
        @_isRequiring = false
        if @_exports isnt @_module.exports
            # changed vai module.exports = xxx
            @_exports = @_module.exports
        @exports = @_exports
        return @exports
    load:(callback)->
        @_loadCallback = callback
        if @isReady
            callback()
            return
        if @scriptContent
            @importToDocument()
            return
        file = @_restoreScriptContentFromStore()
        @_debug "try restore #{@loadPath} from cache",file
        @_debug @hash,file and file.hash
        # has file, has content and
        if file and file.content and not (@version and @version isnt file.version)
            console.debug "return from",@context.name,@loadPath
            @_debug "cache found and do the restore"
            @_debug "#{@loadPath} from cache"
            @scriptContent = file.content
            setTimeout (()=>
                @importToDocument()
                ),0
            return
        Context._httpGet @loadPath,(err,content)=>
            if err
                callback new Error "fail to get #{@loadPath}"
                return
            @scriptContent = content
            @importToDocument()
    importToDocument:()->
        if @script
            null
        scriptContent = @scriptContent
        @_saveScriptContentToStore(scriptContent)
        if @context.dry and @_loadCallback
            @dryReady = true
            @_loadCallback()
            return
        script = document.createElement("script")
        code = """
(function(){
    var require = #{@context.globalName}.getContext(#{@context.id}).getRequire('#{@scriptPath}')
    require.context = #{@context.globalName}.getContext(#{@context.id})
    require.LeafRequire = #{@context.globalName}
    var module = {exports:{}};
    var exports = module.exports
    var global = window;
    var __require = function(){

// #{@scriptPath}
// BY leaf-require
#{scriptContent}

}
#{@context.globalName}.getContext(#{@context.id}).setRequire('#{@scriptPath}',module,exports,__require)

})()
        """
        if @context.debug or @context.enableSourceMap
            mapDataUrl = @createSourceMapUrl(scriptContent)
            code += """
    \n//# sourceMappingURL=#{mapDataUrl}
        """
        @script = script
        script.innerHTML = code
        document.body.appendChild(script)
    createSourceMapUrl:(content,offset = 11)->
        map = {
            "version" : 3,
            "file": @loadPath,
            "sourceRoot": "",
            "sources": [@loadPath],
            "sourcesContent": [content],
            "names": [],
            "mappings": null
        }
        result = []
        for _ in [0...offset]
            result.push ";"
        for line,index in content.split("\n")
            if index is 0
                result.push "AAAA"
            else
                result.push ";AACA"
        map.mappings = result.join("")
        url ="data:application/json;base64,#{btoa unescape encodeURIComponent JSON.stringify(map)}"
        #url = "data:text/plain;charset=utf-8,#{unescape encodeURIComponent JSON.stringify(map)}"
        #url = URL.createObjectURL new Blob([JSON.stringify(map)],{type:"text/json"})
        return url
class Context.BestPractice
    constructor:(option)->
        @config = option.config or "./require.json"
        @localStoragePrefix = option.localStoragePrefix
        @errorHint = option.errorHint or @errorHint
        @updateConfirm = option.updateConfirm or @updateConfirm
        @debug = option.debug or false
        @showDebugInfo = option.showDebugInfo or option.debug or false
        @enableSourceMap = option.enableSourceMap or false
        @entry = option.entry or "main"
    _debug:(args...)->
        if @debug or @showDebugInfo
            console.debug ?= console.log.bind(console)
            console.debug args...
    run:(callback)->
        @context = new LeafRequire({@localStoragePrefix,@enableSourceMap})
        if @debug
            @context.loadConfig @config,()=>
                console.error "load config QAQ"
                @context.load ()=>
                    if callback
                        callback()
                    else
                        @context.require @entry
            return
        @context.restoreCache()
        if @context.hasConfiged
            if @context.isCacheAtomic()
                @_debug "may use cache completely"
            @context.load (err)=>
                @_debug "has config"
                if err
                    @errorHint()
                    return
                setTimeout @checkVerionUpdate.bind(this),0
                @context.require @entry
                return
        else
            @context.loadConfig @config,(err)=>
                if err
                    @errorHint()
                    return
                @context.load (err)=>
                    if err
                        @errorHint()
                        return
                    @context.saveCache()
                    @context.require @entry

    errorHint:()->
        alert "Fail to load application, please reload the webpage. If not work, please contact admin."
    updateConfirm:(callback)->
        message = "detect a new version of the app, should we reload"
        callback confirm(message)
    semanticCompare:(a = "",b = "")->
            as = a.split(".")
            bs = b.split(".")
            while as.length > bs.length
                bs.push "0"
            while bs.length > as.length
                as.push "0"
            as = as.map (item)->Number(item) or 0
            bs = bs.map (item)->Number(item) or 0
            for va,index in as
                vb = bs[index]
                if va > vb
                    return 1
                else if va < vb
                    return -1
            return 0
    checkVerionUpdate:()->
        checker = new Context({localStoragePrefix:@localStoragePrefix,dry:true})
        @_debug "check config"
        checker.loadConfig @config,(err)=>
            if err
                # fail silently to user
                console.error err,"fail to do load config"
                return
            checker.name = "checker"
            @_debug "check config loaded"
            # we use semantic version like 1.2.3.abc
            # as long as the version changed, we upgrades
            # this allow us to rolling back
            if (@semanticCompare checker.version,@context.version) isnt 0
                @_debug @context.version,"<",checker.version
                @_debug "check config detect updates, load it"
                checker.load (err)=>
                    # fail silently
                    if err
                        console.error err,"fail to load updates"
                        return
                    @_debug "updates load complete"
                    checker.compactCache()
                    checker.saveCache()
                    @updateConfirm (result)->
                        if result
                            if not window.location.reload?()
                                window.location = window.location.toString()
            else
                @_debug "check config complete, no updates: version #{checker.version}"
class BundleBuilder
    @fromStandAloneConfig = (config)->
        url = URI.URI
        scripts = config.js.files.map (file)->
            return {
                path:url.normalize(file.path)
                scriptContent:file.scriptContent
            }
        builder = new BundleBuilder({
            contextName:config.contextName
        })
        builder.addScript scripts...
        if config.js.main
            builder.addEntryModule(config.js.main)
        return builder
    constructor:(option = {})->
        @prefixCodes = []
        @scripts = []
        @suffixCodes = []
        @contextName = option.contextName or "GlobalContext"
    addScript:()->
        scripts = (item for item in arguments)
        url = URI.URI
        @scripts.push (scripts.map (file)=>
            return {
                path:url.normalize(file.path)
                content:file.scriptContent
            }
        )...
    addPrefixFunction:(fn)->
        @prefixCodes.push "(#{fn.toString()})()"
    addEntryFunction:(fn)->
        @suffixCodes.push "(#{fn.toString()})()"
    addEntryModule:(name)->
        @suffixCodes.push "(function(){#{@contextName}.require(\"#{name}\")})()"
    generateWorker:()->
        js = @generateBundle()
        url = URL.createObjectURL new Blob([js])
        worker = new Worker(url)
        return worker
    generateBundle:()->
        prefix = @prefixCodes.join(";\n")
        suffix = @suffixCodes.join(";\n")
        scripts = @scripts.map (script)=>
            return @moduleTemplate
            .replace(/{{contextName}}/g,@contextName)
            .replace(/{{currentModulePath}}/g,script.path)
            .replace("{{currentModuleContent}}",script.content)
        core = @coreTemplate
            .replace(/{{contextName}}/g,@contextName)
            .replace("{{modules}}",scripts.join(";\n"))
            .replace("{{createContextProcedure}}",@getPureFunctionProcedure("createBundleContext"))
            .replace("{{BundleBuilderCode}}",@getPureClassCode(BundleBuilder))
        return [prefix,core,suffix].join(";\n")
    getPureFunctionProcedure:(name)->
        return "(#{@["$$"+name].toString()})()"
    getPureClassCode:(ClassObject,className)->
        if not className
            className = ClassObject.name
        constructor =  ClassObject.toString()
        template = "#{className}.prototype[\"{{prop}}\"] = {{value}};"
        codes = []
        for prop,value of ClassObject.prototype
            if typeof value is "function"
                value = value.toString()
            else
                value = JSON.stringify value
            codes.push template.replace("{{prop}}",prop).replace("{{value}}",value)

        return """
        #{className} = #{constructor.toString()}
        #{codes.join("\n")}
        """
    $$createBundleContext:()->
        return {
            modules:{}
            createDedicateWorker:(pathes,option)->
                bundle = new BundleBuilder({contextName:option.contextName or (@globalName or "GlobalContext")+"Worker"})
                for path in pathes
                    module = @getRequiredModule(path)
                    script = {
                        path
                        scriptContent:"(#{module.exec.toString()})()"
                    }
                    bundle.addScript script
                if option.entryModule
                    bundle.addEntryModule option.entryModule
                else if option.entryFunction
                    bundle.addEntryFunction option.entryFunction
                return bundle.generateWorker()
            require:(path)->
                return this.requireModule(null,path)
            getRequiredModuleContent:(path,fromPath)->
                module = @getRequiredModule(path,fromPath)
                return "(#{module.exec.toString()})()"
            getRequiredModule:(path,fromPath)->
                url = URI.URI
                if fromPath
                    realPath = url.resolve(fromPath,path)
                else
                    realPath = url.normalize(path)
                if realPath[0] is "/"
                    realPath = realPath.slice(1)
                if realPath.slice(-3) isnt ".js"
                    realPath += ".js"
                if !this.modules[realPath]
                    throw new Error("module " + path + " required at " + (fromPath || "/") + " is not exists")

                module = this.modules[realPath];
                return module
            requireModule:(fromPath,path)->
                module = @getRequiredModule(path,fromPath)
                if module.exports
                    return module.exports
                if module.isRequiring
                    return module.module.exports

                module.isRequiring = true
                module.exec()
                module.exports = module.module.exports
                module.isRequiring = false
                return module.exports
            setModule:(modulePath,module,exec)->
                if modulePath.slice(-3) isnt ".js"
                    modulePath += ".js"

                this.modules[modulePath] = {
                    module:module,
                    exec:exec
                }
        }
    moduleTemplate:"""(function(){
    var require = {{contextName}}.requireModule.bind({{contextName}},"{{currentModulePath}}");
    var module = {};
    module.exports = {};
    var exports = module.exports;
    function exec(){
        {{currentModuleContent}}
    }
    {{contextName}}.setModule("{{currentModulePath}}",module,exec);
})()"""
    coreTemplate:"""(function(){
    /**
     * Implementation of base URI resolving algorithm in rfc2396.
     * - Algorithm from section 5.2
     *   (ignoring difference between undefined and '')
     * - Regular expression from appendix B
     * - Tests from appendix C
     *
     * @param {string} uri the relative URI to resolve
     * @param {string} baseuri the base URI (must be absolute) to resolve against
     */

    URI = function(){
        function resolveUri(sUri, sBaseUri) {
	    if (sUri == '' || sUri.charAt(0) == '#') return sUri;
	    var hUri = getUriComponents(sUri);
	    if (hUri.scheme) return sUri;
	    var hBaseUri = getUriComponents(sBaseUri);
	    hUri.scheme = hBaseUri.scheme;
	    if (!hUri.authority) {
	        hUri.authority = hBaseUri.authority;
	        if (hUri.path.charAt(0) != '/') {
		    aUriSegments = hUri.path.split('/');
		    aBaseUriSegments = hBaseUri.path.split('/');
		    aBaseUriSegments.pop();
		    var iBaseUriStart = aBaseUriSegments[0] == '' ? 1 : 0;
		    for (var i in aUriSegments) {
		        if (aUriSegments[i] == '..')
			    if (aBaseUriSegments.length > iBaseUriStart) aBaseUriSegments.pop();
		        else { aBaseUriSegments.push(aUriSegments[i]); iBaseUriStart++; }
		        else if (aUriSegments[i] != '.') aBaseUriSegments.push(aUriSegments[i]);
		    }
		    if (aUriSegments[i] == '..' || aUriSegments[i] == '.') aBaseUriSegments.push('');
		    hUri.path = aBaseUriSegments.join('/');
	        }
	    }
	    var result = '';
	    if (hUri.scheme   ) result += hUri.scheme + ':';
	    if (hUri.authority) result += '//' + hUri.authority;
	    if (hUri.path     ) result += hUri.path;
	    if (hUri.query    ) result += '?' + hUri.query;
	    if (hUri.fragment ) result += '#' + hUri.fragment;
	    return result;
        }
        uriregexp = new RegExp('^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\\\?([^#]*))?(#(.*))?');
        function getUriComponents(uri) {
	    var c = uri.match(uriregexp);
	    return { scheme: c[2], authority: c[4], path: c[5], query: c[7], fragment: c[9] };
        }
        var URI = {}
        URI.resolve = function(base,target){
            return resolveUri(target,base);
        }
        URI.normalize = function(url){
            return URI.resolve("",url);
        }
        return {URI:URI}
    }();
    {{BundleBuilderCode}}
    {{contextName}} = {{createContextProcedure}};
    {{contextName}}.contextName = "{{contextName}}";
    {{modules}};
})()"""


Context.BundleBuilder = BundleBuilder
if typeof window isnt "undefined"
    window.module = {
        exports:window
    }
module.exports.LeafRequire = Context
