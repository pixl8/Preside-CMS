component extends="preside.system.base.AdminHandler" {

	property name="datamanagerService"          inject="datamanagerService";
	property name="formBuilderItemTypesService" inject="formBuilderItemTypesService";
	property name="formBuilderQuestionService"  inject="formBuilderQuestionService";
	property name="validationEngine"            inject="validationEngine";
	property name="formsService"                inject="formsService";
	property name="messageBox"                  inject="messagebox@cbmessagebox";
	property name="adminDataViewsService"       inject="adminDataViewsService";
	property name="customizationService"        inject="dataManagerCustomizationService";


// CUSTOM PUBLIC PAGES
	public void function addRecordStep1( event, rc, prc ) {
		if ( !hasCmsPermission( "formquestions.add" ) ) {
			event.adminAccessDenied();
		}

		event.initializeDatamanagerPage( objectName="formbuilder_question" );

		var objectTitleSingular = prc.objectTitle ?: "";
		var addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[  objectTitleSingular  ] );

		prc.pageIcon  = "plus";
		prc.pageTitle = addRecordTitle;
		prc.pageSubtitle = translateResource( uri="preside-objects.formbuilder_question:add.question.step1.page.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.addrecord.breadcrumb.title", data=[ objectTitleSingular ] )
			, link  = ""
		);

		prc.cancelLink    = event.buildAdminLink( objectName="formbuilder_question" );
		prc.addRecordLink = event.buildAdminLink( linkto="datamanager.formbuilder_question.addrecordStep1Action" );
		prc.formName      = "preside-objects.formbuilder_question.admin.add.step1";
	}

	public void function addrecordStep1Action( event, rc, prc ) {
		if ( !hasCmsPermission( "formquestions.add" ) ) {
			event.adminAccessDenied();
		}

		var persist = event.getCollectionForForm();
		persist.validationResult = validateForms();

		if ( !persist.validationResult.validated() ) {
			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );

			setNextEvent(
				  url           = event.buildAdminLink( objectName="formbuilder_question", operation="addRecord" )
				, persistStruct = persist
			);
		}

		setNextEvent( url=event.buildAdminLink(
			  linkto      = "datamanager.addRecord"
			, queryString = "object=formbuilder_question&item_type=#( persist.item_type ?: '' )#"
		) );
	}

// DATA MANAGER CUSTOMIZATIONS
	private boolean function checkPermission( event, rc, prc, args={} ) {
		var objectName       = "formbuilder_question";
		var allowedOps       = datamanagerService.getAllowedOperationsForObject( objectName );
		var permissionsBase  = "formquestions"
		var alwaysDisallowed = [ "manageContextPerms" ];
		var operationMapped  = [ "read", "add", "edit", "delete", "clone", "batchdelete", "batchedit" ];
		var permissionKey    = "#permissionsBase#.#( args.key ?: "" )#";
		var hasPermission    = !alwaysDisallowed.find( args.key )
		                    && ( !operationMapped.find( args.key ) || allowedOps.find( args.key ) )
		                    && hasCmsPermission( permissionKey );

		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		switch( args.key ?: "" ) {
			case "delete":
				var recordId  = prc.recordId ?: ( args.recordId ?: ( rc.id ?: "" ) );

				if ( !isEmptyString( recordId ) ) {
					hasPermission = hasPermission && !formBuilderQuestionService.questionIsInUse( questionId=recordId );
				}
				break;
		}

		return hasPermission;
	}

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink(
			  linkTo      = "datamanager.formbuilder_question.addRecordStep1"
			, queryString = args.queryString ?: ""
		);
	}

	private string function getAddRecordFormName( event, rc, prc, args={} ) {
		var baseFormName = "preside-objects.formbuilder_question.admin.add";
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			return formsService.getMergedFormName( baseFormName, itemTypeFormName );
		}

		return baseFormName;
	}

	private string function getQuickAddRecordFormName( event, rc, prc, args={} ) {
		var baseFormName = "preside-objects.formbuilder_question.admin.add";
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			return formsService.getMergedFormName( baseFormName, itemTypeFormName );
		}

		return baseFormName;
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var baseFormName = "preside-objects.formbuilder_question.admin.edit";
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			return formsService.getMergedFormName( baseFormName, itemTypeFormName );
		}

		return baseFormName;
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		args.record = args.record ?: {};

		if ( IsJson( args.record.item_type_config ?: "" ) ) {
			try {
				StructAppend( args.record, DeserializeJson( args.record.item_type_config ) );
			} catch( any e ) {
				logError( e );
			}
		}
	}

	private string function getCloneRecordFormName( event, rc, prc, args={} ) {
		var baseFormName = "preside-objects.formbuilder_question.admin.clone";
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			return formsService.getMergedFormName( baseFormName, itemTypeFormName );
		}

		return baseFormName;
	}

	private string function preRenderCloneRecordForm( event, rc, prc, args={} ) {
		args.cloneableData = args.cloneableData ?: {};

		if ( IsJson( args.cloneableData.item_type_config ?: "" ) ) {
			try {
				StructAppend( args.cloneableData, DeserializeJson( args.cloneableData.item_type_config ) );
			} catch( any e ) {
				logError( e );
			}
		}
	}

	private void function preAddRecordAction( event, rc, prc, args={} ) {
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			var itemFields = event.getCollectionForForm( itemTypeFormName );

			args.formData.item_type_config = SerializeJson( itemFields );
		}
	}

	private void function preQuickAddRecordAction( event, rc, prc, args={} ) {
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			var itemFields = event.getCollectionForForm( itemTypeFormName );

			args.formData.item_type_config = SerializeJson( itemFields );
		}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			var itemFields = event.getCollectionForForm( itemTypeFormName );

			args.formData.item_type_config = SerializeJson( itemFields );
		}
	}

	private void function preCloneRecordAction( event, rc, prc, args={} ) {
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			var itemFields = event.getCollectionForForm( itemTypeFormName );

			args.formData.item_type_config = SerializeJson( itemFields );
		}
	}

	private string function preRenderRecord( event, rc, prc, args={} ) {
		var recordId = prc.recordId ?: ( rc.recordId ?: "" );
		var isInUse  = formBuilderQuestionService.questionIsInUse( questionId=recordId );

		if ( isTrue( isInUse ) ) {
			return renderView( view="/admin/formbuilder/_questionInUseWarning", args=args );
		}

		return "";
	}

	private void function preDeleteRecordAction( event, rc, prc, args={} ) {
		var records = args.records ?: QueryNew('');

		for ( var record in records ) {
			if ( formBuilderQuestionService.questionIsInUse( questionId=record.id ) ) {
				messageBox.error( translateResource( uri="preside-objects.formbuilder_question:multiAction.question.in.use.warning" ) );
				setNextEvent( url=event.buildAdminLink( objectName="formbuilder_question" ) );
			}
		}
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var record     = args.record     ?: {};
		var recordId   = record.id       ?: "";
		var isInUse    = formBuilderQuestionService.questionIsInUse( questionId=recordId );

		if ( isTrue( isInUse ) ) {
			args.actions = args.actions ?: [];

			for ( var action in args.actions ) {
				if ( find( "deleteRecordAction", action.link ?: "" ) ) {
					action.link  = "javascript:void(0)";
					action.class = "disabled";
					action.title = "";
					break;
				}
			}
		}
	}

// helpers
	private string function _getItemTypeFormAndErrorIfNoItemType( event, rc, prc, args={} ) {
		var itemType = rc.item_type ?: ( prc.record.item_type ?: "" );

		if ( !Len( Trim( itemType ) ) ) {
			var persist = event.getCollectionWithoutSystemVars();
			persist.validationResult = validationEngine.newValidationResult();
			persist.validationResult.addError( fieldName="item_type", message="cms:validation.required.default" );

			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );

			setNextEvent(
				  url           = event.buildAdminLink( objectName="formbuilder_question", operation="addRecord" )
				, persistStruct = persist
			);
		}

		itemType = formBuilderItemTypesService.getItemTypeConfig( itemType );
		if ( isTrue( itemType.configFormExists ?: "" ) ) {
			return itemType.baseConfigFormName ?: "";
		}

		return "";
	}
}

