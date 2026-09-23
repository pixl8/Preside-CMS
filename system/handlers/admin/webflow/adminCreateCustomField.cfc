/**
 * @feature admin and customFields and webflow
 */
component {

	property name="customFieldsService"  inject="customFieldsService";
	property name="formsService"         inject="formsService";
	property name="presideObjectService" inject="presideObjectService";
	property name="messageBox"           inject="messagebox@cbmessagebox";

	private struct function initState( event, rc, prc, args={} ) {
		return {
			target_object = Trim( args.targetObject ?: ( rc.target_object ?: "" ) )
		};
	}

	private string function basics( event, rc, prc, args={}, wfInstance ) {
		var state        = arguments.wfInstance.getState();
		var targetObject = Trim( state.target_object ?: "" );
		var extraFields  = {};

		if ( Len( targetObject ) ) {
			extraFields.target_object = {
				  type         = "hidden"
				, layout       = ""
				, defaultValue = targetObject
			};
		}

		return renderForm(
			  formName         = "webflow.adminCreateCustomField.basics"
			, context          = "admin"
			, formId           = "webflow-adminCreateCustomField-#( args.instanceRef ?: "" )#-basics"
			, savedData        = state
			, additionalArgs   = { fields=extraFields }
			, validationResult = rc.validationResult ?: ""
		);
	}

	private boolean function basicsAction( event, rc, prc, wfInstance, validationResult, persistData ) {
		_validateForm(
			  formName         = "webflow.adminCreateCustomField.basics"
			, formData         = arguments.persistData
			, validationResult = arguments.validationResult
		);

		if ( ( arguments.persistData.kind ?: "" ) != "static" ) {
			arguments.persistData.data_type = "";
		}
		if ( ( arguments.persistData.kind ?: "" ) != "conditional_label" ) {
			arguments.persistData.conditional_label_mode = "";
		}

		runEvent(
			  event          = "admin.datamanager.custom_field._validateFieldKey"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args={ formData=arguments.persistData, validationResult=arguments.validationResult } }
		);
		runEvent(
			  event          = "admin.datamanager.custom_field._validateCreateType"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args={ formData=arguments.persistData, validationResult=arguments.validationResult } }
		);

		return arguments.validationResult.validated();
	}

	private boolean function objectRefAction( event, rc, prc, wfInstance, validationResult, persistData ) {
		if ( !Len( Trim( arguments.persistData.related_object ?: "" ) ) ) {
			arguments.validationResult.addError( fieldName="related_object", message="cms:validation.required.default" );
		}

		return arguments.validationResult.validated();
	}

	private boolean function aggregateAction( event, rc, prc, wfInstance, validationResult, persistData ) {
		var state = arguments.wfInstance.getState();
		StructAppend( arguments.persistData, { kind=state.kind ?: "aggregate", target_object=state.target_object ?: "" }, false );
		prc.record = { kind="aggregate", target_object=state.target_object ?: "" };

		if ( !Len( Trim( arguments.persistData.aggregate_function ?: "" ) ) ) {
			arguments.persistData.aggregate_function = "count";
		}

		runEvent(
			  event          = "admin.datamanager.custom_field._validateAggregateConfig"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args={ formData=arguments.persistData, validationResult=arguments.validationResult } }
		);

		return arguments.validationResult.validated();
	}

	private boolean function relatedDataAction( event, rc, prc, wfInstance, validationResult, persistData ) {
		var state = arguments.wfInstance.getState();
		StructAppend( arguments.persistData, { kind=state.kind ?: "related_data", target_object=state.target_object ?: "" }, false );
		prc.record = { kind="related_data", target_object=state.target_object ?: "" };

		runEvent(
			  event          = "admin.datamanager.custom_field._validateRelatedDataConfig"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args={ formData=arguments.persistData, validationResult=arguments.validationResult } }
		);

		return arguments.validationResult.validated();
	}

	private string function permissions( event, rc, prc, args={}, wfInstance ) {
		var state = arguments.wfInstance.getState();

		return renderForm(
			  formName         = "webflow.adminCreateCustomField.permissions"
			, context          = "admin"
			, formId           = "webflow-adminCreateCustomField-#( args.instanceRef ?: "" )#-permissions"
			, savedData        = state
			, validationResult = rc.validationResult ?: ""
		);
	}

	private boolean function submitAction( event, rc, prc, args={}, wfInstance, validationResult, persistData ) {
		if ( !hasCmsPermission( "customfields.add" ) ) {
			event.adminAccessDenied();
		}

		var state = arguments.wfInstance.getState();

		arguments.persistData.flags = _flagsToList( arguments.persistData.flags ?: ( rc.flags ?: "" ) );

		_validateForm(
			  formName         = "webflow.adminCreateCustomField.permissions"
			, formData         = arguments.persistData
			, validationResult = arguments.validationResult
		);

		if ( !arguments.validationResult.validated() ) {
			return false;
		}

		var data  = _prepareInsertData( state, arguments.persistData );
		var newId = presideObjectService.insertData(
			  objectName = "custom_field"
			, data       = data
		);

		event.audit(
			  action   = "datamanager_add_record"
			, type     = "datamanager"
			, recordId = newId
			, detail   = { id=newId, objectName="custom_field", label=data.label ?: "", key=data.key ?: "" }
		);

		arguments.wfInstance.appendState( { newRecordId=newId } );

		return true;
	}

	private string function confirmation( event, rc, prc, args={}, wfInstance ) {
		var state        = arguments.wfInstance.getState();
		var newId        = Trim( state.newRecordId ?: "" );
		var targetObject = Trim( state.target_object ?: "" );
		var qs           = Len( targetObject ) ? "target_object=#targetObject#" : "";
		var kind         = state.kind      ?: "";
		var dataType     = state.data_type ?: "";

		if ( !Len( newId ) ) {
			setNextEvent( url=event.buildAdminLink( objectName="custom_field", queryString=qs ) );
		}

		if ( kind == "conditional_label" ) {
			qs = ListAppend( qs, "tab=conditional_labels", "&" );
		} else if ( kind == "static" && dataType == "lookup" ) {
			qs = ListAppend( qs, "tab=lookups", "&" );
		}

		messageBox.info( translateResource( uri="webflow.adminCreateCustomField:created" ) );

		setNextEvent( url=event.buildAdminLink(
			  objectName  = "custom_field"
			, operation   = "viewRecord"
			, recordId    = newId
			, queryString = qs
		) );
	}

	private void function postCancel( event, rc, prc, args={}, wfInstance ) {
		var targetObject = "";

		if ( !IsNull( arguments.wfInstance ) ) {
			try {
				targetObject = Trim( arguments.wfInstance.getState().target_object ?: "" );
			} catch ( any e ) {}
		}
		if ( !Len( targetObject ) ) {
			targetObject = Trim( rc.target_object ?: "" );
		}

		messageBox.info( translateResource( uri="webflow.adminCreateCustomField:cancelled" ) );

		setNextEvent( url=event.buildAdminLink(
			  objectName  = "custom_field"
			, queryString = Len( targetObject ) ? "target_object=#targetObject#" : ""
		) );
	}

	private void function _validateForm(
		  required string formName
		, required struct formData
		, required any    validationResult
	) {
		formsService.validateForm(
			  formName         = arguments.formName
			, formData         = arguments.formData
			, validationResult = arguments.validationResult
		);
	}

	private struct function _prepareInsertData( required struct state, required struct persistData ) {
		var merged = Duplicate( arguments.state );
		StructAppend( merged, arguments.persistData, true );

		var kind  = merged.kind ?: "static";
		var flags = ListToArray( _flagsToList( merged.flags ?: "" ) );
		var data  = {
			  label                  = Trim( merged.label         ?: "" )
			, key                    = Trim( merged.key           ?: "" )
			, target_object          = Trim( merged.target_object ?: "" )
			, kind                   = kind
			, help_text              = Trim( merged.help_text     ?: "" )
			, show_in_listing        = ArrayFindNoCase( flags, "show_in_listing" ) > 0
			, filterable             = ArrayFindNoCase( flags, "filterable"      ) > 0
			, data_exportable        = ArrayFindNoCase( flags, "data_exportable" ) > 0
			, batch_editable         = ArrayFindNoCase( flags, "batch_editable"  ) > 0
			, active                 = ArrayFindNoCase( flags, "active"          ) > 0
			, conditional_label_mode = kind == "conditional_label" ? ( merged.conditional_label_mode ?: "single" ) : ""
			, sort_order             = _nextSortOrder( merged.target_object ?: "" )
		};

		if ( kind == "static" ) {
			data.data_type      = Trim( merged.data_type      ?: "" );
			data.related_object = Trim( merged.related_object ?: "" );
		} else {
			data.data_type      = Trim( merged.data_type ?: "" );
			data.batch_editable = false;
		}

		if ( kind == "aggregate" ) {
			data.aggregate_property       = Trim( merged.aggregate_property       ?: "" );
			data.aggregate_function       = Len( Trim( merged.aggregate_function ?: "" ) ) ? merged.aggregate_function : "count";
			data.aggregate_value_property = Trim( merged.aggregate_value_property ?: "" );
			data.aggregate_filter         = Trim( merged.aggregate_filter         ?: "" );
		}

		if ( kind == "related_data" ) {
			data.related_data_relationship = Trim( merged.related_data_relationship ?: "" );
			data.related_data_property     = Trim( merged.related_data_property     ?: "" );
			data.batch_editable            = false;
		}

		return data;
	}

	private string function _flagsToList( required any flags ) {
		if ( IsArray( arguments.flags ) ) {
			return ArrayToList( arguments.flags );
		}

		return ToString( arguments.flags );
	}

	private numeric function _nextSortOrder( required string targetObject ) {
		if ( !Len( arguments.targetObject ) ) {
			return 1;
		}

		var existing = presideObjectService.selectData(
			  objectName   = "custom_field"
			, selectFields = [ "Max( sort_order ) as max_sort" ]
			, filter       = { target_object=arguments.targetObject }
		);

		return Val( existing.max_sort ?: 0 ) + 1;
	}

}
