module.exports = function( grunt ) {

	grunt.loadNpmTasks( 'grunt-contrib-clean' );
	grunt.loadNpmTasks( 'grunt-contrib-cssmin' );
	grunt.loadNpmTasks( 'grunt-contrib-less' );
	grunt.loadNpmTasks( 'grunt-contrib-rename' );
	grunt.loadNpmTasks( 'grunt-contrib-uglify' );
	grunt.loadNpmTasks( 'grunt-rev' );

	grunt.registerTask( 'default', [ 'uglify', 'less', 'cssmin', 'clean', 'rev', 'rename' ] );

	grunt.initConfig( {
		uglify: {
			options:{
				  sourceMap     : true
				, sourceMapName : function( dest ){
					var parts = dest.split( "/" );
					parts[ parts.length-1 ] = parts[ parts.length-1 ].replace( /\.js$/, ".map" );
					return parts.join( "/" );
				 }
			},
			core: {
				src: [
					  'system/assets/js/admin/core/jquery-ui-1.10.3.custom.js'
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
					, 'system/assets/js/admin/core/preside.asset.picker.js'
					, 'system/assets/js/admin/core/preside.uber.select.with.browser.js'
					, 'system/assets/js/admin/core/preside.imageDimension.picker.js'
					, 'system/assets/js/admin/core/formFields.js'
					, 'system/assets/js/admin/core/jquery.bootbox.js'
					, 'system/assets/js/admin/core/jquery.cookies.js'
					, 'system/assets/js/admin/core/jquery.dataTables.js'
					, 'system/assets/js/admin/core/jquery.dataTables.bootstrap.js'
					, 'system/assets/js/admin/core/jquery.dataTables.filterDelay.js'
					, 'system/assets/js/admin/core/jquery.dateformat.js'
					, 'system/assets/js/admin/core/jquery.dirtyforms.js'
					, 'system/assets/js/admin/core/jquery.easy-pie-chart.js'
					, 'system/assets/js/admin/core/jquery.gritter.js'
					, 'system/assets/js/admin/core/jquery.hotkeys.js'
					, 'system/assets/js/admin/core/jquery.lazy.js'
					, 'system/assets/js/admin/core/jquery.serialize-object.js'
					, 'system/assets/js/admin/core/jquery.slimscroll.js'
					, 'system/assets/js/admin/core/jquery.sparkline.js'
					, 'system/assets/js/admin/core/jquery.tabbable.js'
					, 'system/assets/js/admin/core/jquery.ui.touch-punch.js'
					, 'system/assets/js/admin/core/jquery.validate.js'
					, 'system/assets/js/admin/core/list.js'
					, 'system/assets/js/admin/core/preside.autofocus.form.js'
					, 'system/assets/js/admin/core/preside.bootbox.modal.js'
					, 'system/assets/js/admin/core/preside.clickable.tableRows.js'
					, 'system/assets/js/admin/core/preside.confirmation.prompts.js'
					, 'system/assets/js/admin/core/preside.hotkeys.js'
					, 'system/assets/js/admin/core/preside.loading.sheen.js'
					, 'system/assets/js/admin/core/preside.richeditor.js'
					, 'system/assets/js/admin/core/preside.url.builder.js'
					, 'system/assets/js/admin/core/preside.validation.defaults.js'
				],
				dest: 'system/assets/js/admin/core/_core.min.js'
			},
			specific:{
				files: [{
					expand  : true,
					cwd     : "system/assets/js/admin/specific/",
					src     : ["**/*.js", "!**/*.min.js" ],
					dest    : "system/assets/js/admin/specific/",
					ext     : ".min.js",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-2 ] + ".min.js";

						return dest + pathSplit.join( "/" );
					}
				}]
			},
			infrequentChangers: {
				files : [ {
					src  : ["system/assets/js/admin/coretop/*.js", "!system/assets/js/admin/coretop/*.min.js" ],
					dest : 'system/assets/js/admin/coretop/_coretop.min.js'
				}, {
					src:["system/assets/js/admin/coretop/ie/*.js", "!system/assets/js/admin/coretop/ie/*.min.js" ],
					dest: 'system/assets/js/admin/coretop/ie/_ie.min.js'
				},{
					src:["system/assets/js/admin/devtools/*.js", "!system/assets/js/admin/devtools/*.min.js" ],
					dest: 'system/assets/js/admin/devtools/_devtools.min.js'
				}, {
					src:[ "system/assets/js/admin/flot/jquery.flot.*.js" ],
					dest: 'system/assets/js/admin/flot/_flot.min.js'
				}, {
					src:["system/assets/js/admin/frontend/*.js", "!system/assets/js/admin/frontend/*.min.js" ],
					dest: 'system/assets/js/admin/frontend/_frontend.min.js'
				}, {
					src:["system/assets/js/admin/jquery/110/*.js", "!system/assets/js/admin/jquery/110/*.min.js" ],
					dest:"system/assets/js/admin/jquery/110/_jquery110.min.js"
				}, {
					src:["system/assets/js/admin/jquery/20/*.js", "!system/assets/js/admin/jquery/20/*.min.js" ],
					dest:"system/assets/js/admin/jquery/20/_jquery20.min.js"
				} ]
			}
		},

		less: {
			options: {
				paths : ["assets/css"],
			},
			all : {
				files: [{
					expand  : true,
					cwd     : 'system/assets/css/admin/',
					src     : '**/*.less',
					dest    : 'system/assets/css/admin/',
					ext     : ".less.css",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "$" + pathSplit[ pathSplit.length-1 ];

						return dest + pathSplit.join( "/" );
					}
				}]
			}
		},

		cssmin: {
			all: {
				expand : true,
				cwd    : 'system/assets/css/admin/',
				src    : [ '**/*.css', '!**/_*.min.css' ],
				ext    : '.min.css',
				dest   : 'system/assets/css/admin/',
				rename : function( dest, src ){
					var pathSplit = src.split( '/' );

					pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-2 ] + ".min.css";
					return dest + pathSplit.join( "/" );
				}
			}
		},

		rev: {
			options: {
				algorithm : 'md5',
				length    : 8
			},
			assets: {
				files : [
					  { src : "system/assets/js/admin/**/_*.min.js"  }
					, { src : "system/assets/css/admin/**/_*.min.css" }
				]
			}
		},

		rename: {
			assets: {
				expand : true,
				cwd    : 'system/assets/',
				src    : '**/*._*.min.{js,css}',
				dest   : 'system/assets/',
				rename : function( dest, src ){
					var pathSplit = src.split( '/' );

					pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-1 ].replace( /\._/, "." );

					return dest + pathSplit.join( "/" );
				}
			}
		},

		clean: {
			revs : {
				files : [{
					  src    : "system/assets/js/admin/**/_*.min.js"
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}, {
					  src    : "system/assets/css/admin/**/_*.min.css"
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}]
			}
		}
	} );
};