module.exports = function( grunt ) {

	grunt.loadNpmTasks( 'grunt-contrib-clean' );
	grunt.loadNpmTasks( 'grunt-contrib-cssmin' );
	grunt.loadNpmTasks( 'grunt-contrib-less' );
	grunt.loadNpmTasks( 'grunt-contrib-rename' );
	grunt.loadNpmTasks( 'grunt-contrib-uglify' );
	grunt.loadNpmTasks( 'grunt-rev' );

	grunt.registerTask( 'default', [ 'uglify:core', 'uglify:specific', 'less', 'cssmin', 'clean', 'rev', 'rename' ] );
	grunt.registerTask( 'all'    , [ 'uglify', 'less', 'cssmin', 'clean', 'rev', 'rename' ] );

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
					  'system/assets/js/admin/presidecore/preside.uber.select.js'
					, 'system/assets/js/admin/presidecore/i18n.js'
					, 'system/assets/js/admin/presidecore/preside.richeditor.js'
					, 'system/assets/js/admin/presidecore/preside.asset.picker.js'
					, 'system/assets/js/admin/presidecore/preside.uber.select.with.browser.js'
					, 'system/assets/js/admin/presidecore/preside.imageDimension.picker.js'
					, 'system/assets/js/admin/presidecore/formFields.js'
					, 'system/assets/js/admin/presidecore/list.js'
					, 'system/assets/js/admin/presidecore/preside.autofocus.form.js'
					, 'system/assets/js/admin/presidecore/preside.bootbox.modal.js'
					, 'system/assets/js/admin/presidecore/preside.clickable.tableRows.js'
					, 'system/assets/js/admin/presidecore/preside.confirmation.prompts.js'
					, 'system/assets/js/admin/presidecore/preside.hotkeys.js'
					, 'system/assets/js/admin/presidecore/preside.loading.sheen.js'
					, 'system/assets/js/admin/presidecore/preside.url.builder.js'
					, 'system/assets/js/admin/presidecore/preside.validation.defaults.js'
				],
				dest: 'system/assets/js/admin/presidecore/_presidecore.min.js'
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
				},{
					  src  : [
					  	"system/assets/js/admin/lib/plugins/jquery.datatables.js", // must come first
					  	"system/assets/js/admin/lib/plugins/*.js"
					  ]
					, dest : "system/assets/js/admin/lib/plugins-1.0.0.min.js"
				},{
					  src  : ["system/assets/js/admin/lib/ace/ace.js", "system/assets/js/admin/lib/ace/ace-elements.js"]
					, dest : "system/assets/js/admin/lib/ace-1.0.0.min.js"
				},{
					  src  : "system/assets/js/admin/lib/bootstrap-3.0.0.js"
					, dest : "system/assets/js/admin/lib/bootstrap-3.0.0.min.js"
				},{
					  src  : "system/assets/js/admin/lib/jquery-1.10.2.js"
					, dest : "system/assets/js/admin/lib/jquery-1.10.2.min.js"
				},{
					  src  : "system/assets/js/admin/lib/jquery-2.0.3.js"
					, dest : "system/assets/js/admin/lib/jquery-2.0.3.min.js"
				},{
					  src  : "system/assets/js/admin/lib/jquery-ui-1.10.3.custom.js"
					, dest : "system/assets/js/admin/lib/jquery-ui-1.10.3.custom.min.js"
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