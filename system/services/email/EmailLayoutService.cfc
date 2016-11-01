/**
 * @singleton      true
 * @presideService true
 * @autodoc        true
 *
 */
component {

	/**
	 * @viewletsService.inject viewletsService
	 * @formsService.inject    formsService
	 *
	 */
	public any function init( required any viewletsService, required any formsService ) {
		_setViewletsService( arguments.viewletsService );
		_setFormsService( arguments.formsService );

		_loadLayoutsFromViewlets();

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of structs describing the application's
	 * available email layouts. Each struct contains `id`, `title`
	 * and `description` keys. Layouts are ordered by title (ascending).
	 *
	 * @autodoc
	 *
	 */
	public array function listLayouts() {
		var layoutIds    = _getLayouts();
		var formsService = _getFormsService();
		var layouts      = [];

		for( var layoutId in layoutIds ) {
			layouts.append( {
				  id           = layoutId
				, title        = $translateResource( uri="email.layout.#layoutId#:title"      , defaultValue=layoutId )
				, description  = $translateResource( uri="email.layout.#layoutId#:description", defaultValue=""       )
				, configurable = formsService.formExists( "email.layout.#layoutId#" )
			} );
		}

		layouts.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return layouts;
	}

	/**
	 * Returns the rendering of an email layout with the given
	 * arguments.
	 *
	 * @autodoc true
	 *
	 */
	public string function renderLayout(
		  required string layout
		, required string type
		, required string subject
		, required string body
		,          string unsubscribeLink = ""
		,          string viewOnlineLink  = ""
	) {
		var renderType   = arguments.type == "text" ? "text" : "html";
		var viewletEvent = "email.layout.#arguments.layout#.#renderType#";
		var viewletArgs  = {};

		for( var key in arguments ) {
			if ( ![ "layout", "type" ].findNoCase( key ) ) {
				viewletArgs[ key ] = arguments[ key ];
			}
		}

		return $renderViewlet( event=viewletEvent, args=viewletArgs );
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

	private any function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
		_formsService = arguments.formsService;
	}
}