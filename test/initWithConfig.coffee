context = new LeafRequire()
#context.debug = true
#context.enableCache = true

descript "test leaf-require with config file",()->
    it "load config should success",(done)->
        context.setConfig "./leaf-require.json",(err)->
            done(err)
    it "load scripts should success",(done)->
        context.load ()->
            done()
