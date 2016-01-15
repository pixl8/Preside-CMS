/**
 * Provides logic for rendering form builder forms
 * and controls + helpers around choosing render
 * layouts, etc.
 *
 * @autodoc
 * @singleton
 * @presideservice
 */
 component {

// CONSTRUCTOR
 	/**
 	 * viewletsService.inject viewletsService
 	 *
 	 */
 	public any function init( required any viewletsService ) {
 		_setViewletsService( arguments.viewletsService );
 	}

 // PUBLIC API
 	public array function listFormLayouts() {
 		var formLayouts        = [];
 		var formLayoutFilter   = "^formbuilder\.layouts\.form\.";
 		var formLayoutViewlets = _getViewletsService().listPossibleViewlets(
 			filter = formLayoutFilter
 		);

 		for( var viewlet in formLayoutViewlets ){
 			var layoutId = ReReplaceNoCase( viewlet, formLayoutFilter, "" );

 			formLayouts.append( {
 				  id      = layoutId
 				, title   = $translateResource( uri="formbuilder.layouts.form:#layoutId#.title", defaultValue=layoutId )
 				, viewlet = viewlet
 			} );
 		}

 		formLayouts.sort( function( a, b ){
 			return arguments.a.title > arguments.b.title ? 1 : -1;
 		} );

 		return formLayouts;
 	}

 // GETTERS AND SETTERS
 	private any function _getViewletsService() {
 		return _viewletsService;
 	}
 	private void function _setViewletsService( required any viewletsService ) {
 		_viewletsService = arguments.viewletsService;
 	}

 }