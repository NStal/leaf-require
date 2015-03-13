loader = new LeafRequire.BestPractice({
    localStoragePrefix:"SybilLeafRequire"
    ,config:"./require.json"
    ,showDebugInfo:true
    # the first module to run after load
    ,entry:"main"
})
loader.run()
