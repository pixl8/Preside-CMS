module.exports = function( grunt ) {

	grunt.loadNpmTasks( 'grunt-contrib-uglify' );
	grunt.loadNpmTasks( 'grunt-rev' );
	grunt.loadNpmTasks( 'grunt-contrib-clean' );

	grunt.registerTask( 'default', [ 'uglify', 'clean', 'rev' ] );

	grunt.initConfig( {
		uglify: {
			options:{
				  sourceMap     : true
				, sourceMapName : function( dest ){
					var parts = dest.split( "/" );
					parts[ parts.length-1 ] = "sourcemap." + parts[ parts.length-1 ].replace( /\.js$/, ".js.map" );
					return parts.join( "/" );
				 }
			},
			core: {
				src: [
					  'system/assets/js/admin/core/jquery-ui-*.js'
					, 'system/assets/js/admin/core/mustache.js'
					, 'system/assets/js/admin/core/jquery.uber.select.js'
					, 'system/assets/js/admin/core/jquery.fuelux.spinner.js'
					, 'system/assets/js/admin/core/jquery.autosize.js'
					, 'system/assets/js/admin/core/jquery.inputlimiter.1.3.1.js'
					, 'system/assets/js/admin/core/bootstrap.js'
					, 'system/assets/js/admin/core/ace.js'
					, 'system/assets/js/admin/core/ace-elements.js'
					, 'system/assets/js/admin/core/bloodhound.js'
					, 'system/assets/js/admin/core/bootstrap-timepicker.js'
					, 'system/assets/js/admin/core/bootstrap.datepicker.js'
					, 'system/assets/js/admin/core/dropzone.js'
					, 'system/assets/js/admin/core/i18n.js'
					, 'sysetm/assets/js/admin/core/preside.uber.select.with.browser.js'
					, 'system/assets/js/admin/core/preside.asset.picker.js'
					, 'system/assets/js/admin/core/formFields.js'
					, 'system/assets/js/admin/core/jquery.*.js'
					, 'system/assets/js/admin/core/list.js'
					, 'system/assets/js/admin/core/preside.*js'
				],
				dest: 'system/assets/compiled/js/core.min.js'
			},
			specific:{
				files: [{
					expand  : true,
					cwd     : 'system/assets/js/admin/specific',
					src     : '**/*.js',
					dest    : 'system/assets/compiled/js',
					ext     : ".min.js",
					rename  : function( dest, src ){
						return dest + "/" + src.replace( /\//g, "." );
					}
				}]
			},
			coretop: {
				src:"system/assets/js/admin/coretop/*.js",
				dest: 'system/assets/compiled/js/coretop.min.js'
			},
			coretopie: {
				src:"system/assets/js/admin/coretop/ie/*.js",
				dest: 'system/assets/compiled/js/coretop.ie.min.js'
			},
			devtools: {
				src:"system/assets/js/admin/devtools/*.js",
				dest: 'system/assets/compiled/js/devtools.min.js'
			},
			flot: {
				src:"system/assets/js/admin/flot/*.js",
				dest: 'system/assets/compiled/js/flot.min.js'
			},
			frontend: {
				src:"system/assets/js/admin/frontend/*.js",
				dest: 'system/assets/compiled/js/frontend.min.js'
			},
			jquery1: {
				src:"system/assets/js/admin/jquery/110/*.js",
				dest:"system/assets/compiled/js/jquery110.min.js"
			},
			jquery2: {
				src:"system/assets/js/admin/jquery/20/*.js",
				dest:"system/assets/compiled/js/jquery20.min.js"
			}
		},

		rev: {
			options: {
				algorithm : 'md5',
				length    : 8
			},
			assets: {
				src : "system/assets/compiled/js/*.js"
			}
		},

		clean: {
			revs : {
				  src    : "system/assets/compiled/js/*.js"
				, filter : function( src ){ return src.match(/[\/\\][a-f0-9]{8}\./) !== null; }
			}
		}
	} );



};