LeafRequire = {}
#info = JSON.parse(localStorage.get("leafRequireIndex") or "{}")
class Script
    @scripts = []
    @dict = {}
    @fullNameDict = {}
    constructor:(url)->
        #use url to check version
        @url = url
        @ready = false
        @fullName = url.replace(/\?.*/ig,"")
        @exports = null
        if @fullName.lastIndexOf("/") >= 0
            @name = @fullName.substring(@fullName.lastIndexOf("/")+1)
        else
            @name = @fullName
        Script.scripts.push this
        Script.dict[@name] = this
        Script.fullNameDict[@fullName] = this
       
    load:(callback)->
        @callback = callback
        json = JSON.parse(localStorage.getItem("leaf-require-script-#{@name}") or "{}")
        if LeafRequire.enableCache and json.url is @url
            console.log "#{@fullName} in cache"
            @setScript json.script
        else
            console.log "fetch #{@fullName}"
            LeafRequire.getRemoteScript @url,(err,script)=>
                if err
                    @callback err
                    return
                @setScript(script)
                @save()
    _ready:()->
        if @callback
            @callback(null,this)
        @isReady = true
    save:()->
        localStorage.setItem("leaf-require-script-#{@name}",@toString())
    toString:()->
        JSON.stringify({url:@url,script:@script})
    require:()->
        @exports = @_require(@exports)
        return @exports
    setScript:(script)->
        @script = script
        wrapper = """
LeafRequire.Script.fullNameDict["{fullName}"]._require = function(exports){
    if(exports) return exports;
    else exports = {};
    (function(exports){
        var global = window;
        {code};
    })(exports);
    return exports;
}
LeafRequire.Script.fullNameDict["{fullName}"]._ready()
    """
        insertScript = wrapper.replace(/{fullName}/g,@fullName).replace("{code}",@script)
        @src = URL.createObjectURL(new Blob([insertScript],{type:"text/javascript"}))
        tag = document.createElement("script")
        tag.src = @src#+"##{@fullName}"
        document.body.appendChild tag
LeafRequire.Script = Script
LeafRequire.requirements = []
LeafRequire.use = (args...)->
    for url in args
        LeafRequire.requirements.push url
LeafRequire.getRemoteScript = (url,callback)->
    xhr = new XMLHttpRequest()
    xhr.open "GET",url,true
    xhr.onreadystatechange = ()=>
        if xhr.readyState is 4
            callback null,xhr.responseText
    xhr.send()
    return xhr
LeafRequire.require = (name)->
    script = Script.dict[name] or Script.fullNameDict[name]
    if not script
        throw "module #{name} not found"
    return script.require()
        
        
LeafRequire.init = (entry,callback)->
    ready = ()=>
        callback()
        LeafRequire.require(entry)
    LeafRequire.entry = entry
    
    if entry not in LeafRequire.requirements
        LeafRequire.requirements.push entry
    counter = 0
    total = LeafRequire.requirements.length
    for url in LeafRequire.requirements
        _ = new Script(url)
        _.load (err,script)->
            console.log "script load ready",script.fullName
            if err
                console.error "fail to load script",script
                throw "fail to load script"
            counter++
            if counter is total
                ready()
window.LeafRequire = LeafRequire
window.require = LeafRequire.require
