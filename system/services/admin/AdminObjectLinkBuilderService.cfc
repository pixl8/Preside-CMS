/**
 * Provides logic for building links to object pages
 * in the admin - e.g. listing, edit record, view record, etc.
 *
 * @autodoc        true
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @customizationService.inject datamanagerCustomizationService
	 *
	 */
	public any function init( required any customizationService ) {
		_setCustomizationService( arguments.customizationService );

		return this;
	}

// PUBLIC API
	/**
	 * Returns the link to the given object, operation and optional
	 * recordId (required for most operations)
	 *
	 * @autodoc
	 * @objectName Name of the object
	 * @operation  Operation to link to, e.g. listing, add, view, edit, editAction, etc.
	 * @recordId   ID of the record to link to. Required for record based operations
	 */
	public string function buildLink(
		  required string objectName
		, required string operation
		,          string recordId   = ""
	) {
		var customizationAction = "build#arguments.operation#Link";
		var args                = { objectName=arguments.objectName };

		if ( Len( Trim( arguments.recordId ) ) ) {
			args.recordId = arguments.recordId;
		}

		var result = _getCustomizationService().runCustomization(
			  objectName     = arguments.objectName
			, action         = customizationAction
			, args           = args
			, defaultHandler = "admin.objectLinks.#customizationAction#"
		);

		result = result ?: "";
		result = IsSimpleValue( result ) ? result : "";


		return result;
	}


// GETTERS AND SETTERS
	private any function _getCustomizationService() {
		return _customizationService;
	}
	private void function _setCustomizationService( required any customizationService ) {
		_customizationService = arguments.customizationService;
	}
}