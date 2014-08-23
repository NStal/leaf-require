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
    @getContext = (id)->
        return @instances[id]
    @_httpGet = (url,callback)->
        XHR = new XMLHttpRequest()
        XHR.open("GET",url,true)
        XHR.onreadystatechange = (err)=>
            if XHR.readyState is 4
                callback null,XHR.responseText
            if XHR.readyState is 0
                callback new Error "Network Error"
        XHR.send()

    constructor:(option = {})->
        @scripts = []
        @root = option.root or "./"
        @ready = false
        @id = Context.id++
        @globalName = "LeafRequire"
        @useObjectUrl = false
        @version = "0.0.0"
        Context.instances[@id] = this
        @localStoragePrefix = "leaf-require"
    use:(files...)->
        for file in files
            console.log "use",file.path or file
            @scripts.push new Script this,file
    getScript:(path)->
        for script in @scripts
            if script.scriptPath is path
                return script 
        if path.lastIndexOf(".js") isnt path.length - ".js".length
            for script in @scripts
                if script.scriptPath is path+".js"
                    return script
        return null
    setConfig:(config,callback)->
        if typeof config is "string"
            @setConfigRemote config,callback
        else
            try
                @setConfigSync(config)
                callback()
            catch e 
                callback(e)
        
    setConfigSync:(config)->
        config.js = config.js or {}
        files = config.js.files or []
        @root = config.js.root or @root
        for file in files
            @use file
        @name = config.name
        @localStoragePrefix = @name
        @mainModule = config.js.main or null
        @debug = config.debug or @debug
        @enableCache = config.cache or @enableCache or node @debug or false
    setConfigRemote:(src,callback)->
        if @enableCache
            @prepareCache()
            @cache.config = @cache.config or {}
            if @cache.config[src]
                @setConfigSync JSON.parse @cache.config[src]
                callback null
                return
        Context._httpGet src,(err,content)=>
            if err
                console.error err
                callback new Error "fail to get configs #{src} due to network error"
                return
            try
                config = JSON.parse content
                @setConfigSync config
                
                if @enableCache
                    @prepareCache()
                    @cache.config = @cache.config
                    @cache.config[src] = content
                callback null
            catch e
                callback e
    getRequire:(path)->
        script = @getScript(path)
        return (_path)->
            return script.require(_path)
    setRequire:(path,module,exports,__require)->
        script = @getScript(path)
        script.setRequire(module,exports,__require)
    require:(path,fromScript)-> 
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
        return script.beRequired()
    load:(callback)->
        @scripts.forEach (script)=>
            script.load (err)=>
                if err
                    throw new Error "fail to load script #{script.loadPath}"
                allReady = @scripts.every (item)=>
                    if not item.isReady
                        return false
                    return true
                if allReady
                    if @mainModule
                        @require @mainModule
                    callback()
    clearCache:(version)->
        if not window.localStorage
            return
        keys = (window.localStorage.key(index) for index in [0...window.localStorage.length])
        for key in keys
            if key.indexOf(@localStoragePrefix) is 0
                window.localStorage.removeItem key
    prepareCache:()->
        if not window.localStorage
            @cache = {}
            return
        if @cache
            return
        cache = window.localStorage.getItem("#{@localStoragePrefix}/cache") or "{}"
        try
            @cache = JSON.parse cache
        catch e
            @cache = {}
        return
    saveCache:()->
        if not window.localStorage
            return
        cache = @cache or {}
        window.localStorage.setItem "#{@localStoragePrefix}/cache",JSON.stringify cache
    saveCacheDelay:()->
        if @_saveCacheDelayTimer
            clearTimeout @_saveCacheDelayTimer
        @_saveCacheDelayTimer = setTimeout (()=>
            @saveCache()
            ),0
class Script
    constructor:(@context,file)->
        url = URI.URI
        if typeof file is "string"
            @path = file
        else
            @path = file.path
            @version = file.version or file.hash or null
        @scriptPath = url.normalize(@path)
        @loadPath = url.resolve(@context.root,@path)
    _restoreScriptContentFromCache:()->
        @context.prepareCache()
        files = @context.cache.files or {}
        return files[@path]
    _saveScriptContentToCache:(content)->
        @context.prepareCache()
        files = @context.cache.files = @context.cache.files or {}
        files[@path] = {
            hash:@hash
            content:content
        }
        @context.saveCacheDelay()
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
        if @context and @context.enableCache
            file = @_restoreScriptContentFromCache()
            # has file, has content and
            if file and file.content and not (@version and @version isnt file.version)
                console.debug "#{@loadPath} from cache"
                setTimeout (()=>
                    @parse file.content
                    ),0
                return
        Context._httpGet @loadPath,(err,content)=>
            
            if err
                console.error err
                throw new Error "fail to get #{@loadPath}"
            @parse content
    parse:(scriptContent)->
        if @context.enableCache
            @_saveScriptContentToCache(scriptContent)
        script = document.createElement("script")
        code = """
(function(){
    var require = #{@context.globalName}.getContext(#{@context.id}).getRequire('#{@scriptPath}')
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
        if @context.debug
            mapDataUrl = @createSourceMapUrl(scriptContent)
            code += """
    //# sourceMappingURL=#{mapDataUrl}
        """
        script.innerHTML = code
        document.body.appendChild(script)
    createSourceMapUrl:(content)->
        
        offset = 9
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
        url = URL.createObjectURL new Blob([JSON.stringify(map)],{type:"text/json"})
        return url
if not exports
    exports = window
exports.LeafRequire = Context