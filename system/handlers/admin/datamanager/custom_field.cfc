/**
 * @feature admin and customFields
 */
component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="customFieldsService"          inject="customFieldsService";
	property name="formsService"                 inject="formsService";
	property name="presideObjectService"         inject="presideObjectService";
	property name="customFieldsPropertyInjector" inject="customFieldsPropertyInjector";
	property name="customFieldTypesService"      inject="customFieldTypesService";

	variables.permissionBase        = "customfields";
	variables.deleteConfirmFormName = "preside-objects.custom_field.admin.delete.confirm";
	variables.infoCardStyle         = "definitionList";
	variables.infoCol1              = [ "label", "key", "kind" ];
	variables.infoCol2              = [ "data_type", "conditional_label_mode", "active" ];
	variables.infoCol3              = [ "show_in_listing", "filterable", "data_exportable", "batch_editable" ];
	variables.tabs                  = [ "lookups", "conditional_labels" ];
	variables.extraSelectFieldsForViewRecord = [ "lookup_count", "conditional_rule_count", "related_data_relationship", "related_data_property" ];

	public string function addRecordForm( event, rc, prc, args={} ) {
		if ( !hasCmsPermission( "customfields.add" ) ) {
			event.adminAccessDenied();
		}

		var targetObject = _getTargetObject( argumentCollection=arguments );
		var listingQs    = Len( targetObject ) ? "target_object=#targetObject#" : "";

		if ( !Len( Trim( rc.flowRef ?: "" ) ) ) {
			var thisUrl = event.getCurrentUrl();
			var qsDelim = Find( "?", thisUrl ) ? "&" : "?";
			setNextEvent( url=thisUrl & qsDelim & "flowRef=#CreateUUID()#" );
		}

		prc.pageSubTitle = translateResource( uri="preside-objects.custom_field:add.subtitle" );

		return renderWebflow(
			  webflowId   = "adminCreateCustomField"
			, instanceRef = rc.flowRef
			, lazyLoad    = false
			, args        = { targetObject=targetObject, listingQs=listingQs }
		);
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		_validateAggregateConfig( argumentCollection=arguments );
		_validateRelatedDataConfig( argumentCollection=arguments );
		_validateDisplayConfig( argumentCollection=arguments );
		_serialiseDisplayConfig( argumentCollection=arguments );
		_normaliseFormPlacement( argumentCollection=arguments );
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

		var displayForm = _getDisplayFormName( kind, dataType );
		if ( Len( displayForm ) ) {
			formName = formsService.getMergedFormName( formName, displayForm );
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

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		var record   = args.record ?: ( IsStruct( prc.record ?: "" ) ? prc.record : {} );
		var kind     = record.kind ?: "";
		var dataType = record.data_type ?: "";
		var parts    = [];
		var hint     = "";

		if ( IsStruct( args.record ?: "" ) && Len( _getDisplayFormName( kind, dataType ) ) ) {
			StructAppend( args.record, customFieldTypesService.getDisplayConfig(
				  dataType   = dataType
				, typeConfig = record.type_config ?: ""
			) );
		}

		if ( Len( Trim( kind ) ) ) {
			ArrayAppend( parts, translateResource( uri="enum.customFieldKind:#kind#.label", defaultValue=kind ) );
		}
		if ( kind == "static" && Len( Trim( dataType ) ) ) {
			ArrayAppend( parts, translateResource( uri="enum.customFieldDataType:#dataType#.label", defaultValue=dataType ) );
		}

		if ( ArrayLen( parts ) ) {
			prc.pageSubTitle = ArrayToList( parts, " · " );
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

	private string function buildListingLink( event, rc, prc, args={} ) {
		return runEvent(
			  event          = "admin.objectLinks.buildListingLink"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
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

	public void function toggleActiveAction( event, rc, prc, args={} ) {
		if ( !hasCmsPermission( "customfields.edit" ) ) {
			event.adminAccessDenied();
		}

		var recordId = Trim( rc.id ?: "" );
		var field    = customFieldsService.getField( recordId );

		if ( StructIsEmpty( field ) ) {
			event.notFound();
		}

		var makeActive   = !IsTrue( field.active ?: "" );
		var targetObject = field.target_object ?: "";
		var objectTitle  = Len( targetObject ) ? translateResource( uri="preside-objects.#targetObject#:title", defaultValue=targetObject ) : targetObject;
		var qs           = Len( targetObject ) ? "target_object=#targetObject#" : "";

		presideObjectService.updateData(
			  objectName = "custom_field"
			, id         = recordId
			, data       = { active=makeActive }
		);

		messageBox.info( translateResource(
			  uri  = makeActive ? "preside-objects.custom_field:activate.success" : "preside-objects.custom_field:deactivate.success"
			, data = [ field.label ?: field.key ?: recordId, objectTitle ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName="custom_field", operation="viewRecord", recordId=recordId, queryString=qs ) );
	}

	private void function extraTopRightButtonsForObject( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );
		var actions      = args.actions ?: [];

		for( var i=ArrayLen( actions ); i>=1; i-- ) {
			if ( ( actions[ i ].globalKey ?: "" ) != "o" ) {
				continue;
			}
			if ( !Len( targetObject ) ) {
				ArrayDeleteAt( actions, i );
			} else {
				actions[ i ].link = event.buildAdminLink(
					  objectName  = "custom_field"
					, operation   = "sortRecords"
					, queryString = "target_object=#targetObject#"
				);
			}
		}

		args.actions = actions;
	}

	private void function extraTopRightButtonsForViewRecord( event, rc, prc, args={} ) {
		var record       = _getViewRecord( argumentCollection=arguments );
		var recordId     = prc.recordId ?: ( record.id ?: ( rc.id ?: "" ) );
		var isActive     = IsTrue( record.active ?: "" );
		var targetObject = _getTargetObject( argumentCollection=arguments );
		var objectTitle  = Len( targetObject ) ? translateResource( uri="preside-objects.#targetObject#:title", defaultValue=targetObject ) : "";
		var qs           = "id=#recordId#";

		if ( Len( targetObject ) ) {
			qs = ListAppend( qs, "target_object=#targetObject#", "&" );
		}

		ArrayPrepend( args.actions ?: [], {
			  link      = event.buildAdminLink( linkto="datamanager.custom_field.toggleActiveAction", queryString=qs )
			, btnClass  = isActive ? "btn-warning" : "btn-success"
			, iconClass = isActive ? "fa-eye-slash" : "fa-check"
			, title     = translateResource( uri="preside-objects.custom_field:#isActive ? 'deactivate' : 'activate'#.btn" )
			, prompt    = translateResource(
				  uri  = "preside-objects.custom_field:#isActive ? 'deactivate' : 'activate'#.prompt"
				, data = [ record.label ?: record.key ?: recordId, objectTitle ]
			  )
		} );

		_pointDeleteActionAtConfirmation( event, args.actions ?: [], recordId );
	}

	public void function confirmDelete( event, rc, prc ) {
		checkPermission(
			  event = arguments.event
			, rc    = arguments.rc
			, prc   = arguments.prc
			, args  = { key="delete", object="custom_field", throwOnError=true }
		);

		var field = customFieldsService.getField( Trim( rc.id ?: "" ) );
		if ( StructIsEmpty( field ) ) {
			event.notFound();
		}

		var targetObject = field.target_object ?: "";
		var objectTitle  = Len( targetObject ) ? translateResource( uri="preside-objects.#targetObject#:title", defaultValue=targetObject ) : targetObject;
		var fieldName    = customFieldsService.getDeletionConfirmationName( field );
		var storesValues = ( field.kind ?: "" ) == "static";

		prc.pageIcon  = "trash";
		prc.pageTitle = translateResource( uri="preside-objects.custom_field:delete.page.title" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.custom_field:title" )
			, link  = event.buildAdminLink( objectName="custom_field" )
		);
		event.addAdminBreadCrumb(
			  title = fieldName
			, link  = event.buildAdminLink( objectName="custom_field", operation="viewRecord", recordId=field.id )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.custom_field:delete.breadcrumb" )
			, link  = ""
		);

		event.setView( view="/admin/datamanager/custom_field/confirmDelete" );
		prc.fieldName        = fieldName;
		prc.objectTitle      = objectTitle;
		prc.storesValues     = storesValues;
		prc.storedValueCount = storesValues ? customFieldsService.countStoredValues( field ) : 0;
		prc.versioned        = storesValues && Len( targetObject ) && presideObjectService.objectIsVersioned( targetObject );
		prc.formName         = variables.deleteConfirmFormName;
		prc.deleteAction     = event.buildAdminLink( objectName="custom_field", recordId=field.id, operation="deleteRecordAction" );
		prc.actionButtons    = [
			  {
				  type      = "link"
				, href      = event.buildAdminLink( objectName="custom_field", operation="viewRecord", recordId=field.id )
				, class     = "btn-default"
				, globalKey = "c"
				, iconClass = "fa-reply"
				, label     = translateResource( uri="cms:datamanager.cancel.btn" )
			  }
			, {
				  type      = "button"
				, class     = "btn-danger"
				, iconClass = "fa-trash"
				, name      = "_deleteAction"
				, value     = "delete"
				, label     = translateResource( uri="preside-objects.custom_field:delete.submit.btn" )
			  }
		];
	}

	private void function preDeleteRecordAction( event, rc, prc, args={} ) {
		var recordId = Trim( rc.id ?: "" );
		if ( !Len( recordId ) || ListLen( recordId ) != 1 ) {
			messageBox.error( translateResource( uri="preside-objects.custom_field:delete.confirmation.mismatch" ) );
			setNextEvent( url=event.buildAdminLink( objectName="custom_field" ) );
		}

		var field = customFieldsService.getField( recordId );
		if ( StructIsEmpty( field ) ) {
			return;
		}

		var confirmUrl = event.buildAdminLink( linkTo="datamanager.custom_field.confirmDelete", queryString="id=#recordId#" );
		if ( !StructKeyExists( rc, "confirmation_name" ) ) {
			setNextEvent( url=confirmUrl );
		}

		var formData         = event.getCollectionForForm( variables.deleteConfirmFormName );
		var validationResult = validateForm( formName=variables.deleteConfirmFormName, formData=formData );

		if ( validationResult.validated() && !customFieldsService.deletionConfirmationMatches( field, formData.confirmation_name ?: "" ) ) {
			validationResult.addError( fieldName="confirmation_name", message="preside-objects.custom_field:delete.confirmation.mismatch" );
		}
		if ( !validationResult.validated() ) {
			setNextEvent( url=confirmUrl, persistStruct={ validationResult=validationResult } );
		}

		customFieldsService.deleteFieldData( field );
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var record       = args.record     ?: {};
		var recordId     = record.id       ?: "";
		var isActive     = IsTrue( record.active ?: "" );
		var targetObject = record.target_object ?: _getTargetObject( argumentCollection=arguments );
		var objectTitle  = Len( targetObject ) ? translateResource( uri="preside-objects.#targetObject#:title", defaultValue=targetObject ) : "";
		var qs           = "id=#recordId#";

		if ( Len( targetObject ) ) {
			qs = ListAppend( qs, "target_object=#targetObject#", "&" );
		}

		ArrayAppend( args.actions ?: [], {
			  link  = event.buildAdminLink( linkto="datamanager.custom_field.toggleActiveAction", queryString=qs )
			, icon  = isActive ? "fa-eye-slash" : "fa-check"
			, class = "confirmation-prompt"
			, title = translateResource(
				  uri  = "preside-objects.custom_field:#isActive ? 'deactivate' : 'activate'#.prompt"
				, data = [ record.label ?: record.key ?: recordId, objectTitle ]
			  )
		} );

		_pointDeleteActionAtConfirmation( event, args.actions ?: [], recordId );
	}

	private void function _pointDeleteActionAtConfirmation( required any event, required array actions, required string recordId ) {
		if ( !Len( Trim( arguments.recordId ) ) ) {
			return;
		}

		var confirmLink = event.buildAdminLink( linkTo="datamanager.custom_field.confirmDelete", queryString="id=#arguments.recordId#" );
		var deleteTitle = translateResource( uri="preside-objects.custom_field:delete.btn" );

		for( var action in arguments.actions ) {
			if ( !FindNoCase( "deleteRecordAction", action.link ?: "" ) ) {
				continue;
			}

			action.link   = confirmLink;
			action.title  = deleteTitle;
			action.prompt = "";
			action.match  = "";
			action.class  = Trim( ReReplaceNoCase( action.class ?: "", "confirmation-prompt", "" ) );
		}
	}

	private void function preFetchRecordsForSorting( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );

		if ( !Len( targetObject ) ) {
			messageBox.error( translateResource( uri="preside-objects.custom_field:sort.requires.object" ) );
			setNextEvent( url=event.buildAdminLink( objectName="custom_field" ) );
		}

		args.extraFilters = args.extraFilters ?: [];
		ArrayAppend( args.extraFilters, { filter={ target_object=targetObject } } );
		prc.cancelLink = event.buildAdminLink( objectName="custom_field" );
	}

	private string function buildSortRecordsLink( event, rc, prc, args={} ) {
		_appendTargetObjectQueryString( argumentCollection=arguments );

		return runEvent(
			  event          = "admin.objectLinks.buildSortRecordsLink"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
	}

	private string function sortRecordsActionButtons( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );
		var buttons      = runEvent(
			  event          = "admin.datamanager._sortRecordsActionButtons"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);

		if ( !Len( targetObject ) ) {
			return buttons;
		}

		return '<input type="hidden" name="target_object" value="#EncodeForHtmlAttribute( targetObject )#" />' & buttons;
	}

	private array function getSortRecordsActionButtons( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );

		if ( Len( targetObject ) ) {
			args.cancelAction = event.buildAdminLink( objectName="custom_field" );
		}

		return runEvent(
			  event          = "admin.datamanager._getSortRecordsActionButtons"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
	}

	private void function postSortRecordsAction( event, rc, prc, args={} ) {
		var targetObject = _getTargetObject( argumentCollection=arguments );

		if ( !Len( targetObject ) && ArrayLen( args.sortedIds ?: [] ) ) {
			var field = customFieldsService.getField( args.sortedIds[ 1 ] );
			targetObject = field.target_object ?: "";
		}
		if ( Len( targetObject ) ) {
			customFieldsPropertyInjector.refreshObject( targetObject );
		}
	}

	private string function preViewRecordContent( event, rc, prc, args={} ) {
		var record       = args.record ?: _getViewRecord( argumentCollection=arguments );
		var recordId     = args.recordId ?: ( record.id ?: ( prc.recordId ?: "" ) );
		var isActive     = IsTrue( record.active ?: "" );
		var targetObject = record.target_object ?: _getTargetObject( argumentCollection=arguments );
		var objectTitle  = Len( targetObject ) ? translateResource( uri="preside-objects.#targetObject#:title", defaultValue=targetObject ) : targetObject;
		var qs           = "id=#recordId#";

		if ( Len( targetObject ) ) {
			qs = ListAppend( qs, "target_object=#targetObject#", "&" );
		}

		return renderView( view="/admin/datamanager/custom_field/_statusBanner", args={
			  active       = isActive
			, objectTitle  = objectTitle
			, toggleLink   = isActive ? "" : event.buildAdminLink( linkto="datamanager.custom_field.toggleActiveAction", queryString=qs )
			, toggleLabel  = translateResource( uri="preside-objects.custom_field:#isActive ? 'deactivate' : 'activate'#.btn" )
			, togglePrompt = translateResource(
				  uri  = "preside-objects.custom_field:#isActive ? 'deactivate' : 'activate'#.prompt"
				, data = [ record.label ?: record.key ?: recordId, objectTitle ]
			  )
		} );
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
	}

	private void function _validateAggregateConfig( event, rc, prc, args={} ) {
		var formData         = args.formData         ?: {};
		var validationResult = args.validationResult ?: "";
		var kind             = prc.record.kind ?: ( formData.kind ?: "" );
		var targetObject     = Len( Trim( formData.target_object ?: "" ) ) ? formData.target_object : ( prc.record.target_object ?: "" );

		if ( kind != "aggregate" || !IsObject( validationResult ) ) {
			return;
		}

		if ( !customFieldsService.objectHasAggregateRelationships( targetObject ) ) {
			validationResult.addError( fieldName="aggregate_property", message="customFields:validation.aggregate.no.relationships" );
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

	private void function _validateRelatedDataConfig( event, rc, prc, args={} ) {
		var formData         = args.formData         ?: {};
		var validationResult = args.validationResult ?: "";
		var kind             = prc.record.kind ?: ( formData.kind ?: "" );
		var targetObject     = Len( Trim( formData.target_object ?: "" ) ) ? formData.target_object : ( prc.record.target_object ?: "" );

		if ( kind != "related_data" || !IsObject( validationResult ) ) {
			return;
		}

		if ( !customFieldsService.objectHasRelatedDataRelationships( targetObject ) ) {
			validationResult.addError( fieldName="related_data_relationship", message="customFields:validation.related_data.no.relationships" );
			return;
		}

		var relationshipPath = Trim( formData.related_data_relationship ?: "" );
		var propertyName     = Trim( formData.related_data_property     ?: "" );

		if ( !Len( relationshipPath ) || !Len( propertyName ) ) {
			validationResult.addError( fieldName="related_data_relationship", message="customFields:validation.related_data.invalid.path" );
		} else {
			var resolved = customFieldsService.resolveRelatedDataPath(
				  objectName       = targetObject
				, relationshipPath = relationshipPath
				, propertyName     = propertyName
			);
			if ( !IsTrue( resolved.valid ?: false ) ) {
				validationResult.addError( fieldName="related_data_relationship", message="customFields:validation.related_data.invalid.path" );
			} else {
				formData.data_type      = resolved.dataType ?: "";
				formData.batch_editable = false;
			}
		}
	}

	private void function _serialiseDisplayConfig( event, rc, prc, args={} ) {
		var record      = _getViewRecord( argumentCollection=arguments );
		var dataType    = record.data_type ?: "";
		var displayForm = _getDisplayFormName( record.kind ?: "", dataType );

		if ( !Len( displayForm ) ) {
			return;
		}

		args.formData = args.formData ?: {};
		args.formData.type_config = customFieldTypesService.buildTypeConfig(
			  dataType = dataType
			, formData = event.getCollectionForForm( displayForm )
		);
	}

	private void function _validateDisplayConfig( event, rc, prc, args={} ) {
		var formData         = args.formData         ?: {};
		var validationResult = args.validationResult ?: "";
		var record           = _getViewRecord( argumentCollection=arguments );
		var dataType         = Len( Trim( formData.data_type ?: "" ) ) ? formData.data_type : ( record.data_type ?: "" );
		var kind             = Len( Trim( formData.kind      ?: "" ) ) ? formData.kind      : ( record.kind      ?: "" );

		if ( !IsObject( validationResult ) || !Len( _getDisplayFormName( kind, dataType ) ) ) {
			return;
		}

		var group = customFieldTypesService.getDisplayGroup( dataType );

		if ( group == "number" ) {
			var places = Trim( formData.decimalPlaces ?: "" );
			var maximum = customFieldTypesService.getMaxDecimalPlaces();

			if ( Len( places ) && ( !IsNumeric( places ) || Val( places ) != Int( Val( places ) ) || Val( places ) < 0 || Val( places ) > maximum ) ) {
				validationResult.addError( fieldName="decimalPlaces", message="customFields:validation.display.decimal.places", params=[ maximum ] );
			}
		}

		if ( group == "boolean" && ( formData.booleanDisplay ?: "" ) == "customBadge" ) {
			for( var value in [ "true", "false" ] ) {
				if ( !Len( Trim( formData[ "#value#Label" ] ?: "" ) ) && !Len( Trim( formData[ "#value#Colour" ] ?: "" ) ) ) {
					validationResult.addError( fieldName="#value#Label", message="customFields:validation.display.badge.incomplete" );
				}
			}
		}
	}

	private string function _getDisplayFormName( required string kind, required string dataType ) {
		if ( arguments.kind != "static" ) {
			return "";
		}

		var group = customFieldTypesService.getDisplayGroup( arguments.dataType );

		return Len( group ) ? "custom-field-display.#group#" : "";
	}

	private struct function _getViewRecord( event, rc, prc, args={} ) {
		if ( IsStruct( args.record ?: "" ) && !StructIsEmpty( args.record ) ) {
			return args.record;
		}
		if ( IsQuery( prc.record ?: "" ) && prc.record.recordCount ) {
			return QueryRowToStruct( prc.record );
		}
		if ( IsStruct( prc.record ?: "" ) ) {
			return prc.record;
		}

		return {};
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

	private void function _normaliseFormPlacement( event, rc, prc, args={} ) {
		if ( ( prc.record.kind ?: "" ) != "static" ) {
			return;
		}

		var prepared = customFieldsService.prepareFormPlacement(
			  formData  = args.formData ?: {}
			, catalogue = customFieldsService.getFormPlacementCatalogue( prc.record.target_object ?: "" )
		);

		if ( Len( prepared.error ?: "" ) ) {
			args.validationResult.addError( fieldName=prepared.errorField, message=prepared.error );
			return;
		}

		args.formData.include_in_add_form  = prepared.include_in_add_form;
		args.formData.include_in_edit_form = prepared.include_in_edit_form;
		args.formData.form_placement       = prepared.form_placement;
		args.formData.form_tab             = prepared.form_tab;
		args.formData.form_tab_label       = prepared.form_tab_label;
		args.formData.form_fieldset        = prepared.form_fieldset;
		args.formData.form_fieldset_label  = prepared.form_fieldset_label;
	}

}
