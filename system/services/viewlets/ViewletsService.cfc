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

		for( var directory in arguments.directories ) {
			var viewsDirectory    = directory & "/views";
			var handlersDirectory = directory & "/handlers";
			var siteTemplate   = _getSiteTemplateFromDirectory( directory );


			if ( DirectoryExists( viewsDirectory ) ) {
				var expandedDirPath = ExpandPath( viewsDirectory );
				var viewFiles       = DirectoryList( viewsDirectory, true, "path", "*.cfm" );

				for( var viewFile in viewFiles ) {
					var viewletName = Replace( viewFile, expandedDirPath, "" );

					viewletName = ReReplaceNoCase( viewletName, "^[\/\\]", "" );
					viewletName = ReReplaceNoCase( viewletName, "\.cfm$" , "" );
					viewletName = ReReplaceNoCase( viewletName, "[\/\\]" , ".", "all" );

					_registerViewlet( viewletName, siteTemplate, viewlets );
				}
			}

			if ( DirectoryExists( handlersDirectory ) ) {
				var expandedDirPath = ExpandPath( handlersDirectory );
				var handlerFiles    = DirectoryList( handlersDirectory, true, "path", "*.cfc" );

				for( var handlerFile in handlerFiles ) {
					var viewletNameBase = ReReplaceNoCase( Replace( handlerFile, expandedDirPath, "" ), "\.cfc$" , "" );
					var handlerCfcPath  = handlersDirectory & viewletNameBase

					handlerCfcPath  = ReReplaceNoCase( handlerCfcPath, "^[\/\\]", "" );
					handlerCfcPath  = ReReplaceNoCase( handlerCfcPath, "[\/\\]" , ".", "all" );
					viewletNameBase = ReReplaceNoCase( viewletNameBase, "^[\/\\]", "" );
					viewletNameBase = ReReplaceNoCase( viewletNameBase, "[\/\\]" , ".", "all" );

					var actions = _readActionsFromHandler( handlerCfcPath );
					for( var action in actions ) {
						var viewletName = viewletNameBase & "." & action;
						_registerViewlet( viewletName, siteTemplate, viewlets )
					}
				}

			}
		}

		for( var siteTemplate in viewlets.sitetemplates ) {
			viewlets.sitetemplates[ siteTemplate ] = StructKeyArray( viewlets.sitetemplates[ siteTemplate ] )

			for( var viewlet in viewlets.sitetemplates[ siteTemplate ] ) {
				if ( StructKeyExists( viewlets.core, viewlet ) ) {
					ArrayDelete( viewlets.sitetemplates[ siteTemplate ], viewlet );
				}
			}
		}

		_setCoreViewlets( StructKeyArray( viewlets.core ) );
		_setSiteTemplateViewlets( viewlets.sitetemplates );
	}

	private function _registerViewlet( viewletName, siteTemplate, viewlets ){
			if ( arguments.siteTemplate == "" ) {
				arguments.viewlets.core[ arguments.viewletName ] = true;
			} else {
				arguments.viewlets.sitetemplates[ arguments.siteTemplate ] = arguments.viewlets.sitetemplates[ arguments.siteTemplate ] ?: {};
				arguments.viewlets.sitetemplates[ arguments.siteTemplate ][ arguments.viewletName ] = true;
			}

			if ( arguments.viewletName.reFindNoCase( "\.index$" ) ) {
				arguments.viewletName = arguments.viewletName.reReplaceNoCase( "\.index$", "" );

				if ( arguments.siteTemplate == "" ) {
					arguments.viewlets.core[ arguments.viewletName ] = true;
				} else {
					arguments.viewlets.sitetemplates[ arguments.siteTemplate ][ arguments.viewletName ] = true;
				}
			}
		}

	private string function _getSiteTemplateFromDirectory( required string directory ) {
		var regex = "^.*[\\/]site-templates[\\/]([^\\/]+)$";

		if ( !ReFindNoCase( regex, arguments.directory ) ) {
			return "";
		}

		return ReReplaceNoCase( arguments.directory, regex, "\1" );
	}

	private array function _readActionsFromHandler( required string handlerCfcPath ) {
		var actions         = [];
		var lifeCycleRegex  = "^(pre|post|around)";
		var functions       = preside.system.services.helpers.ComponentMetaDataReader::getComponentFunctions( arguments.handlerCfcPath );

		for( var functionName in functions ) {
			if ( !ReFindNoCase( lifeCycleRegex, functionName ) ) {
				ArrayAppend( actions, functionName );
			}
		}

		return actions;
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