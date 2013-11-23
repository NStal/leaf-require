# browser-sync-require

A experiment script allow you use node style sync require in browser.

## Feature
* cache javascript.
* do what node module do.

## Todo
* auto dependency detect

## example

```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <script type="text/javascript" src="../leafRequire.js"></script>
  </head>
  <body>
    
  </body>
  <script type="text/javascript">
    LeafRequire.enableCache = true;
    LeafRequire.use("./test1.js?version=2","test2.js","test3.js");
    LeafRequire.init("testMain.js",function(){
    console.log("every body is loaded!");
    })    
  </script>
</html>
```
```javascript
//test1.js
exports.callMe = function() {
  return console.log("Test1.called!");
};

console.log("Test1.loaded I'm loaded");

//test2.js
exports.callMe = function() {
  return console.log("Test2.called!");
};

console.log("Test2.loaded I'm loaded");

//test3.js
exports.callMe = function() {
  return console.log("Test3.called!");
};

console.log("Test3.loaded I'm loaded");

//testMain.js

console.log("Main loaded");

console.log("require test1");

test1 = require("test1.js");

console.log("require test2");

test2 = require("test2.js");

console.log("require test3");

test3 = require("test3.js");

test1.callMe();

test2.callMe();

test3.callMe();

console.log("require test1 again");

nextTest1 = require("test1.js");

console.log("nothing should happen..");

console.log("now call next test1")
nextTest1.callMe();


```


require should be
```
fetch ./test1.js 
fetch test2.js 
fetch test3.js 
fetch testMain.js 
script load ready ./test1.js 
script load ready test2.js 
script load ready test3.js 
script load ready testMain.js 
every body is loaded! index.html:14
Main loaded 
require test1 
Test1.loaded I'm loaded 
require test2 
Test2.loaded I'm loaded 
require test3 
Test3.loaded I'm loaded 
Test1.called! 
Test2.called! 
Test3.called! 
require test1 again 
nothing should happen.. 
now call next test1
Test1.called! 
```