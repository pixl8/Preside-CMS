component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @configuredToolbars.inject coldbox:setting:ckeditor.toolbars
	 */
	public any function init( required struct configuredToolbars ) output=false {
		_setConfiguredToolbars( arguments.configuredToolbars );

		return this;
	}

// PUBLIC API METHODS
	public string function getToolbarDefinition( required string toolbarDefinition ) output=false {
		var toolbars = _getConfiguredToolbars();

		return toolbars[ arguments.toolbarDefinition ] ?: arguments.toolbarDefinition;

		// return _stripPermissionRestrictedButtons( toolbars[ arguments.toolbarDefinition ] ?: arguments.toolbarDefinition );
	}


// PRIVATE HELPERS
	private string function _stripPermissionRestrictedButtons( required string toolbar ) output=false {
		var bars               = ListToArray( arguments.toolbar, "|" );
		var securityService    = _getSecurityService();
		var ignoreButtons      = [ "/", "-" ];
		var transformedToolbar = [];
		var finalToolbar       = "";

		for( var bar in bars ){
			var buttons = ListToArray( bar, "," );
			var transformedButtons = [];

			for( var btn in buttons ) {
				if ( ignoreButtons.find( btn ) || securityService.hasPermission( "ckeditor.button.#btn#" ) ) {
					transformedButtons.append( btn );
				}
			}
			transformedButtons = _trimButtonMarkers( transformedButtons, "-" );
			if ( transformedButtons.len() ) {
				transformedToolbar.append( transformedButtons );
			}
		}
		transformedToolbar = _trimBarMarkers( transformedToolbar, "/" );

		for( var bar in transformedToolbar ){
			finalToolbar = ListAppend( finalToolbar, ArrayToList( bar ), "|" );
		}

		return finalToolbar;
	}

	private array function _trimButtonMarkers( required array buttons ) {
		while( buttons.len() && buttons[1] == "-" ){
			buttons.deleteAt(1);
		}
		while( buttons.len() && buttons[ buttons.len() ] == "-" ){
			buttons.deleteAt( buttons.len() );
		}

		return buttons;
	}

	private array function _trimBarMarkers( required array bars ) {
		while( bars.len() && bars[1].len() == 1 && bars[1][1] == "/" ){
			bars.deleteAt(1);
		}
		while( bars.len() && bars[ bars.len() ].len() == 1 && bars[bars.len()][1] == "/" ){
			bars.deleteAt( bars.len() );
		}

		return bars;
	}

// GETTERS AND SETTERS
	private struct function _getConfiguredToolbars() output=false {
		return _configuredToolbars;
	}
	private void function _setConfiguredToolbars( required struct configuredToolbars ) output=false {
		_configuredToolbars = arguments.configuredToolbars;
	}
}