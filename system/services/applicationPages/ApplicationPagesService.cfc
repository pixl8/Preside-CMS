/**
 * Service for interacting with application pages. See :doc:`/devguides/applicationpages`.
 *
 */
component output=false autodoc=true {

// CONSTRUCTOR
	public any function init( required struct configuredPages ) output=false {
		_setConfiguredPages( arguments.configuredPages );
		_processConfiguredPages();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of ids of all the registered application pages
	 */
	public array function listPages() output=false autodoc=true {
		return _getConfiguredPages().keyArray();
	}

	/**
	 * Returns configured details of the page referred to in the passed 'id' argument
	 *
	 * @id.hint ID of the page who's details you wish to retrieve
	 *
	 */
	public struct function getPage( required string id ) output=false autodoc=true {
		var pages = _getConfiguredPages();

		return pages[ arguments.id ] ?: throw(
			  type    = "ApplicationPagesService.page.notFound"
			, message = "The application page, [#arguments.id#], is not registered with the system."
		);
	}

	/**
	 * Returns whether or not the passed in page is registered with the system
	 *
	 * @id.hint ID of the page that we wish to check
	 */
	public boolean function pageExists( required string id ) output=false autodoc=true {
		return _getConfiguredPages().keyExists( arguments.id );
	}


// PRIVATE HELPERS
	private void function _processConfiguredPages() output=false {
		var configuredPages = _getConfiguredPages();
		var processed       = {};
		var processPage     = function( pageName, page ){
			processed[ pageName ] = Duplicate( page );
			processed[ pageName ].delete( "children" );

			if ( page.keyExists( "children" ) ) {
				for( var child in page.children ) {
					processPage( pageName & "." & child, page.children[child] );
				}
			}
		};

		for( var page in configuredPages ){
			processPage( page, configuredPages[ page ] );
		}

		_setConfiguredPages( processed );
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredPages() output=false {
		return _configuredPages;
	}
	private void function _setConfiguredPages( required struct configuredPages ) output=false {
		_configuredPages = arguments.configuredPages;
	}

}