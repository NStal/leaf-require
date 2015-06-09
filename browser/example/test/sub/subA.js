console.log("I'm subA from sub/subA.js");
console.log("I'm about to require rootA.js at /rootA.js which is ../rootA.js from me");
require("../rootA.js");
