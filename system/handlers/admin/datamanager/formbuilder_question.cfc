component extends="preside.system.base.AdminHandler" {

	property name="datamanagerService"          inject="datamanagerService";
	property name="formBuilderItemTypesService" inject="formBuilderItemTypesService";
	property name="validationEngine"            inject="validationEngine";
	property name="formsService"                inject="formsService";
	property name="messageBox"                  inject="messagebox@cbmessagebox";
	property name="presideObjectService"        inject="presideObjectService";

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

	public string function getRelatedFormRecordsForAjaxDatatable( event, rc, prc, args={} ) {
		var recordId       = rc.recordId     ?: "";
		var objectName     = rc.objectName   ?: "formbuilder_question";
		var propertyName   = rc.propertyName ?: "forms";
		var extraFilters   = [];
		var subquerySelect = presideObjectService.selectData(
			  objectName          = objectName
			, id                  = recordId
			, selectFields        = [ "#propertyName#.id as id" ]
			, getSqlAndParamsOnly = true
		);
		var subQueryAlias = "relatedRecordsFilter";
		var params        = {};

		for( var param in subquerySelect.params ) { params[ param.name ] = param; }

		extraFilters.append( {
			filter="1=1", filterParams=params, extraJoins=[ {
				  type           = "inner"
				, subQuery       = subquerySelect.sql
				, subQueryAlias  = subQueryAlias
				, subQueryColumn = "id"
				, joinToTable    = "formbuilder_form"
				, joinToColumn   = "id"
			} ]
		} );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = "formbuilder_form"
				, gridFields      = "name"
				, extraFilters    = extraFilters
				, useMultiActions = false
				, isMultilingual  = false
				, draftsEnabled   = false
				, useCache        = false
				, actionsView     = "admin.datamanager.formbuilder_question.formGridActions"
			}
		);
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

// VIEWLETS
	private string function formGridActions( event, rc, prc, args ) {
		args.editRecordLink = event.buildAdminLink( linkTo="formbuilder.manageForm" , queryString="id=" & args.id );
		return renderView( view="/admin/datamanager/formbuilder_question/_formGridActions", args=args );
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

