/**
 * @feature admin and customObjects
 */
component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="customObjectsService"         inject="customObjectsService";
	property name="customFieldsService"          inject="customFieldsService";
	property name="customFieldsPropertyInjector" inject="customFieldsPropertyInjector";
	property name="presideObjectService"         inject="presideObjectService";

	variables.permissionBase        = "customobjects";
	variables.deleteConfirmFormName = "preside-objects.custom_object.admin.delete.confirm";
	variables.infoCardStyle         = "definitionList";
	variables.infoCol1              = [ "label", "label_singular", "key" ];
	variables.infoCol2              = [ "category", "has_label_field", "label_field", "active" ];
	variables.infoCol3              = [ "description" ];
	variables.tabs                  = [ "fields" ];

	private void function preAddRecordAction( event, rc, prc, args={} ) {
		args.formData.key = LCase( Trim( args.formData.key ?: "" ) );
		if ( !StructKeyExists( args.formData, "active" ) ) {
			args.formData.active = true;
		}

		if ( !Len( Trim( args.formData.label_field ?: "" ) ) ) {
			args.formData.label_field = _formHasLabelField( args.formData ) ? "label" : "";
		}

		_validateKey( argumentCollection=arguments, ignoreObjectName="" );
		_validateLabelField( argumentCollection=arguments, objectName=customObjectsService.getObjectName( args.formData.key ?: "" ) );
	}

	private void function postAddRecordAction( event, rc, prc, args={} ) {
		if ( Len( Trim( args.newId ?: "" ) ) ) {
			customObjectsService.refreshDefinition( args.newId );
		}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		var existingKey = "";

		if ( IsQuery( args.existingRecord ?: "" ) && args.existingRecord.recordCount ) {
			existingKey = args.existingRecord.key ?: "";
		}

		args.formData.key = existingKey;
		_validateKey( argumentCollection=arguments, ignoreObjectName=customObjectsService.getObjectName( existingKey ) );
		_validateLabelField( argumentCollection=arguments, objectName=customObjectsService.getObjectName( existingKey ) );
	}

	private void function postEditRecordAction( event, rc, prc, args={} ) {
		var recordId = Trim( rc.id ?: "" );

		if ( Len( recordId ) ) {
			customObjectsService.refreshDefinition( recordId );
		}
	}

	private void function preDeleteRecordAction( event, rc, prc, args={} ) {
		var recordId = Trim( rc.id ?: "" );

		if ( !Len( recordId ) || ListLen( recordId ) != 1 ) {
			messageBox.error( translateResource( uri="preside-objects.custom_object:delete.confirmation.mismatch" ) );
			setNextEvent( url=event.buildAdminLink( objectName="custom_object" ) );
		}

		var definition = customObjectsService.getDefinition( recordId );
		if ( StructIsEmpty( definition ) ) {
			return;
		}

		var confirmUrl = event.buildAdminLink( linkTo="datamanager.custom_object.confirmDelete", queryString="id=#recordId#" );
		if ( !StructKeyExists( rc, "confirmation_name" ) ) {
			setNextEvent( url=confirmUrl );
		}

		var formData         = event.getCollectionForForm( variables.deleteConfirmFormName );
		var validationResult = validateForm( formName=variables.deleteConfirmFormName, formData=formData );

		if ( validationResult.validated() && !customObjectsService.deletionConfirmationMatches( definition, formData.confirmation_name ?: "" ) ) {
			validationResult.addError( fieldName="confirmation_name", message="preside-objects.custom_object:delete.confirmation.mismatch" );
		}
		if ( !validationResult.validated() ) {
			setNextEvent( url=confirmUrl, persistStruct={ validationResult=validationResult } );
		}

		customObjectsService.removeDefinition( definition );
	}

	public void function confirmDelete( event, rc, prc ) {
		checkPermission(
			  event = arguments.event
			, rc    = arguments.rc
			, prc   = arguments.prc
			, args  = { key="delete", object="custom_object", throwOnError=true }
		);

		var definition = customObjectsService.getDefinition( Trim( rc.id ?: "" ) );
		if ( StructIsEmpty( definition ) ) {
			event.notFound();
		}

		var objectName = customObjectsService.getObjectName( definition.key ?: "" );
		var objectLabel = Len( Trim( definition.label ?: "" ) ) ? definition.label : ( definition.key ?: "" );

		prc.pageIcon  = "trash";
		prc.pageTitle = translateResource( uri="preside-objects.custom_object:delete.page.title" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.custom_object:title" )
			, link  = event.buildAdminLink( objectName="custom_object" )
		);
		event.addAdminBreadCrumb(
			  title = objectLabel
			, link  = event.buildAdminLink( objectName="custom_object", operation="viewRecord", recordId=definition.id )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.custom_object:delete.breadcrumb" )
			, link  = ""
		);

		event.setView( view="/admin/datamanager/custom_object/confirmDelete" );
		prc.objectLabel  = objectLabel;
		prc.recordCount  = customObjectsService.countRecords( definition.id ?: "" );
		prc.fieldCount   = customObjectsService.countFields( objectName );
		prc.formName     = variables.deleteConfirmFormName;
		prc.deleteAction = event.buildAdminLink( objectName="custom_object", recordId=definition.id, operation="deleteRecordAction" );
		prc.actionButtons = [
			  {
				  type      = "link"
				, href      = event.buildAdminLink( objectName="custom_object", operation="viewRecord", recordId=definition.id )
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
				, label     = translateResource( uri="preside-objects.custom_object:delete.submit.btn" )
			  }
		];
	}

	public void function toggleActiveAction( event, rc, prc ) {
		if ( !hasCmsPermission( "customobjects.edit" ) ) {
			event.adminAccessDenied();
		}

		var recordId   = Trim( rc.id ?: "" );
		var definition = customObjectsService.getDefinition( recordId );

		if ( StructIsEmpty( definition ) ) {
			event.notFound();
		}

		var makeActive = !IsTrue( definition.active ?: "" );

		presideObjectService.updateData(
			  objectName = "custom_object"
			, id         = recordId
			, data       = { active=makeActive }
		);
		customObjectsService.refreshDefinition( recordId );

		messageBox.info( translateResource(
			  uri  = makeActive ? "preside-objects.custom_object:activate.success" : "preside-objects.custom_object:deactivate.success"
			, data = [ definition.label ?: definition.key ?: recordId ]
		) );

		setNextEvent( url=event.buildAdminLink( objectName="custom_object", operation="viewRecord", recordId=recordId ) );
	}

	private string function preViewRecordContent( event, rc, prc, args={} ) {
		var record   = args.record ?: {};
		var recordId = args.recordId ?: ( record.id ?: ( prc.recordId ?: "" ) );
		var isActive = IsTrue( record.active ?: "" );

		return renderView( view="/admin/datamanager/custom_object/_statusBanner", args={
			  active       = isActive
			, toggleLink   = event.buildAdminLink( linkto="datamanager.custom_object.toggleActiveAction", queryString="id=#recordId#" )
			, toggleLabel  = translateResource( uri="preside-objects.custom_object:#isActive ? 'deactivate' : 'activate'#.btn" )
			, togglePrompt = translateResource(
				  uri  = "preside-objects.custom_object:#isActive ? 'deactivate' : 'activate'#.prompt"
				, data = [ record.label ?: record.key ?: recordId ]
			  )
		} );
	}

	private string function _fieldsTab( event, rc, prc, args={} ) {
		var record     = args.record ?: {};
		var objectName = customObjectsService.getObjectName( record.key ?: "" );

		if ( !Len( objectName ) ) {
			return "";
		}

		args.targetObject = objectName;
		args.fieldCount   = customObjectsService.countFields( objectName );

		return renderView( view="/admin/datamanager/custom_object/_fieldsTab", args=args );
	}

	private void function extraTopRightButtonsForViewRecord( event, rc, prc, args={} ) {
		var record = {};

		if ( IsStruct( args.record ?: "" ) && Len( args.record.key ?: "" ) ) {
			record = args.record;
		} else if ( IsQuery( prc.record ?: "" ) && prc.record.recordCount ) {
			record = QueryRowToStruct( prc.record );
		}

		var recordId   = prc.recordId ?: ( record.id ?: ( rc.id ?: "" ) );
		var objectName = customObjectsService.getObjectName( record.key ?: "" );
		var isActive   = IsTrue( record.active ?: "" );

		if ( isActive && Len( record.key ?: "" ) ) {
			ArrayPrepend( args.actions ?: [], {
				  link      = event.buildAdminLink( objectName=objectName )
				, btnClass  = "btn-default"
				, iconClass = "fa-list"
				, title     = translateResource( uri="preside-objects.custom_object:view.records.btn" )
			} );
		}

		_pointDeleteActionAtConfirmation( event, args.actions ?: [], recordId );
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var record   = args.record ?: {};
		var recordId = record.id ?: "";

		_pointDeleteActionAtConfirmation( event, args.actions ?: [], recordId );
	}

	private void function _pointDeleteActionAtConfirmation( required any event, required array actions, required string recordId ) {
		if ( !Len( Trim( arguments.recordId ) ) ) {
			return;
		}

		var confirmLink = event.buildAdminLink( linkTo="datamanager.custom_object.confirmDelete", queryString="id=#arguments.recordId#" );
		var deleteTitle = translateResource( uri="preside-objects.custom_object:delete.btn" );

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

	private string function _infoCardlabel_field( event, rc, prc, args={} ) {
		var record     = args.record ?: {};
		var chosen     = Trim( record.label_field ?: "" );
		var objectName = customObjectsService.getObjectName( record.key ?: "" );

		if ( !Len( chosen ) || IsTrue( record.has_label_field ?: "" ) ) {
			return "";
		}

		for ( var field in customFieldsService.listFields( objectName=objectName, includeInactive=true ) ) {
			if ( Compare( field.key ?: "", chosen ) == 0 ) {
				return EncodeForHtml( field.label ?: chosen );
			}
		}

		return EncodeForHtml( chosen );
	}

	private void function _validateLabelField( event, rc, prc, args={}, string objectName="" ) {
		var validationResult = args.validationResult ?: "";
		if ( !IsObject( validationResult ) ) {
			return;
		}

		var error = customObjectsService.getLabelFieldValidationError(
			  objectName    = arguments.objectName
			, labelField    = args.formData.label_field ?: ""
			, hasLabelField = _formHasLabelField( args.formData ?: {} )
		);

		if ( Len( error ) ) {
			validationResult.addError( fieldName="label_field", message=error );
		}
	}

	private boolean function _formHasLabelField( required struct formData ) {
		var value = arguments.formData.has_label_field ?: "";

		return IsBoolean( value ) && value;
	}

	private void function _validateKey( event, rc, prc, args={}, string ignoreObjectName="" ) {
		var validationResult = args.validationResult ?: "";
		if ( !IsObject( validationResult ) ) {
			return;
		}

		var objectKey = LCase( Trim( args.formData.key ?: "" ) );
		var error     = customObjectsService.getKeyValidationError( objectKey, arguments.ignoreObjectName );

		if ( Len( error ) ) {
			validationResult.addError(
				  fieldName = "key"
				, message   = translateResource( uri=error, data=[ customObjectsService.getObjectName( objectKey ) ] )
			);
		}
	}

}
