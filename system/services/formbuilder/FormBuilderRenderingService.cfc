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
	 * @viewletsService.inject viewletsService
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

	/**
	 * Lists the layouts possible for a given form field type (itemtype).
	 *
	 * @autodoc
	 * @itemType.hint Item type that the layout will be for, e.g. 'textinput'
	 *
	 */
	public array function listFormFieldLayouts( required string itemType ) {
		var discoveredLayouts   = {};
		var fieldLayouts        = [];
		var fieldLayoutFilter   = "^formbuilder\.layouts\.formfield\.";
		var fieldLayoutViewlets = _getViewletsService().listPossibleViewlets(
			filter = fieldLayoutFilter
		);

		for( var viewlet in fieldLayoutViewlets ){
			var layoutId = ReReplaceNoCase( viewlet, fieldLayoutFilter, "" );

			if ( ListLen( layoutId, "." ) > 1 ) {
				var itemTypeLayout = ListFirst( layoutId, "." );
				if ( itemTypeLayout != arguments.itemType ) {
					continue;
				}

				layoutId = ListRest( layoutId, "." );
			}

			discoveredLayouts[ layoutId ] = {
				  id      = layoutId
				, title   = $translateResource( uri="formbuilder.layouts.formfield:#layoutId#.title", defaultValue=layoutId )
				, viewlet = viewlet
			};
		}
		for( var layout in discoveredLayouts ) {
			fieldLayouts.append( discoveredLayouts[ layout ] );
		}

		fieldLayouts.sort( function( a, b ){
			return arguments.a.title > arguments.b.title ? 1 : -1;
		} );

		return fieldLayouts;
	}

	/**
	 * Returns the convention based viewlet name
	 * for the given item type and context
	 *
	 * @autodoc
	 * @itemtype.hint The item type who's viewlet you wish to get
	 * @context.hint  The context in which the item will be rendered. i.e. 'input', 'adminPlaceholder', 'response', etc.
	 */
	public string function getItemTypeViewlet( required string itemType, required string context ) {
		var itemTypeSpecific = "formbuilder.item-types.#arguments.itemType#.render#arguments.context#";

		if ( $getColdbox().viewletExists( itemTypeSpecific ) ) {
			return itemTypeSpecific;
		}

		return "formbuilder.defaultRenderers.#arguments.context#";
	}

	/**
	 * Returns the viewlet that should be used to render
	 * the given item type and form field layout combination.
	 *
	 * @autodoc
	 * @itemType.hint The Item Type who's viewlet you wish to get
	 * @layout.hint   The layout who's viewlet you wish to get
	 *
	 */
	public string function getFormFieldLayoutViewlet( required string itemType, required string layout ) {
		var layouts = listFormFieldLayouts( itemType=arguments.itemType );

		for( var layout in layouts ) {
			if ( layout.id == arguments.layout ) {
				return layout.viewlet;
			}
		}
		return "formbuilder.layouts.formfield.default";
	}

	/**
	 * Returns the viewlet that should be used to render
	 * the given form layout.
	 *
	 * @autodoc
	 * @layout.hint The layout who's viewlet you wish to get
	 *
	 */
	public string function getFormLayoutViewlet( required string layout ) {
		var layouts = listFormLayouts();

		for( var layout in layouts ) {
			if ( layout.id == arguments.layout ) {
				return layout.viewlet;
			}
		}
		return "formbuilder.layouts.form.default";
	}

	/**
	 * Returns an array of column names that the item type will need when rendering
	 * and excel export of responses.
	 *
	 * @autodoc
	 * @itemType.hint      The item type, e.g. 'select'
	 * @configuration.hint The stored configuration options for the item within the form
	 *
	 */
	public array function getItemTypeExportColumns( required string itemType, required struct configuration ) {
		var customHandler = "formbuilder.item-types.#arguments.itemType#.getExportColumns";
		var cbController  = $getColdbox();

		if ( cbController.handlerExists( customHandler ) ) {
			return cbController.runEvent(
				  event          = customHandler
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=arguments.configuration }
			);
		}

		return [ ( arguments.configuration.label ?: "" ) ];
	}


	/**
	 * Returns the convention based viewlet name
	 * for the given action and context
	 *
	 * @autodoc
	 * @action.hint  The action who's viewlet you wish to get
	 * @context.hint The context in which the action will be rendered. i.e. 'adminPlaceholder'
	 */
	public string function getActionViewlet( required string action, required string context ) {
		var actionSpecific = "formbuilder.actions.#arguments.action#.render#arguments.context#";

		if ( $getColdbox().viewletExists( actionSpecific ) ) {
			return actionSpecific;
		}

		return "formbuilder.defaultActionRenderers.#arguments.context#";
	}

 // GETTERS AND SETTERS
	private any function _getViewletsService() {
		return _viewletsService;
	}
	private void function _setViewletsService( required any viewletsService ) {
		_viewletsService = arguments.viewletsService;
	}

 }