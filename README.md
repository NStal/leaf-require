# leaf-require

A experiment lib allow you use nodejs style sync require in browser without precompile ... written in coffee. 

## Feature
* do what common module do.
* localStorage cache support
* version support
* source map support, you will not notice any difference of your code when debug, just like directly include them in the html.
* friendly with manifest.

## example

All the example script can be found at /example.

### Basic usage
```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <script type="text/javascript" src="../leaf-require.js"></script>
    <script type="text/javascript" src="./init.js"></script>
  </head>
  <body>
  </body>
</html>
```

Then we write a init.js to setup the requirements.

```javascript
  //init.js
  var context;

  context = new LeafRequire({
    root: "./test/"
  });
  context.debug = true; // open source map
  context.use("a.js"
        , "b.js"
        , "c.js"
        , "main.js"
        , "sub/subA.js"
        , "sub/subB.js"
        , "rootA.js");

  context.load(function() {
    console.log("inited");
    context.require("main");
    // main will require a.js 
    // a.js will require b.js and c.js
    // b.js will require a.js (recursive require behaves just like nodejs)
    
    context.require("sub/subA");
    // sub/subA.js will require rootA.js
    // rootA.js will require sub/subB.js
  });
```

a.js may looks like below.

```javascript
b = require("b")
c = require("c")
console.log("I'm module a!");
```

### manage requirements with a config
```javascript
var context = new LeafRequire({
  root: "./test/"
});
// config can be a url to the config file
var config = "asset/require.json"
context.setConfig(config,function(err){
  console.assert(!err);
  context.load(function(err){
    console.assert(!err);
    context.require("main");
  })
})

```

require.json may looks like below, // is invalid for json, so don't add them to your json file

```javascript
{
    "name": "leaf-require",
    "js": {
        "root": "./",  // request root, togather with the file path we generate the request url
        "files": [
            {
                //remote file path and local require path as well
                "path": "init.js", 
                // optional a hash to the file so if hash not modified and cache is enabled 
                // we will try to load scripts from localStorage
                "hash": "2ba20d" 
            },
            {
                "path": "main.js",
                "hash": "13338a"
            },
            {
                "path": "rootA.js",
                "hash": "f54367"
            },
            {
                "path": "test/a.js",
                "hash": "2859bc"
            },
            {
                "path": "test/b.js",
                "hash": "24cbd7"
            },
            {
                "path": "test/c.js",
                "hash": "472654"
            },
            {
                "path": "test/main.js",
                "hash": "413b74"
            },
            {
                "path": "test/rootA.js",
                "hash": "8285bf"
            },
            {
                "path": "test/sub/subA.js",
                "hash": "62a110"
            },
            {
                "path": "test/sub/subB.js",
                "hash": "4a748f"
            }
        ]
    },
    // enable debug mode, currently just for source map
    "debug": true,
    // enable cache so the script will be stored to localStorage
    // and next time, they will be likely stored from localStorage
    // if hash matches.
    "cache": false
}
```

You can easily generate this config by using leafjs-util. You can generate the above codes at ```example/``` directory of this repo.
```bash
sudo npm install -g leafjs-util

leafjs-require -h   # print the help message
leafjs-require ./ --excludes ./lib --enable-debug -r "./"
# The config will be print to stdout.
# You can also use -o option to specify a file to store it.
# Note, if -o with an exists file, leafjs-require 
# will try to inherit it's property like debug and cache.
# You can give a -f option to force overwrite and get rid of this behavior.
```

### difference with commonjs module
```require("a.js")``` will be /{root}/{requiringScriptPath}/a.js

```require("/a.js")``` will be /{root}/a.js

```require("/a")``` will be /{root}/a or then /{root}/a.js

### useful features

```javascript

context.enableCache = true  // try load script from local storage first
context.clearCache()        // clear cache so force an reload
context.debug = true        // enable source map feature for easier debug
```

# test

Testcase require nodejs and grunt

```bash
npm install
npm test
```

and open http://localhost:3000/test/index.html to see the result.