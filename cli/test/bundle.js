;
(function(){
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
}();
BundleBuilder = function BundleBuilder(option) {
      if (option == null) {
        option = {};
      }
      this.prefixCodes = [];
      this.scripts = [];
      this.suffixCodes = [];
      this.contextName = option.contextName || "GlobalContext";
    }
BundleBuilder.prototype["addScript"] = function () {
      var item, ref, scripts, url;
      scripts = (function() {
        var i, len, results1;
        results1 = [];
        for (i = 0, len = arguments.length; i < len; i++) {
          item = arguments[i];
          results1.push(item);
        }
        return results1;
      }).apply(this, arguments);
      url = URI.URI;
      return (ref = this.scripts).push.apply(ref, scripts.map((function(_this) {
        return function(file) {
          return {
            path: url.normalize(file.path),
            content: file.scriptContent
          };
        };
      })(this)));
    };
BundleBuilder.prototype["addPrefixFunction"] = function (fn) {
      return this.prefixCodes.push("(" + (fn.toString()) + ")()");
    };
BundleBuilder.prototype["addEntryFunction"] = function (fn) {
      return this.suffixCodes.push("(" + (fn.toString()) + ")()");
    };
BundleBuilder.prototype["addEntryModule"] = function (name) {
      return this.suffixCodes.push("(function(){" + this.contextName + ".require(\"" + name + "\")})()");
    };
BundleBuilder.prototype["generateWorker"] = function () {
      var js, url, worker;
      js = this.generateBundle();
      url = URL.createObjectURL(new Blob([js]));
      worker = new Worker(url);
      return worker;
    };
BundleBuilder.prototype["generateBundle"] = function () {
      var core, prefix, scripts, suffix;
      prefix = this.prefixCodes.join(";\n");
      suffix = this.suffixCodes.join(";\n");
      scripts = this.scripts.map((function(_this) {
        return function(script) {
          return _this.moduleTemplate.replace(/{{contextName}}/g, _this.contextName).replace(/{{currentModulePath}}/g, script.path).replace("{{currentModuleContent}}", script.content);
        };
      })(this));
      core = this.coreTemplate.replace(/{{contextName}}/g, this.contextName).replace("{{modules}}", scripts.join(";\n")).replace("{{createContextProcedure}}", this.getPureFunctionProcedure("createBundleContext")).replace("{{BundleBuilderCode}}", this.getPureClassCode(BundleBuilder));
      return [prefix, core, suffix].join(";\n");
    };
BundleBuilder.prototype["getPureFunctionProcedure"] = function (name) {
      return "(" + (this["$" + name].toString()) + ")()";
    };
BundleBuilder.prototype["getPureClassCode"] = function (ClassObject, className) {
      var codes, constructor, prop, ref, template, value;
      if (!className) {
        className = ClassObject.name;
      }
      constructor = ClassObject.toString();
      template = className + ".prototype[\"{{prop}}\"] = {{value}};";
      codes = [];
      ref = ClassObject.prototype;
      for (prop in ref) {
        value = ref[prop];
        if (typeof value === "function") {
          value = value.toString();
        } else {
          value = JSON.stringify(value);
        }
        codes.push(template.replace("{{prop}}", prop).replace("{{value}}", value));
      }
      return className + " = " + (constructor.toString()) + "\n" + (codes.join("\n"));
    };
BundleBuilder.prototype["$createBundleContext"] = function () {
      return {
        modules: {},
        createDedicateWorker: function(pathes, option) {
          var bundle, i, item, j, len, len1, path, script, scripts;
          bundle = new BundleBuilder({
            contextName: option.contextName || (this.globalName || "GlobalContext") + "Worker"
          });
          for (i = 0, len = pathes.length; i < len; i++) {
            path = pathes[i];
            if (typeof path === "string") {
              script = this.getRequiredModule(path);
              scripts = [script];
            } else if (path.test) {
              scripts = this.getMatchingModules(path);
            } else {
              continue;
            }
            for (j = 0, len1 = scripts.length; j < len1; j++) {
              item = scripts[j];
              script = {
                path: path,
                scriptContent: "(" + (item.exec.toString()) + ")()"
              };
            }
            bundle.addScript(script);
          }
          if (option.entryModule) {
            bundle.addEntryModule(option.entryModule);
          } else if (option.entryFunction) {
            bundle.addEntryFunction(option.entryFunction);
          }
          return bundle.generateWorker();
        },
        require: function(path) {
          return this.requireModule(null, path);
        },
        getRequiredModuleContent: function(path, fromPath) {
          var module;
          module = this.getRequiredModule(path, fromPath);
          return "(" + (module.exec.toString()) + ")()";
        },
        getMatchingModules: function(path) {
          var item, modulePath, ref, results;
          results = [];
          ref = this.modules;
          for (modulePath in ref) {
            item = ref[modulePath];
            if (path.test(modulePath)) {
              results.push(item);
            }
          }
          return results;
        },
        getRequiredModule: function(path, fromPath) {
          var module, realPath, url;
          url = URI.URI;
          if (fromPath) {
            realPath = url.resolve(fromPath, path);
          } else {
            realPath = url.normalize(path);
          }
          if (realPath[0] === "/") {
            realPath = realPath.slice(1);
          }
          if (realPath.slice(-3) !== ".js") {
            realPath += ".js";
          }
          if (!this.modules[realPath]) {
            throw new Error("module " + path + " required at " + (fromPath || "/") + " is not exists");
          }
          module = this.modules[realPath];
          return module;
        },
        requireModule: function(fromPath, path) {
          var module;
          module = this.getRequiredModule(path, fromPath);
          if (module.exports) {
            return module.exports;
          }
          if (module.isRequiring) {
            return module.module.exports;
          }
          module.isRequiring = true;
          module.exec();
          module.exports = module.module.exports;
          module.isRequiring = false;
          return module.exports;
        },
        setModule: function(modulePath, module, exec) {
          if (modulePath.slice(-3) !== ".js") {
            modulePath += ".js";
          }
          return this.modules[modulePath] = {
            module: module,
            exec: exec
          };
        }
      };
    };
BundleBuilder.prototype["moduleTemplate"] = "(function(){\nvar require = {{contextName}}.requireModule.bind({{contextName}},\"{{currentModulePath}}\");\nvar module = {};\nmodule.exports = {};\nvar exports = module.exports;\nfunction exec(){\n    {{currentModuleContent}}\n}\n{{contextName}}.setModule(\"{{currentModulePath}}\",module,exec);\n})()";
BundleBuilder.prototype["coreTemplate"] = "(function(){\n/**\n * Implementation of base URI resolving algorithm in rfc2396.\n * - Algorithm from section 5.2\n *   (ignoring difference between undefined and '')\n * - Regular expression from appendix B\n * - Tests from appendix C\n *\n * @param {string} uri the relative URI to resolve\n * @param {string} baseuri the base URI (must be absolute) to resolve against\n */\n\nURI = function(){\n    function resolveUri(sUri, sBaseUri) {\n\t    if (sUri == '' || sUri.charAt(0) == '#') return sUri;\n\t    var hUri = getUriComponents(sUri);\n\t    if (hUri.scheme) return sUri;\n\t    var hBaseUri = getUriComponents(sBaseUri);\n\t    hUri.scheme = hBaseUri.scheme;\n\t    if (!hUri.authority) {\n\t        hUri.authority = hBaseUri.authority;\n\t        if (hUri.path.charAt(0) != '/') {\n\t\t    aUriSegments = hUri.path.split('/');\n\t\t    aBaseUriSegments = hBaseUri.path.split('/');\n\t\t    aBaseUriSegments.pop();\n\t\t    var iBaseUriStart = aBaseUriSegments[0] == '' ? 1 : 0;\n\t\t    for (var i in aUriSegments) {\n\t\t        if (aUriSegments[i] == '..')\n\t\t\t    if (aBaseUriSegments.length > iBaseUriStart) aBaseUriSegments.pop();\n\t\t        else { aBaseUriSegments.push(aUriSegments[i]); iBaseUriStart++; }\n\t\t        else if (aUriSegments[i] != '.') aBaseUriSegments.push(aUriSegments[i]);\n\t\t    }\n\t\t    if (aUriSegments[i] == '..' || aUriSegments[i] == '.') aBaseUriSegments.push('');\n\t\t    hUri.path = aBaseUriSegments.join('/');\n\t        }\n\t    }\n\t    var result = '';\n\t    if (hUri.scheme   ) result += hUri.scheme + ':';\n\t    if (hUri.authority) result += '//' + hUri.authority;\n\t    if (hUri.path     ) result += hUri.path;\n\t    if (hUri.query    ) result += '?' + hUri.query;\n\t    if (hUri.fragment ) result += '#' + hUri.fragment;\n\t    return result;\n    }\n    uriregexp = new RegExp('^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\\\?([^#]*))?(#(.*))?');\n    function getUriComponents(uri) {\n\t    var c = uri.match(uriregexp);\n\t    return { scheme: c[2], authority: c[4], path: c[5], query: c[7], fragment: c[9] };\n    }\n    var URI = {}\n    URI.resolve = function(base,target){\n        return resolveUri(target,base);\n    }\n    URI.normalize = function(url){\n        return URI.resolve(\"\",url);\n    }\n    return {URI:URI}\n}();\n{{BundleBuilderCode}}\n{{contextName}} = {{createContextProcedure}};\n{{contextName}}.contextName = \"{{contextName}}\";\n{{modules}};\n})()";
GlobalContext = (function () {
      return {
        modules: {},
        createDedicateWorker: function(pathes, option) {
          var bundle, i, item, j, len, len1, path, script, scripts;
          bundle = new BundleBuilder({
            contextName: option.contextName || (this.globalName || "GlobalContext") + "Worker"
          });
          for (i = 0, len = pathes.length; i < len; i++) {
            path = pathes[i];
            if (typeof path === "string") {
              script = this.getRequiredModule(path);
              scripts = [script];
            } else if (path.test) {
              scripts = this.getMatchingModules(path);
            } else {
              continue;
            }
            for (j = 0, len1 = scripts.length; j < len1; j++) {
              item = scripts[j];
              script = {
                path: path,
                scriptContent: "(" + (item.exec.toString()) + ")()"
              };
            }
            bundle.addScript(script);
          }
          if (option.entryModule) {
            bundle.addEntryModule(option.entryModule);
          } else if (option.entryFunction) {
            bundle.addEntryFunction(option.entryFunction);
          }
          return bundle.generateWorker();
        },
        require: function(path) {
          return this.requireModule(null, path);
        },
        getRequiredModuleContent: function(path, fromPath) {
          var module;
          module = this.getRequiredModule(path, fromPath);
          return "(" + (module.exec.toString()) + ")()";
        },
        getMatchingModules: function(path) {
          var item, modulePath, ref, results;
          results = [];
          ref = this.modules;
          for (modulePath in ref) {
            item = ref[modulePath];
            if (path.test(modulePath)) {
              results.push(item);
            }
          }
          return results;
        },
        getRequiredModule: function(path, fromPath) {
          var module, realPath, url;
          url = URI.URI;
          if (fromPath) {
            realPath = url.resolve(fromPath, path);
          } else {
            realPath = url.normalize(path);
          }
          if (realPath[0] === "/") {
            realPath = realPath.slice(1);
          }
          if (realPath.slice(-3) !== ".js") {
            realPath += ".js";
          }
          if (!this.modules[realPath]) {
            throw new Error("module " + path + " required at " + (fromPath || "/") + " is not exists");
          }
          module = this.modules[realPath];
          return module;
        },
        requireModule: function(fromPath, path) {
          var module;
          module = this.getRequiredModule(path, fromPath);
          if (module.exports) {
            return module.exports;
          }
          if (module.isRequiring) {
            return module.module.exports;
          }
          module.isRequiring = true;
          module.exec();
          module.exports = module.module.exports;
          module.isRequiring = false;
          return module.exports;
        },
        setModule: function(modulePath, module, exec) {
          if (modulePath.slice(-3) !== ".js") {
            modulePath += ".js";
          }
          return this.modules[modulePath] = {
            module: module,
            exec: exec
          };
        }
      };
    })();
GlobalContext.contextName = "GlobalContext";
(function(){
var require = GlobalContext.requireModule.bind(GlobalContext,"common.js");
var module = {};
module.exports = {};
var exports = module.exports;
function exec(){
    // Generated by CoffeeScript 1.10.0
(function() {
  module.exports.getTestData = (function(_this) {
    return function() {
      return "QAQ";
    };
  })(this);

}).call(this);

}
GlobalContext.setModule("common.js",module,exec);
})();
(function(){
var require = GlobalContext.requireModule.bind(GlobalContext,"dep.js");
var module = {};
module.exports = {};
var exports = module.exports;
function exec(){
    // Generated by CoffeeScript 1.10.0
(function() {
  var common, worker;

  common = require("./common");

  worker = GlobalContext.createDedicateWorker(["worker", "common"], {
    contextName: "WorkerContext",
    entryFunction: function() {
      return WorkerContext.require("worker");
    }
  });

  worker.addEventListener("message", function(e) {
    if (e.data === "ready") {
      console.log("worker ready");
      worker.postMessage(common.getTestData());
      return;
    }
    if (e.data === common.getTestData()) {
      alert("Work works!");
    }
  });

}).call(this);

}
GlobalContext.setModule("dep.js",module,exec);
})();
(function(){
var require = GlobalContext.requireModule.bind(GlobalContext,"init.js");
var module = {};
module.exports = {};
var exports = module.exports;
function exec(){
    // Generated by CoffeeScript 1.10.0
(function() {
  var bp, config, ref;

  config = (ref = window.location.hash.toString()) != null ? ref.replace("#", "") : void 0;

  bp = new LeafRequire.BestPractice({
    config: config,
    debug: true
  });

  bp.run();

  window.GlobalContext = bp.context;

}).call(this);

}
GlobalContext.setModule("init.js",module,exec);
})();
(function(){
var require = GlobalContext.requireModule.bind(GlobalContext,"main.js");
var module = {};
module.exports = {};
var exports = module.exports;
function exec(){
    // Generated by CoffeeScript 1.10.0
(function() {
  require("/dep");

}).call(this);

}
GlobalContext.setModule("main.js",module,exec);
})();
(function(){
var require = GlobalContext.requireModule.bind(GlobalContext,"worker.js");
var module = {};
module.exports = {};
var exports = module.exports;
function exec(){
    // Generated by CoffeeScript 1.10.0
(function() {
  var common;

  common = require("./common");

  self.addEventListener("message", (function(_this) {
    return function(e) {
      if (e.data === common.getTestData()) {
        return self.postMessage(common.getTestData());
      } else {
        return console.error("invalid message");
      }
    };
  })(this));

  self.postMessage("ready");

}).call(this);

}
GlobalContext.setModule("worker.js",module,exec);
})();
})();
(function(){GlobalContext.require("main")})()
