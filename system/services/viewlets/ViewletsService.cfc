/**
 * Provides logic for querying viewlets that exist
 * in the system.
 *
 * @autodoc
 * @singleton
 */
component {

// constructor
	/**
	 * @sourceDirectories.inject presidecms:directories
	 * @siteService.inject       siteService
	 */
	public any function init( required array sourceDirectories, required any siteService ) {
		_setSiteService( arguments.siteService );
		_scanDirectories( arguments.sourceDirectories );
		_setCachedResults( {} );

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of potential viewlets in the system.
	 * These viewlets will have been calculated by scanning
	 * the handlers and views of the entire application.
	 *
	 * @autodoc
	 * @filter.hint A regular expression with which to filter the viewlets to return
	 */
	public array function listPossibleViewlets( string filter="" ) {
		var cachedResults = _getCachedResults();
		var cacheKey      = _getSiteService().getActiveSiteTemplate( emptyIfDefault=true ) & arguments.filter;

		if ( !StructKeyExists( cachedResults, cacheKey ) ) {
			var viewlets = Duplicate( _getCoreViewlets() );
			viewlets.append( _getSiteTemplateViewlets(), true );

			if ( Len( Trim( arguments.filter ) ) ) {
				for( var i=viewlets.len(); i>0; i-- ){
					var viewlet = viewlets[ i ];

					if ( !ReFindNoCase( arguments.filter, viewlet ) ) {
						viewlets.deleteAt( i );
					}
				}
			}

			cachedResults[ cacheKey ] = viewlets;
		}

		return cachedResults[ cacheKey ] ?: [];
	}

// PRIVATE HELPERS
	private void function _scanDirectories( required array directories ) {
		var viewlets = {
			  core          = {}
			, sitetemplates = {}
		};
		var registerViewlet = function( viewletName, siteTemplate ){
			if ( arguments.siteTemplate == "" ) {
				viewlets.core[ arguments.viewletName ] = true;
			} else {
				viewlets.sitetemplates[ arguments.siteTemplate ] = viewlets.sitetemplates[ arguments.siteTemplate ] ?: {};
				viewlets.sitetemplates[ arguments.siteTemplate ][ arguments.viewletName ] = true;
			}

			if ( arguments.viewletName.reFindNoCase( "\.index$" ) ) {
				arguments.viewletName = arguments.viewletName.reReplaceNoCase( "\.index$", "" );

				if ( arguments.siteTemplate == "" ) {
					viewlets.core[ arguments.viewletName ] = true;
				} else {
					viewlets.sitetemplates[ arguments.siteTemplate ][ arguments.viewletName ] = true;
				}
			}
		}

		for( var directory in directories ) {
			var viewsDirectory    = directory & "/views";
			var handlersDirectory = directory & "/handlers";
			var siteTemplate   = _getSiteTemplateFromDirectory( directory );


			if ( DirectoryExists( viewsDirectory ) ) {
				var expandedDirPath = ExpandPath( viewsDirectory );
				var viewFiles       = DirectoryList( viewsDirectory, true, "path", "*.cfm" );

				for( var viewFile in viewFiles ) {
					var viewletName = viewFile.replace( expandedDirPath, "" );

					viewletName = viewletName.reReplaceNoCase( "^[\/\\]", "" );
					viewletName = viewletName.reReplaceNoCase( "\.cfm$" , "" );
					viewletName = viewletName.reReplaceNoCase( "[\/\\]" , ".", "all" );

					registerViewlet( viewletName, siteTemplate );
				}
			}

			if ( DirectoryExists( handlersDirectory ) ) {
				var expandedDirPath = ExpandPath( handlersDirectory );
				var handlerFiles    = DirectoryList( handlersDirectory, true, "path", "*.cfc" );

				for( var handlerFile in handlerFiles ) {
					var viewletNameBase = handlerFile.replace( expandedDirPath, "" ).reReplaceNoCase( "\.cfc$" , "" );
					var handlerCfcPath  = handlersDirectory & viewletNameBase

					handlerCfcPath  = handlerCfcPath.reReplaceNoCase( "^[\/\\]", "" );
					handlerCfcPath  = handlerCfcPath.reReplaceNoCase( "[\/\\]" , ".", "all" );
					viewletNameBase = viewletNameBase.reReplaceNoCase( "^[\/\\]", "" );
					viewletNameBase = viewletNameBase.reReplaceNoCase( "[\/\\]" , ".", "all" );

					var actions = _readActionsFromHandler( handlerCfcPath );
					for( var action in actions ) {
						var viewletName = viewletNameBase & "." & action;
						registerViewlet( viewletName, siteTemplate )
					}
				}

			}
		}

		for( var siteTemplate in viewlets.sitetemplates ) {
			viewlets.sitetemplates[ siteTemplate ] = viewlets.sitetemplates[ siteTemplate ].keyArray();

			for( var viewlet in viewlets.sitetemplates[ siteTemplate ] ) {
				if ( StructKeyExists( viewlets.core, viewlet ) ) {
					viewlets.sitetemplates[ siteTemplate ].delete( viewlet );
				}
			}
		}

		_setCoreViewlets( viewlets.core.keyArray() );
		_setSiteTemplateViewlets( viewlets.sitetemplates );
	}

	private string function _getSiteTemplateFromDirectory( required string directory ) {
		var regex = "^.*[\\/]site-templates[\\/]([^\\/]+)$";

		if ( !ReFindNoCase( regex, arguments.directory ) ) {
			return "";
		}

		return ReReplaceNoCase( arguments.directory, regex, "\1" );
	}

	private array function _readActionsFromHandler( required string handlerCfcPath ) {
		var actions                    = {};
		var lifeCycleRegex             = "^(pre|post|around)";
		var readNonLifeCycleFunctions = function( meta ){
			var functions = arguments.meta.functions ?: [];

			if ( StructKeyExists( arguments.meta, "extends" ) ) {
				readNonLifeCycleFunctions( arguments.meta.extends );
			}

			for( var func in functions ) {
				var functionName = func.name ?: "";
				if ( Len( Trim( functionName ) ) && !ReFindNoCase( lifeCycleRegex, functionName ) ) {
					actions[ functionName ] = true;
				}
			}
		};


		readNonLifeCycleFunctions( getComponentMetadata( handlerCfcPath ) );

		return actions.keyArray();
	}

// GETTERS AND SETTERS
	private array function _getCoreViewlets() {
		return _coreViewlets;
	}
	private void function _setCoreViewlets( required array coreViewlets ) {
		_coreViewlets = arguments.coreViewlets;
	}

	private array function _getSiteTemplateViewlets() {
		return _siteTemplateViewlets[ _getSiteService().getActiveSiteTemplate( emptyIfDefault=true ) ] ?: [];
	}
	private void function _setSiteTemplateViewlets( required struct siteTemplateViewlets ) {
		_siteTemplateViewlets = arguments.siteTemplateViewlets;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}

	private struct function _getCachedResults() {
		return _cachedResults;
	}
	private void function _setCachedResults( required struct cachedResults ) {
		_cachedResults = arguments.cachedResults;
	}
}