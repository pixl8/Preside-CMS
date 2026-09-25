module.exports = function( grunt ) {

	grunt.loadNpmTasks( 'grunt-contrib-clean' );
	grunt.loadNpmTasks( 'grunt-contrib-cssmin' );
	grunt.loadNpmTasks( 'grunt-contrib-less' );
	grunt.loadNpmTasks( 'grunt-contrib-rename' );
	grunt.loadNpmTasks( 'grunt-contrib-uglify' );
	grunt.loadNpmTasks( 'grunt-contrib-watch' );
	grunt.loadNpmTasks( 'grunt-rev' );

	grunt.registerTask( 'default', [ 'uglify:core', 'uglify:legacyDatatablesCore', 'uglify:modernDatatablesCore', 'uglify:specific', 'uglify:frontend', 'less', 'cssmin', 'clean:frequentChangers', 'rev:frequentChangers', 'rename' ] );
	grunt.registerTask( 'all'    , [ 'uglify', 'less', 'cssmin', 'clean:all', 'rev:all', 'rename' ] );

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
					  'js/admin/presidecore/preside.uber.select.js'
					, 'js/admin/presidecore/i18n.js'
					, 'js/admin/presidecore/preside.richeditor.js'
					, 'js/admin/presidecore/preside.bootbox.modal.js'
					, 'js/admin/presidecore/preside.asset.picker.js'
					, 'js/admin/presidecore/preside.object.picker.js'
					, 'js/admin/presidecore/preside.object.configurator.js'
					, 'js/admin/presidecore/preside.imageDimension.picker.js'
					, 'js/admin/presidecore/formFields.js'
					, 'js/admin/presidecore/list.js'
					, 'js/admin/presidecore/preside.autofocus.form.js'
					, 'js/admin/presidecore/preside.clickable.tableRows.js'
					, 'js/admin/presidecore/preside.confirmation.prompts.js'
					, 'js/admin/presidecore/preside.hotkeys.js'
					, 'js/admin/presidecore/preside.url.builder.js'
					, 'js/admin/presidecore/preside.validation.defaults.js'
					, 'js/admin/presidecore/*.js'
					, '!js/admin/presidecore/datatables.resize.fix.js'
					, '!js/admin/presidecore/preside.static.datatable.js'
					, '!js/admin/presidecore/_*.min.js'
				],
				dest: 'js/admin/presidecore/_presidecore.min.js'
			},
			legacyDatatablesCore: {
				src: [
					  'js/admin/presidecore/datatables.resize.fix.js'
					, 'js/admin/presidecore/preside.static.datatable.js'
				],
				dest: 'js/admin/datatablesCore/_datatablesCore.min.js'
			},
			modernDatatablesCore: {
				src: [
					  'js/admin/presidecoreModern/datatables.resize.fix.js'
					, 'js/admin/presidecoreModern/preside.static.datatable.js'
				],
				dest: 'js/admin/datatablesCoreModern/_datatablesCoreModern.min.js'
			},
			specific:{
				files: [{
					expand  : true,
					cwd     : "js/admin/specific/",
					src     : ["**/*.js", "!**/*.min.js" ],
					dest    : "js/admin/specific/",
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
					src  : ["js/admin/coretop/*.js", "!js/admin/coretop/*.min.js" ],
					dest : 'js/admin/coretop/_coretop.min.js'
				}, {
					src:["js/admin/devtools/*.js", "!js/admin/devtools/*.min.js" ],
					dest: 'js/admin/devtools/_devtools.min.js'
				}, {
					src:[ "js/admin/flot/jquery.flot.*.js" ],
					dest: 'js/admin/flot/_flot.min.js'
				}, {
					src:["js/admin/frontend/*.js", "!js/admin/frontend/*.min.js" ],
					dest: 'js/admin/frontend/_frontend.min.js'
				},{
					  src  : [
						"js/admin/lib/plugins/jquery.moment.js",
						"js/admin/lib/plugins/*.js",
						"!js/admin/lib/plugins/jquery.dataTables*.js"
					  ]
					, dest : "js/admin/lib/plugins-1.8.004.min.js"
				},{
					  src  : [
						"js/admin/lib/plugins/jquery.dataTables.js",
						"js/admin/lib/plugins/jquery.dataTables.bootstrap.js",
						"js/admin/lib/plugins/jquery.dataTables.filterDelay.js"
					  ]
					, dest : "js/admin/lib/datatables-1.9.4.min.js"
				},{
					  src  : [
						"js/admin/lib/pluginsModern/jquery.dataTables.js",
						"js/admin/lib/pluginsModern/jquery.dataTables.dateTime.js",
						"js/admin/lib/pluginsModern/jquery.dataTables.colReorder.js",
						"js/admin/lib/pluginsModern/jquery.dataTables.columnControl.js",
						"js/admin/lib/pluginsModern/jquery.dataTables.bootstrap.js",
						"js/admin/lib/pluginsModern/jquery.dataTables.columnControlBootstrap.js",
						"js/admin/lib/pluginsModern/jquery.dataTables.filterDelay.js",
						"js/admin/lib/pluginsModern/jquery.dataTables.preside.adapter.js"
					  ]
					, dest : "js/admin/lib/datatables-3.0.4.min.js"
				},{
					  src  : ["js/admin/frontendModern/*.js", "!js/admin/frontendModern/*.min.js" ]
					, dest : "js/admin/frontendModern/_frontendModern.min.js"
				},{
					  src  : ["js/admin/lib/ace/ace.js", "js/admin/lib/ace/ace-elements.js"]
					, dest : "js/admin/lib/ace-1.0.0.min.js"
				},{
					  src  : "js/admin/lib/bootstrap-3.0.0.003.js"
					, dest : "js/admin/lib/bootstrap-3.0.0.003.min.js"
				},{
					  src  : "js/admin/lib/jquery-2.2.5-sec.js"
					, dest : "js/admin/lib/jquery-2.2.5-sec.min.js"
				},{
					  src  : "js/admin/lib/jquery-ui-1.11.4.js"
					, dest : "js/admin/lib/jquery-ui-1.11.4.min.js"
				} ]
			},
			frontend:{
				files: [{
					expand  : true,
					cwd     : "js/frontend/",
					src     : ["**/*.js", "!**/*.min.js" ],
					dest    : "js/frontend/",
					ext     : ".min.js",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-2 ] + ".min.js";

						return dest + pathSplit.join( "/" );
					}
				}]
			},
		},

		less: {
			options: {
				paths : [ "css/admin/lessglobals", "css/admin/bootstrap", "css/admin/ace" ],
				javascriptEnabled : true
			},
			all : {
				files: [{
					expand  : true,
					cwd     : 'css/admin/',
					src     : ['**/*.less', '!**/lessglobals/*', '!**/ace/**', '!**/bootstrap/**', '!**/core/**' ],
					dest    : 'css/admin/',
					ext     : ".less.css",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "$" + pathSplit[ pathSplit.length-1 ];

						return dest + pathSplit.join( "/" );
					}
				},
				{
					expand  : true,
					cwd     : 'css/frontend/',
					src     : '**/*.less',
					dest    : 'css/frontend/',
					ext     : ".less.css",
					rename  : function( dest, src ){
						var pathSplit = src.split( '/' );

						pathSplit[ pathSplit.length-1 ] = "$" + pathSplit[ pathSplit.length-1 ];

						return dest + pathSplit.join( "/" );
					}
				}]
			},
			ace:{
				src  : 'css/admin/ace/ace.less',
				dest : 'css/admin/ace/ace-for-preside.less'
			},
			core: {
				src  : 'css/admin/core/core.less',
				dest : 'css/admin/core/core.less.css'
			}
		},

		cssmin: {
			all: {
				expand : true,
				cwd    : 'css/',
				src    : [ '**/*.css', '!**/_*.min.css' ],
				ext    : '.min.css',
				dest   : 'css/',
				rename : function( dest, src ){
					var pathSplit = src.split( '/' );

					pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-2 ] + ".min.css";
					return dest + pathSplit.join( "/" );
				}
			}
		},

		clean: {
			frequentChangers : {
				files : [{
					  src    : [ "js/admin/specific/**/_*.min.js", "js/admin/presidecore/_*.min.js", "js/admin/datatablesCore/_*.min.js", "js/admin/datatablesCoreModern/_*.min.js", "js/frontend/**/_*.min.js" ]
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}, {
					  src    : [ "css/admin/**/_*.min.css", "css/frontend/**/_*.min.css" ]
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}]
			},
			all : {
				files : [{
					  src    : "js/**/_*.min.js"
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}, {
					  src    : ["css/admin/**/_*.min.css","css/frontend/**/_*.min.css"]
					, filter : function( src ){ return src.match(/[\/\\]_[a-f0-9]{8}\./) !== null; }
				}]
			}
		},

		rev: {
			options: {
				algorithm : 'md5',
				length    : 8
			},
			frequentChangers: {
				files : [
					  { src : [ "js/admin/specific/**/_*.min.js", "js/admin/presidecore/_*.min.js", "js/admin/datatablesCore/_*.min.js", "js/admin/datatablesCoreModern/_*.min.js", "js/frontend/**/_*.min.js" ]  }
					, { src : "css/**/**/_*.min.css" }
				]
			},
			all: {
				files : [
					  { src : "js/**/_*.min.js"  }
					, { src : "css/**/**/_*.min.css" }
				]
			}
		},

		rename: {
			assets: {
				expand : true,
				cwd    : '',
				src    : '**/*._*.min.{js,css}',
				dest   : '',
				rename : function( dest, src ){
					var pathSplit = src.split( '/' );

					pathSplit[ pathSplit.length-1 ] = "_" + pathSplit[ pathSplit.length-1 ].replace( /\._/, "." );

					return dest + pathSplit.join( "/" );
				}
			}
		},

		watch: {
			frequentChangers: {
				files : [ "css/**/**/*.less", "css/**/**/*.css", "js/admin/presidecore/*.js", "js/admin/presidecoreModern/*.js", "js/admin/specific/**/*.js", "js/frontend/**/*.js", "!css/**/**/*.min.css", "!js/**/*.min.js" ],
				tasks : [ "default" ]
			}
		}
	} );
};