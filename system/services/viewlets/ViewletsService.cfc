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

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of potential viewlets in the system.
	 * These viewlets will have been calculated by scanning
	 * the handlers and views of the entire application.
	 *
	 * @autodoc
	 */
	public array function listPossibleViewlets() {
		var viewlets = Duplicate( _getCoreViewlets() );
		viewlets.append( _getSiteTemplateViewlets(), true );

		return viewlets;
	}

// PRIVATE HELPERS
	private void function _scanDirectories( required array directories ) {
		var viewlets = {
			  core          = {}
			, sitetemplates = {}
		};

		for( var directory in directories ) {
			var viewsDirectory = directory & "/views";
			var siteTemplate   = _getSiteTemplateFromDirectory( directory );

			if ( DirectoryExists( viewsDirectory ) ) {
				var expandedDirPath = ExpandPath( viewsDirectory );
				var viewFiles       = DirectoryList( viewsDirectory, true, "path", "*.cfm" );

				for( var viewFile in viewFiles ) {
					var viewletName = viewFile.replace( expandedDirPath, "" );

					viewletName = viewletName.reReplaceNoCase( "^[\/\\]", "" );
					viewletName = viewletName.reReplaceNoCase( "\.cfm$" , "" );
					viewletName = viewletName.reReplaceNoCase( "[\/\\]" , ".", "all" );

					if ( siteTemplate == "" ) {
						viewlets.core[ viewletName ] = true;
					} else {
						viewlets.sitetemplates[ siteTemplate ] = viewlets.sitetemplates[ siteTemplate ] ?: {};
						viewlets.sitetemplates[ siteTemplate ][ viewletName ] = true;
					}

					if ( viewletName.reFindNoCase( "\.index$" ) ) {
						viewletName = viewletName.reReplaceNoCase( "\.index$", "" )

						if ( siteTemplate == "" ) {
							viewlets.core[ viewletName ] = true;
						} else {
							viewlets.sitetemplates[ siteTemplate ][ viewletName ] = true;
						}
					}
				}
			}
		}

		for( var siteTemplate in viewlets.sitetemplates ) {
			viewlets.sitetemplates[ siteTemplate ] = viewlets.sitetemplates[ siteTemplate ].keyArray();

			for( var viewlet in viewlets.sitetemplates[ siteTemplate ] ) {
				if ( viewlets.core.keyExists( viewlet ) ) {
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

// GETTERS AND SETTERS
	private array function _getCoreViewlets() {
		return _coreViewlets;
	}
	private void function _setCoreViewlets( required array coreViewlets ) {
		_coreViewlets = arguments.coreViewlets;
	}

	private array function _getSiteTemplateViewlets() {
		return _siteTemplateViewlets[ _getSiteService().getActiveSiteTemplate() ] ?: [];
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
}