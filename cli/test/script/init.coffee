config = window.location.hash.toString()?.replace("#","")
bp = new LeafRequire.BestPractice({config,debug:true})
bp.run()
