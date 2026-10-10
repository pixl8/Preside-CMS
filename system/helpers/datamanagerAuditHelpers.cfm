<cfscript>
	function _auditDataManagerRecordAction( required string handlerAction ) {
		var event        = getController().getRequestContext();
		var prc          = event.getCollection( private=true );
		var handlerEvent = "admin.datamanager._" & arguments.handlerAction;

		arguments.object        = arguments.objectName    ?: ( prc.objectName ?: "" );
		arguments.draftsEnabled = arguments.draftsEnabled ?: isTrue( prc.draftsEnabled ?: "" );

		if ( !Len( Trim( arguments.object ) ) ) {
			throw( type="datamanager.audit.missing.objectname", message="A call to [#arguments.handlerAction#] was made without an objectName. Outside of a datamanager request to an object record, you must pass this in manually." );
		}

		StructDelete( arguments, "handlerAction" );
		StructDelete( arguments, "objectName"    );

		getController().runEvent(
			  event          = handlerEvent
			, private        = true
			, prePostExempt  = true
			, eventArguments = arguments
		);
	}

	function auditDataManagerAddRecord(
		  string  objectName
		, required string recordId
		,        struct  formData
		,        string  formName
		,        string  auditAction
		,        string  auditType
		,        boolean draftsEnabled
		,        boolean isDraft
	) {
		_auditDataManagerRecordAction( argumentCollection=arguments, handlerAction="addRecordActionAudit" );
	}

	function auditDataManagerEditRecord(
		  string  objectName
		, required string recordId
		,        struct  formData
		,        string  formName
		,        string  auditAction
		,        string  auditType
		,        boolean draftsEnabled
		,        boolean isDraft
	) {
		_auditDataManagerRecordAction( argumentCollection=arguments, handlerAction="editRecordActionAudit" );
	}
</cfscript>
