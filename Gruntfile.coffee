'use strict';

module.exports = (grunt)->
	grunt.initConfig(
		connect:
			server:
				options:
					port: 3000
					base: "."
					hostname: "*"
		
		watch: 
			all: 
				options: 
					livereload: true
				files: ['test/index.html', 'leafRequire.js']
			
		

	);

	grunt.loadNpmTasks('grunt-contrib-connect')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.registerTask('test', ['connect', 'watch'])