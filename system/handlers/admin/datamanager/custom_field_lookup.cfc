/**
 * @feature admin and customFields
 */
component {

	property name="customFieldsService"  inject="customFieldsService";
	property name="customizationService" inject="dataManagerCustomizationService";
	property name="presideObjectService" inject="presideObjectService";

	variables.permissionBase = "customfields";
	variables.parentTab      = "lookups";
	variables.objectName     = "custom_field_lookup";

	private boolean function checkPermission( event, rc, prc, args={} ) {
		var key           = args.key ?: "";
		var hasPermission = hasCmsPermission( "#variables.permissionBase#.manage" );

		if ( ListFindNoCase( "clone", key ) ) {
			hasPermission = false;
		}

		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

	private void function rootBreadcrumb( event, rc, prc, args={} ) {
		var parent = _getParentField( argumentCollection=arguments );
		if ( !Len( parent.id ?: "" ) ) {
			event.notFound();
		}

		rc.target_object = parent.target_object ?: ( rc.target_object ?: "" );

		customizationService.runCustomization(
			  objectName     = "custom_field"
			, action         = "rootBreadcrumb"
			, args           = args
		);
		customizationService.runCustomization(
			  objectName     = "custom_field"
			, action         = "objectBreadcrumb"
			, defaultHandler = "admin.datamanager._objectBreadcrumb"
			, args           = {
				  objectName  = "custom_field"
				, objectTitle = translateResource( uri="preside-objects.custom_field:title", defaultValue="custom_field" )
			}
		);
		customizationService.runCustomization(
			  objectName     = "custom_field"
			, action         = "recordBreadcrumb"
			, defaultHandler = "admin.datamanager._recordBreadcrumb"
			, args           = {
				  objectName  = "custom_field"
				, recordId    = parent.id
				, recordLabel = parent.label ?: parent.key ?: parent.id
			}
		);
	}

	private string function buildListingLink( event, rc, prc, args={} ) {
		return _parentViewLink( argumentCollection=arguments );
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		return "field=" & _getFieldId( argumentCollection=arguments );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var fieldId = _getFieldId( argumentCollection=arguments );

		args.extraFilters = args.extraFilters ?: [];
		if ( Len( fieldId ) ) {
			ArrayAppend( args.extraFilters, { filter={ field=fieldId } } );
		}
	}

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		arguments.queryString = "object=#variables.objectName#&field=" & _getFieldId( argumentCollection=arguments );

		return event.buildAdminLink( linkto="datamanager.addRecord", queryString=_withTargetObject( argumentCollection=arguments ) );
	}

	private string function buildAddRecordActionLink( event, rc, prc, args={} ) {
		arguments.queryString = "object=#variables.objectName#&field=" & _getFieldId( argumentCollection=arguments );

		return event.buildAdminLink( linkto="datamanager.addRecordAction", queryString=_withTargetObject( argumentCollection=arguments ) );
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var fieldId  = _getFieldId( argumentCollection=arguments );
		var recordId = args.recordId ?: ( rc.id ?: "" );

		arguments.queryString = "object=#variables.objectName#&id=#recordId#&field=#fieldId#";

		return event.buildAdminLink( linkto="datamanager.editRecord", queryString=_withTargetObject( argumentCollection=arguments ) );
	}

	private string function buildDeleteRecordActionLink( event, rc, prc, args={} ) {
		var fieldId  = _getFieldId( argumentCollection=arguments );
		var recordId = args.recordId ?: ( rc.id ?: "" );

		arguments.queryString = "object=#variables.objectName#&id=#recordId#&field=#fieldId#";

		return event.buildAdminLink( linkto="datamanager.deleteRecordAction", queryString=_withTargetObject( argumentCollection=arguments ) );
	}

	private any function addRecordAction( event, rc, prc, args={} ) {
		arguments.queryString = "field=" & _getFieldId( argumentCollection=arguments );
		var qs = _withTargetObject( argumentCollection=arguments );

		return runEvent(
			  event          = "admin.datamanager._addRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  args          = args
				, object        = variables.objectName
				, audit         = true
				, successUrl    = _parentViewLink( argumentCollection=arguments )
				, errorUrl      = event.buildAdminLink( objectName=variables.objectName, operation="addRecord", queryString=qs )
				, addAnotherUrl = event.buildAdminLink( objectName=variables.objectName, operation="addRecord", queryString=qs )
			  }
		);
	}

	private void function editRecordAction( event, rc, prc, args={} ) {
		var fieldId  = _getFieldId( argumentCollection=arguments );
		var recordId = args.recordId ?: ( rc.id ?: "" );

		arguments.queryString = "field=#fieldId#&id=#recordId#";
		var qs = _withTargetObject( argumentCollection=arguments );

		args.successUrl = _parentViewLink( argumentCollection=arguments );

		runEvent(
			  event          = "admin.datamanager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  args       = args
				, object     = variables.objectName
				, audit      = true
				, successUrl = args.successUrl
				, errorUrl   = event.buildAdminLink( objectName=variables.objectName, operation="editRecord", recordId=recordId, queryString=qs )
			  }
		);
	}

	private void function deleteRecordAction( event, rc, prc, args={} ) {
		runEvent(
			  event          = "admin.datamanager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  args          = args
				, object        = variables.objectName
				, audit         = true
				, postActionUrl = _parentViewLink( argumentCollection=arguments )
			  }
		);
	}

	private string function preRenderAddRecordForm( event, rc, prc, args={} ) {
		var fieldId = _getFieldId( argumentCollection=arguments );
		if ( !Len( fieldId ) ) {
			event.notFound();
		}

		args.record = args.record ?: {};
		args.record.field = fieldId;
		args.additionalArgs = args.additionalArgs ?: {};
		args.additionalArgs.fields = args.additionalArgs.fields ?: {};
		args.additionalArgs.fields.field = {
			  type         = "hidden"
			, layout       = ""
			, defaultValue = fieldId
		};

		return "";
	}

	private void function preAddRecordAction( event, rc, prc, args={} ) {
		var formData = args.formData ?: {};
		var fieldId  = _getFieldId( argumentCollection=arguments );

		if ( Len( fieldId ) ) {
			formData.field = fieldId;
		}
	}

	private string function _getFieldId( event, rc, prc, args={} ) {
		var fieldId = Trim( rc.field ?: "" );
		var record  = prc.record ?: "";

		if ( !Len( fieldId ) ) {
			fieldId = Trim( args.field ?: "" );
		}
		if ( !Len( fieldId ) && IsQuery( record ) && record.recordCount && ListFindNoCase( record.columnList, "field" ) ) {
			fieldId = Trim( record.field );
		} else if ( !Len( fieldId ) && IsStruct( record ) ) {
			fieldId = Trim( record.field ?: "" );
		}
		if ( !Len( fieldId ) && ( prc.objectName ?: "" ) == "custom_field" ) {
			fieldId = Trim( prc.recordId ?: "" );
		}
		if ( !Len( fieldId ) && ( prc.objectName ?: "" ) == variables.objectName ) {
			var childId = ListFirst( Trim( args.recordId ?: ( rc.id ?: "" ) ) );
			if ( Len( childId ) ) {
				var child = presideObjectService.selectData(
					  objectName   = variables.objectName
					, id           = childId
					, selectFields = [ "field" ]
				);
				if ( child.recordCount ) {
					fieldId = Trim( child.field );
				}
			}
		}

		return fieldId;
	}

	private struct function _getParentField( event, rc, prc, args={} ) {
		var fieldId = _getFieldId( argumentCollection=arguments );

		if ( !Len( fieldId ) ) {
			return {};
		}

		return customFieldsService.getField( fieldId );
	}

	private string function _parentViewLink( event, rc, prc, args={} ) {
		var parent = _getParentField( argumentCollection=arguments );
		var qs     = "tab=#variables.parentTab#";

		if ( Len( parent.target_object ?: "" ) ) {
			qs = ListAppend( qs, "target_object=#parent.target_object#", "&" );
		}

		return event.buildAdminLink( objectName="custom_field", recordId=parent.id ?: "", queryString=qs );
	}

	private string function _withTargetObject( required string queryString, event, rc, prc, args={} ) {
		var parent = _getParentField( argumentCollection=arguments );
		var qs     = arguments.queryString;

		if ( Len( parent.target_object ?: "" ) && !ReFindNoCase( "(^|&)target_object=", qs ) ) {
			qs = ListAppend( qs, "target_object=#parent.target_object#", "&" );
		}

		return qs;
	}

}
