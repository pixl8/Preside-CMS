/**
 * @feature admin and urlRedirects
 */
component {

	variables.permissionBase = "urlRedirects";

	private boolean function checkPermission( event, rc, prc, args={} ) {
		var key           = args.key ?: "";
		var hasPermission = false;

		if ( Len( Trim( key ) ) ) {
			if ( ArrayContains( [ "add", "edit", "delete" ], key ) ) {
				key = "#key#Rule";
			}

			hasPermission = hasCmsPermission( "#variables.permissionBase#.#key#" );
		}

		if ( !hasPermission && isTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return true;
	}

	private string function preRenderAddRecordForm( event, rc, prc, args={} ) {
		_includeForRecordForm( argumentCollection=arguments );
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		_includeForRecordForm( argumentCollection=arguments );
	}

	public void function addRecordAction( event, rc, prc, batch=false, batchAll=false, batchSrcArgs={} ) {
		_checkPermission( argumentCollection=arguments, key="add" );

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  audit        = true
				, auditType    = "urlredirects"
				, auditAction  = "add_redirect_rule"
				, batch        = arguments.batch
				, batchAll     = arguments.batchAll
				, batchSrcArgs = arguments.batchSrcArgs
			  }
		);
	}

	public void function editRecordAction( event, rc, prc, batch=false, batchAll=false, batchSrcArgs={} ) {
		_checkPermission( argumentCollection=arguments, key="edit" );

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  audit        = true
				, auditType    = "urlredirects"
				, auditAction  = "edit_redirect_rule"
				, batch        = arguments.batch
				, batchAll     = arguments.batchAll
				, batchSrcArgs = arguments.batchSrcArgs
			  }
		);
	}

	public void function deleteRecordAction( event, rc, prc, batch=false, batchAll=false, batchSrcArgs={} ) {
		_checkPermission( argumentCollection=arguments, key="delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  audit        = true
				, auditType    = "urlredirects"
				, auditAction  = "delete_redirect_rule"
				, batch        = arguments.batch
				, batchAll     = arguments.batchAll
				, batchSrcArgs = arguments.batchSrcArgs
			  }
		);
	}

	private void function _includeForRecordForm( event, rc, prc, args={} ) {
		event.include( "/js/admin/specific/urlRedirects/" );

		event.includeData( {
			  "redirectType301Warning"     = translateResource( uri="preside-objects.url_redirect_rule:field.redirect_type.301.warning" )
			, "exactMatchOnlyfalseWarning" = translateResource( uri="preside-objects.url_redirect_rule:field.exact_match_only.false.warning" )
			, "toSlugPrefix"               = translateResource( uri="preside-objects.url_redirect_rule:field.label.slug.to.prefix" )
			, "fromSlugPrefix"             = translateResource( uri="preside-objects.url_redirect_rule:field.label.slug.from.prefix" )
		} );
	}

	private any function _checkPermission(
		  required any     event
		, required struct  rc
		, required struct  prc
		, required string  key
		,          string  object          = prc.objectName ?: ""
		,          boolean throwOnError    = false
		,          boolean checkOperations = true
	) {
		return checkPermission( argumentCollection=arguments );
	}

}