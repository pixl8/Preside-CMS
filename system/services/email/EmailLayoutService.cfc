/**
 * @singleton      true
 * @presideService true
 *
 */
component {

	/**
	 * @viewletsService.inject viewletsService
	 *
	 */
	public any function init( required any viewletsService ) {
		_setViewletsService( arguments.viewletsService );
		_loadLayoutsFromViewlets();

		return this;
	}

// PUBLIC API
	public array function listLayouts() {
		var layoutIds = _getLayouts();
		var layouts   = [];

		for( var layoutId in layoutIds ) {
			layouts.append( {
				  id          = layoutId
				, title       = $translateResource( uri="email.layout:#layoutId#.title"      , defaultValue=layoutId )
				, description = $translateResource( uri="email.layout:#layoutId#.description", defaultValue=""       )
			} );
		}

		layouts.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return layouts;
	}

// PRIVATE HELPERS
	private void function _loadLayoutsFromViewlets() {
		var viewletRegex     = "email\.layout\.(.*?)\.(html|text)";
		var matchingViewlets = _getViewletsService().listPossibleViewlets( filter="email\.layout\.(.*?)\.(html|text)" );
		var layouts          = {};

		for( var viewlet in matchingViewlets ){
			layouts[ viewlet.reReplace( viewletRegex, "\1" ) ] = true;
		}

		_setLayouts( layouts.keyArray() );
	}

// GETTERS AND SETTERS
	private array function _getLayouts() {
		return _layouts;
	}
	private void function _setLayouts( required array layouts ) {
		_layouts = arguments.layouts;
	}

	private any function _getViewletsService() {
		return _viewletsService;
	}
	private void function _setViewletsService( required any viewletsService ) {
		_viewletsService = arguments.viewletsService;
	}
}