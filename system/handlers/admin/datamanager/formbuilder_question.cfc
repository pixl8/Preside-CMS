component extends="preside.system.base.AdminHandler" {

	property name="datamanagerService"          inject="datamanagerService";
	property name="formBuilderItemTypesService" inject="formBuilderItemTypesService";
	property name="validationEngine"            inject="validationEngine";
	property name="formsService"                inject="formsService";
	property name="messageBox"                  inject="messagebox@cbmessagebox";

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

	private void function preAddRecordAction( event, rc, prc, args={} ) {
		var itemTypeFormName = _getItemTypeFormAndErrorIfNoItemType( argumentCollection=arguments );

		if ( Len( itemTypeFormName ) ) {
			var itemFields = event.getCollectionForForm( itemTypeFormName );

			args.formData.item_type_config = SerializeJson( itemFields );
		}
	}

// helpers
	private string function _getItemTypeFormAndErrorIfNoItemType( event, rc, prc, args={} ) {
		var itemType = rc.item_type ?: "";

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

