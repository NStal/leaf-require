# leaf-require

A experiment lib allow you use nodejs style sync require in browser without precompile ... written in coffee. 

## Feature
* do what common module do.
* localStorage cache support
* flexible version support
* source map support, you will not notice any difference of your code when debug, just like directly include them in the html.
* friendly with manifest.

## example

All the example script can be found at /example.

### Best practice

here introduce the best practice of `leaf-require`.

first create a config file using leafjs-require from npm.
```bash
npm install -g leafjs-util
# print help for leafjs-require
leafjs-require -h
# see the script below at ./example/best-practice/createRequire.sh
# create the config file
read version < ./version
 [ -z "$version" ] && version=0
# everytime after creating require.json, version bumps.
version=$((version + 1))
echo $version > ./version
leafjs-require ./js -r "./js" --set-version "0.0.0."$version -o ./require.json --excludes ./js/init.js,./js/lib/leaf-require.js
```

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

Then we write a init.coffee to setup .

```coffee-script
loader = new LeafRequire.BestPractice({
    localStoragePrefix:"SybilLeafRequire"
    ,config:"./require.json"
    ,showDebugInfo:true
    # the first module to run after load
    ,entry:"main"
})
loader.run()
```

require.json may looks like below, // is invalid for json, so don't add them to your json file

```javascript
{
    "name": "leaf-require",
    "version": "0.0.1",
    "js": {
        "root": "./test/",  // request root, togather with the file path we generate the request url
        "files": [
            {
                //remote file path and local require path as well
                "path": "a.js",
                // we will try to load scripts from localStorage
                "hash": "2859bc"
            },
            {
                "path": "b.js",
                "hash": "24cbd7"
            },
            {
                "path": "c.js",
                "hash": "472654"
            },
            {
                "path": "main.js",
                "hash": "413b74"
            },
            {
                "path": "rootA.js",
                "hash": "8285bf"
            },
            {
                "path": "sub/subA.js",
                "hash": "62a110"
            },
            {
                "path": "sub/subB.js",
                "hash": "4a748f"
            }

        ]
    },
}
```

You can easily generate this config by using leafjs-util. You can generate the above codes at ```example/``` directory of this repo.
```bash
sudo npm install -g leafjs-util

leafjs-require -h   # print the help message
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

### useful features in BestPractice
```coffee-script
new BestPractive {
    errorHint:()->
        console.error "give user some feedback to let them try again later"
    updateConfirm:(callback)->
        console.log ask user to refresh the page"
        callback confirm "update detected, shall we reload now?"
    # ignore cache completely and compile source map.
    debug:true
    # you can also only enable source map
    enableSourceMap:true
    # use a prefix to avoid cache key conflict in `localStorage`
    localStoragePrefix:"PrefixToAvoidConflict"
}
```


# test

Testcase require nodejs and grunt

```bash
npm install
npm test
```

and open http://localhost:3000/test/index.html to see the result.
