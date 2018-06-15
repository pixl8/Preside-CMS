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
	 * @dataManagerService.inject   datamanagerService
	 *
	 */
	public any function init(
		  required any customizationService
		, required any datamanagerService
	) {
		_setCustomizationService( arguments.customizationService );
		_setDataManagerService( arguments.datamanagerService );

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
	 * @args       Any additional args to send to the link builder
	 */
	public string function buildLink(
		  required string objectName
		,          string operation  = ""
		,          string recordId   = ""
		,          struct args       = {}
	) {
		if ( $getPresideObjectService().isPageType( arguments.objectName ) ) {
			arguments.objectName = "page";
		}

		if ( !Len( Trim( arguments.operation ) ) ) {
			if ( !Len( Trim( arguments.recordId ) ) ) {
				arguments.operation = "listing";
			} else {
				arguments.operation = getDefaultRecordOperation( arguments.objectName );
			}
		}

		var customizationAction = "build#arguments.operation#Link";
		var customizationArgs   = { objectName=arguments.objectName };

		customizationArgs.append( arguments.args );
		if ( Len( Trim( arguments.recordId ) ) ) {
			customizationArgs.recordId = arguments.recordId;
		}

		var result = "";
		if ( _getCustomizationService().objectHasCustomization( arguments.objectName, customizationAction ) ) {
			result = _getCustomizationService().runCustomization(
				  objectName = arguments.objectName
				, action     = customizationAction
				, args       = customizationArgs
			);
		} else if ( _getDataManagerService().isObjectAvailableInDataManager( arguments.objectName ) ) {
			result = $getColdbox().runEvent(
				  event          = "admin.objectLinks.#customizationAction#"
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=customizationArgs }
			);
		}

		result = result ?: "";
		result = IsSimpleValue( result ) ? result : "";

		return result;
	}

	/**
	 * Returns the default operation for a record.
	 *
	 * @autodoc true
	 * @objectname The name of the object whose default operation you wish to get
	 *
	 */
	public string function getDefaultRecordOperation( required string objectName ) {
		var definedOperation = $getPresideObjectService().getObjectAttribute(
			  objectName = arguments.objectName
			, attributeName = "datamanagerDefaultRecordOperation"
		);

		if ( Len( Trim( definedOperation ) ) ) {
			return Trim( definedOperation );
		}

		var canRead = _getDataManagerService().isOperationAllowed(
			  objectName = arguments.objectName
			, operation  = "read"
		);

		if ( canRead ) {
			return "viewRecord";
		}

		var canEdit = _getDataManagerService().isOperationAllowed(
			  objectName = arguments.objectName
			, operation  = "edit"
		);

		if ( canEdit ) {
			return "editRecord";
		}

		return "listing";
	}

// GETTERS AND SETTERS
	private any function _getCustomizationService() {
		return _customizationService;
	}
	private void function _setCustomizationService( required any customizationService ) {
		_customizationService = arguments.customizationService;
	}

	private any function _getDataManagerService() {
		return _dataManagerService;
	}
	private void function _setDataManagerService( required any dataManagerService ) {
		_dataManagerService = arguments.dataManagerService;
	}
}