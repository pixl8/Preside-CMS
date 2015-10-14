module.exports = function(grunt) {
	// load all grunt tasks
	require('load-grunt-tasks')(grunt);

	grunt.registerTask( 'default', [ 'concat:base', 'uglify:base', 'sass:base', 'cssmin:base' ] );

	// grunt config
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),

		concat: {
			base: {
				src: ['js/src/*.js'],
				dest: 'js/base.js',
			}
		},

		cssmin: {
			base: {
				src: ['css/base.css'],
				dest: 'css/base.min.css'
			}
		},

		sass: {
			base: {
				files: [{
					cwd: 'sass/',
					dest: 'css/',
					expand: true,
					ext: '.css',
					src: ['*.scss']
				}],
				options: {
					sourcemap: 'none',
					style: 'expanded'
				}
			}
		},

		uglify: {
			base: {
				files: {
					'js/base.min.js': ['js/base.js']
				}
			}
		},

		watch: {
			base: {
				files: ['js/src/*.js', 'sass/**/*.scss'],
				tasks: ['concat:base', 'uglify:base', 'sass:base', 'cssmin:base']
			}
		},

		// dev update
		devUpdate: {
			main: {
				options: {
					semver: false,
					updateType: 'prompt'
				}
			}
		}
	});
};