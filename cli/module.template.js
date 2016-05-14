;(function(){
    var require = window.{{contextName}}.requireModule.bind(window.{{contextName}},"{{currentModulePath}}");
    var module = {};
    module.exports = {};
    var exports = module.exports;
    function exec(){
        {{currentModuleContent}}
    }
    window.GlobalContext.setModule("{{currentModulePath}}",module,exec);
})()
