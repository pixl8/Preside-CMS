/**
 * @feature admin and customFields
 */
component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="customFieldsService"  inject="customFieldsService";
	property name="customizationService" inject="dataManagerCustomizationService";
	property name="formsService"         inject="formsService";

	variables.permissionBase = "customfields";
	variables.infoCardStyle  = "definitionList";
	variables.infoCol1       = [ "label", "key", "kind" ];
	variables.infoCol2       = [ "data_type", "active", "slot" ];
	variables.infoCol3       = [ "data_exportable", "batch_editable", "modified" ];
	variables.tabs           = [ "lookups", "conditional_labels" ];
	variables.extraSelectFieldsForViewRecord = [ "lookup_count", "conditional_rule_count" ];

	private boolean function checkPermission( event, rc, prc, args={} ) {
		var key           = args.key ?: "";
		var hasPermission = hasCmsPermission( "#variables.permissionBase#.manage" );

		if ( ListFindNoCase( "read,navigate", key ) ) {
			hasPermission = hasPermission || hasCmsPermission( "#variables.permissionBase#.manage" );
		}

		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

	private any function addRecordAction( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );
		var listingQs    = Len( targetObject ) ? "target_object=#targetObject#" : "";
		var successQs    = listingQs;
		var kind         = rc.kind      ?: "";
		var dataType     = rc.data_type ?: "";
		var successOp    = "editRecord";

		if ( kind == "conditional_label" ) {
			successOp = "viewRecord";
			successQs = ListAppend( successQs, "tab=conditional_labels", "&" );
		} else if ( kind == "static" && dataType == "lookup" ) {
			successOp = "viewRecord";
			successQs = ListAppend( successQs, "tab=lookups", "&" );
		}

		return runEvent(
			  event          = "admin.datamanager._addRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  args          = args
				, object        = "custom_field"
				, audit         = true
				, successUrl    = event.buildAdminLink( objectName="custom_field", operation=successOp, recordId="{newid}", queryString=successQs )
				, errorUrl      = event.buildAdminLink( objectName="custom_field", operation="addRecord", queryString=listingQs )
				, addAnotherUrl = event.buildAdminLink( objectName="custom_field", operation="addRecord", queryString=listingQs )
			  }
		);
	}

	private void function preAddRecordAction( event, rc, prc, args={} ) {
		var formData = args.formData ?: {};

		formData.active = false;
		_normalizeTypeFields( formData );
		_validateFieldKey( argumentCollection=arguments );
		_validateCreateType( argumentCollection=arguments );
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		_validateAggregateConfig( argumentCollection=arguments );
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var formName = "preside-objects.custom_field.admin.edit";
		var kind     = prc.record.kind ?: "";
		var dataType = prc.record.data_type ?: "";
		var kindForm = "preside-objects.custom_field.admin.edit.#kind#";
		var typeForm = kindForm & "." & dataType;

		if ( kind == "conditional_label" && !isFeatureEnabled( "rulesEngine" ) ) {
			return formName;
		}

		if ( Len( Trim( kind ) ) && formsService.formExists( kindForm ) ) {
			formName = formsService.getMergedFormName( formName, kindForm );
		}
		if ( kind == "static" && Len( Trim( dataType ) ) && formsService.formExists( typeForm ) ) {
			formName = formsService.getMergedFormName( formName, typeForm );
		}

		return formName;
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );
		if ( Len( targetObject ) ) {
			args.extraFilters = args.extraFilters ?: [];
			ArrayAppend( args.extraFilters, { filter={ target_object=targetObject } } );
		}
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );
		if ( Len( targetObject ) ) {
			return "target_object=#targetObject#";
		}
		return "";
	}

	private string function preRenderListing( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );

		if ( Len( targetObject ) ) {
			var objectTitle = translateResource( uri="preside-objects.#targetObject#:title", defaultValue=targetObject );

			prc.pageTitle    = translateResource( uri="cms:datamanager.managecustomfields.title" );
			prc.pageSubTitle = translateResource( uri="cms:datamanager.managecustomfields.subtitle", data=[ objectTitle ] );
		}

		return "";
	}

	private string function preRenderAddRecordForm( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );

		prc.pageSubTitle = translateResource( uri="preside-objects.custom_field:add.subtitle" );

		if ( Len( targetObject ) ) {
			args.record = args.record ?: {};
			args.record.target_object = targetObject;
			args.additionalArgs = args.additionalArgs ?: {};
			args.additionalArgs.fields = args.additionalArgs.fields ?: {};
			args.additionalArgs.fields.target_object = {
				  type         = "hidden"
				, layout       = ""
				, defaultValue = targetObject
			};
		}

		return "";
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		var record   = args.record ?: ( IsStruct( prc.record ?: "" ) ? prc.record : {} );
		var kind     = record.kind ?: "";
		var dataType = record.data_type ?: "";
		var parts    = [];
		var hint     = "";

		if ( Len( Trim( kind ) ) ) {
			ArrayAppend( parts, translateResource( uri="enum.customFieldKind:#kind#.label", defaultValue=kind ) );
		}
		if ( kind == "static" && Len( Trim( dataType ) ) ) {
			ArrayAppend( parts, translateResource( uri="enum.customFieldDataType:#dataType#.label", defaultValue=dataType ) );
		}
		if ( !IsTrue( record.active ?: "" ) ) {
			ArrayAppend( parts, translateResource( uri="preside-objects.custom_field:edit.inactive.hint" ) );
		}

		if ( ArrayLen( parts ) ) {
			prc.pageSubTitle = ArrayToList( parts, " · " );
		}

		if ( kind == "conditional_label" ) {
			hint = translateResource( uri="preside-objects.custom_field:edit.conditional.hint" );
		} else if ( kind == "static" && dataType == "lookup" ) {
			hint = translateResource( uri="preside-objects.custom_field:edit.lookups.hint" );
		} else if ( kind == "aggregate" ) {
			hint = translateResource( uri="preside-objects.custom_field:edit.aggregate.hint" );
		}

		if ( Len( hint ) ) {
			return '<div class="alert alert-info"><p><i class="fa fa-fw fa-info-circle"></i> #HtmlEditFormat( hint )#</p></div>';
		}

		return "";
	}

	private string function _lookupsTab( event, rc, prc, args={} ) {
		if ( ( args.record.data_type ?: "" ) != "lookup" ) {
			return "";
		}

		args.fieldId = prc.recordId ?: "";

		return renderView( view="/admin/datamanager/custom_field/_lookupsTab", args=args );
	}

	private string function _conditional_labelsTab( event, rc, prc, args={} ) {
		if ( ( args.record.kind ?: "" ) != "conditional_label" || !isFeatureEnabled( "rulesEngine" ) ) {
			return "";
		}

		args.fieldId = prc.recordId ?: "";

		return renderView( view="/admin/datamanager/custom_field/_conditionalLabelsTab", args=args );
	}

	private void function rootBreadcrumb( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );

		if ( Len( targetObject ) ) {
			customizationService.runCustomization(
				  objectName     = targetObject
				, action         = "rootBreadcrumb"
				, defaultHandler = "admin.datamanager._rootBreadcrumb"
				, args           = _parentBreadcrumbArgs( targetObject )
			);
		} else {
			runEvent(
				  event          = "admin.datamanager._rootBreadcrumb"
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=args }
			);
		}
	}

	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );

		if ( Len( targetObject ) ) {
			customizationService.runCustomization(
				  objectName     = targetObject
				, action         = "objectBreadcrumb"
				, defaultHandler = "admin.datamanager._objectBreadcrumb"
				, args           = _parentBreadcrumbArgs( targetObject )
			);

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.managecustomfields.breadcrumb.title" )
				, link  = event.buildAdminLink( objectName="custom_field", queryString="target_object=#targetObject#" )
			);
		} else {
			runEvent(
				  event          = "admin.datamanager._objectBreadcrumb"
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=args }
			);
		}
	}

	private string function buildListingLink( event, rc, prc, args={} ) {
		return _delegateObjectLink( argumentCollection=arguments, action="buildListingLink" );
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		_appendTargetObjectQueryString( argumentCollection=arguments );

		return super.buildViewRecordLink( argumentCollection=arguments );
	}

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		return _delegateObjectLink( argumentCollection=arguments, action="buildAddRecordLink" );
	}

	private string function buildAddRecordActionLink( event, rc, prc, args={} ) {
		return _delegateObjectLink( argumentCollection=arguments, action="buildAddRecordActionLink" );
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		return _delegateObjectLink( argumentCollection=arguments, action="buildEditRecordLink" );
	}

	private string function buildEditRecordActionLink( event, rc, prc, args={} ) {
		return _delegateObjectLink( argumentCollection=arguments, action="buildEditRecordActionLink" );
	}

	private string function buildDeleteRecordActionLink( event, rc, prc, args={} ) {
		return _delegateObjectLink( argumentCollection=arguments, action="buildDeleteRecordActionLink" );
	}

	private void function _validateFieldKey( event, rc, prc, args={} ) {
		var formData         = args.formData         ?: {};
		var validationResult = args.validationResult ?: "";
		if ( !IsObject( validationResult ) ) {
			return;
		}

		var error = customFieldsService.getFieldKeyValidationError(
			  objectName = formData.target_object ?: ""
			, key        = formData.key ?: ""
			, excludeId  = formData.id  ?: ""
		);
		if ( Len( Trim( error ) ) ) {
			validationResult.addError( fieldName="key", message=error );
		}
	}

	private void function _validateCreateType( event, rc, prc, args={} ) {
		var formData         = args.formData         ?: {};
		var validationResult = args.validationResult ?: "";
		if ( !IsObject( validationResult ) ) {
			return;
		}

		if ( ( formData.kind ?: "" ) == "static" && !Len( Trim( formData.data_type ?: "" ) ) ) {
			validationResult.addError( fieldName="data_type", message="cms:validation.required.default" );
		}

		if ( ( formData.kind ?: "" ) == "aggregate" && !customFieldsService.objectHasAggregateRelationships( formData.target_object ?: "" ) ) {
			validationResult.addError( fieldName="kind", message="customFields:validation.aggregate.no.relationships" );
		}
	}

	private void function _validateAggregateConfig( event, rc, prc, args={} ) {
		var formData         = args.formData         ?: {};
		var validationResult = args.validationResult ?: "";
		var kind             = prc.record.kind ?: ( formData.kind ?: "" );

		if ( kind != "aggregate" || !IsObject( validationResult ) ) {
			return;
		}

		if ( !Len( Trim( formData.aggregate_property ?: "" ) ) ) {
			validationResult.addError( fieldName="aggregate_property", message="cms:validation.required.default" );
		}

		var fn = LCase( Trim( formData.aggregate_function ?: "count" ) );
		if ( fn != "count" && !Len( Trim( formData.aggregate_value_property ?: "" ) ) ) {
			validationResult.addError( fieldName="aggregate_value_property", message="cms:validation.required.default" );
		}
	}

	private void function _normalizeTypeFields( required struct formData ) {
		if ( ( arguments.formData.kind ?: "" ) != "static" ) {
			arguments.formData.data_type      = "";
			arguments.formData.batch_editable = false;
		}
		if ( ( arguments.formData.kind ?: "" ) == "aggregate" && !Len( Trim( arguments.formData.aggregate_function ?: "" ) ) ) {
			arguments.formData.aggregate_function = "count";
		}
	}

	private string function _getTargetObject( event, rc, prc, args={} ) {
		var targetObject = Trim( rc.target_object ?: "" );

		if ( !Len( targetObject ) && !IsSimpleValue( prc.record ?: "" ) ) {
			targetObject = Trim( prc.record.target_object ?: "" );
		}

		if ( targetObject == "custom_field" ) {
			return "";
		}

		return targetObject;
	}

	private struct function _parentBreadcrumbArgs( required string targetObject ) {
		return {
			  objectName  = arguments.targetObject
			, objectTitle = translateResource( uri="preside-objects.#arguments.targetObject#:title", defaultValue=arguments.targetObject )
		};
	}

	private string function _delegateObjectLink( event, rc, prc, args={}, required string action ) {
		_appendTargetObjectQueryString( argumentCollection=arguments );

		return runEvent(
			  event          = "admin.objectLinks.#arguments.action#"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
	}

	private void function _appendTargetObjectQueryString( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );
		var qs           = args.queryString ?: "";

		if ( Len( targetObject ) && !ReFindNoCase( "(^|&)target_object=", qs ) ) {
			args.queryString = ListAppend( qs, "target_object=#targetObject#", "&" );
		}
	}

}
