component extends="preside.system.base.AdminHandler" {

	property name="rulesEngineContextService"   inject="rulesEngineContextService";
	property name="rulesEngineConditionService" inject="rulesEngineConditionService";
	property name="rulesEngineFieldTypeService" inject="rulesEngineFieldTypeService";
	property name="rulesEngineFilterService"    inject="rulesEngineFilterService";
	property name="dataManagerService"          inject="dataManagerService";
	property name="messageBox"                  inject="messagebox@cbmessagebox";
	property name="presideObjectService"        inject="PresideObjectService";

	function preHandler() {
		super.preHandler( argumentCollection=arguments );

		if ( !isFeatureEnabled( "rulesEngine" ) ) {
			event.notFound();
		}

		prc.pageIcon = translateResource( "cms:rulesEngine.iconClass" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:rulesEngine.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="rulesengine" )
		);

		_checkPermissions( argumentCollection=arguments, key="navigate" );
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:rulesEngine.page.title" );
		prc.pageSubTitle = translateResource( "cms:rulesEngine.page.subtitle" );

		prc.contexts     = rulesEngineContextService.listContexts();
		prc.gridFields   = ListToArray( presideObjectService.getObjectAttribute( objectName="rules_engine_condition", attributeName="dataManagerGridFields", defaultValue="condition_name,context,filter_object,datemodified" ) );
	}

	public void function addCondition( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="add" );

		var contextId = rc.context ?: "";
		var contexts  = rulesEngineContextService.listContexts();

		for( var context in contexts ) {
			if ( context.id == contextId ) {
				prc.context = context;
				break;
			}
		}

		if ( !IsStruct( prc.context ?: "" ) ) {
			event.notFound();
		}

		prc.pageTitle    = translateResource( uri="cms:rulesEngine.add.condition.page.title", data=[ prc.context.title, prc.context.description ] );
		prc.pageSubTitle = translateResource( uri="cms:rulesEngine.add.condition.page.subtitle", data=[ prc.context.title, prc.context.description ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:rulesEngine.add.condition.breadcrumb.title", data=[ prc.context.title, prc.context.description ] )
			, link  = event.buildAdminLink( linkTo="rulesengine.addCondition", queryString="context=" & contextId )
		);

	}

	public void function addConditionAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="add" );
		var object   = "rules_engine_condition";
		var formName = "preside-objects.#object#.admin.add";
		var formData = event.getCollectionForForm( formName );

		formData._addAnother = rc._addAnother ?: 0;
		formData.context     = rc.context     ?: "";

		_conditionToFilterCheck( argumentCollection=arguments, action="add", formData=formData );

		if ( ( rc.convertAction ?: "" ) == "filter" && ( rc.filter_object ?: "" ).len() ) {
			rc.context = "";

			formName = "preside-objects.#object#.admin.add.filter";
		} else {
			rc.filter_object = "";
		}

		var newId    = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object            = object
				, errorUrl          = event.buildAdminLink( "rulesEngine.addCondition" )
				, formName          = formName
				, redirectOnSuccess = false
				, audit             = true
				, auditType         = "rulesEngine"
				, auditAction       = "add_rules_engine_condition"
			}
		);

		var newRecordLink = event.buildAdminLink( linkTo="rulesEngine.editCondition", queryString="object=#object#&id=#newId#" );

		messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[ translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ) , '<a href="#newRecordLink#">#( rc.condition_name ?: '' )#</a>'
		] ) );

		if ( Val( rc._addanother ?: 0 ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="rulesEngine.addCondition", queryString="context=#rc.context#" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="rulesEngine" ) );
		}
	}

	public void function editCondition( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="edit" );

		var id = rc.id ?: "";


		prc.record = rulesEngineConditionService.getConditionRecord( id );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:rulesEngine.condition.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="rulesEngine" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		rc.context = prc.record.context;
		rc.filter_object = prc.record.filter_object;

		if ( Len( Trim( rc.filter_object ) ) ) {
			prc.pageTitle    = translateResource( uri="cms:rulesEngine.edit.filter.page.title", data=[ prc.record.condition_name ] );
			prc.pageSubTitle = translateResource( uri="cms:rulesEngine.edit.filter.page.subtitle", data=[ prc.record.condition_name ] );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:rulesEngine.edit.filter.breadcrumb.title", data=[ prc.record.condition_name ] )
				, link  = event.buildAdminLink( linkTo="rulesengine.editCondition", queryString="id=" & id )
			);

		} else {
			prc.pageTitle    = translateResource( uri="cms:rulesEngine.edit.condition.page.title", data=[ prc.record.condition_name ] );
			prc.pageSubTitle = translateResource( uri="cms:rulesEngine.edit.condition.page.subtitle", data=[ prc.record.condition_name ] );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:rulesEngine.edit.condition.breadcrumb.title", data=[ prc.record.condition_name ] )
				, link  = event.buildAdminLink( linkTo="rulesengine.editCondition", queryString="id=" & id )
			);
		}
	}

	public void function editConditionAction( event, rc, prc ) {
		var conditionId = rc.id ?: "";
		var object   = "rules_engine_condition";
		var formName = "preside-objects.#object#.admin.edit";
		var formData = event.getCollectionForForm( formName );

		_checkPermissions( argumentCollection=arguments, key="edit" );

		_conditionToFilterCheck( argumentCollection=arguments, action="edit", formData=formData );
		if ( ( rc.convertAction ?: "" ) == "filter" && ( rc.filter_object ?: "" ).len() ) {
			rc.context = "";

			formName = "preside-objects.#object#.admin.edit.filter";
		} else if ( Len( Trim( rc.context ?: "" ) ) ) {
			rc.filter_object = "";
		}

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object        = "rules_engine_condition"
				, errorUrl      = event.buildAdminLink( linkTo="rulesEngine.editCondition", queryString="id=" & conditionId )
				, successAction = "rulesEngine"
				, formName      = formName
				, audit         = true
				, auditType     = "rulesEngine"
				, auditAction   = "edit_rules_engine_condition"
			}
		);
	}

	public void function convertConditionToFilter( event, rc, prc ) {
		var action        = rc.saveAction ?: "";
		var permissionKey = "";

		switch( action ) {
			case "quickadd":
			case "add":
				permissionKey = "add";
			break;
			case "edit":
			case "quickedit":
				permissionKey = "edit";
			break;
			default:
				event.notFound();
		}
		_checkPermissions( argumentCollection=arguments, key=permissionKey );

		switch( action ) {
			case "add":
				prc.submitAction = event.buildAdminLink( "rulesEngine.addConditionAction" );
			break;
			case "edit":
				prc.submitAction = event.buildAdminLink( "rulesEngine.editConditionAction" );
			break;
		}


		if ( permissionKey == "edit" ) {
			var id = rc.id ?: "";
			prc.record = rulesEngineConditionService.getConditionRecord( id );

			if ( !prc.record.recordCount ) {
				messageBox.error( translateResource( uri="cms:rulesEngine.condition.not.found.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="rulesEngine" ) );
			}
			prc.record = queryRowToStruct( prc.record );
		}

		var objectsFilterable = rc.objectsFilterable ?: [];
		if ( !IsArray( objectsFilterable ) || !objectsFilterable.len() ) {
			event.notFound();
		}

		prc.pageTitle    = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.page.title" );
		prc.pageSubTitle = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.page.subtitle" );

		var objectName      = renderContent( "objectName", objectsFilterable[ 1 ] );
		prc.pageDescription = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.intro.single.object", data=[ objectName ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.breadcrumb.title" )
			, link  = ""
		);
	}

	function deleteConditionAction( event, rc, prc )  {
		_checkPermissions( argumentCollection=arguments, key="delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object      = "rules_engine_condition"
				, postAction  = "rulesEngine"
				, audit       = true
				, auditType   = "rulesEngine"
				, auditAction = "delete_rules_engine_condition"
			}
		);
	}

	public void function getConditionsForAjaxDataTables( event, rc, prc )  {
		_checkPermissions( argumentCollection=arguments, key="read" );

		var gridFields = presideObjectService.getObjectAttribute( objectName="rules_engine_condition", attributeName="dataManagerGridFields", defaultValue="condition_name,context,filter_object,datemodified" )

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "rules_engine_condition"
				, gridFields  = gridFields
				, actionsView = "/admin/rulesEngine/_conditionsTableActions"
			}
		);
	}

	public string function ajaxRenderField( event, rc, prc ) {
		var fieldConfig = event.getCollectionWithoutSystemVars();
		var fieldValue  = rc.fieldValue ?: "";
		var fieldType   = rc.fieldType  ?: "";

		fieldConfig.delete( "fieldValue" );
		fieldConfig.delete( "fieldType"  );

		return rulesEngineFieldTypeService.renderConfiguredField(
			  fieldType          = fieldType
			, value              = fieldValue
			, fieldConfiguration = fieldConfig
		);
	}

	public string function editFieldModal( event, rc, prc ) {
		var fieldConfig = event.getCollectionWithoutSystemVars();
		var fieldValue  = rc.fieldValue ?: "";
		var fieldType   = rc.fieldType  ?: "";

		fieldConfig.delete( "fieldValue" );
		fieldConfig.delete( "fieldType"  );

		prc.configScreen = rulesEngineFieldTypeService.renderConfigScreen(
			  fieldType          = fieldType
			, currentValue       = fieldValue
			, fieldConfiguration = fieldConfig
		);

		event.setLayout( "adminModalDialog" );
	}

	public void function editFieldModalAction() {
		// TODO: this is the most basic implementation - needs to be more involved here (field types should have ability to validate and process their own submissions)
		event.renderData( type="json", data={
			  success = true
			, value   = ( rc.value ?: "" )
		} );
	}

	public void function getConditionsForAjaxSelectControl() {
		var context                = rc.context ?: "";
		var validContexts          = rulesEngineContextService.listValidExpressionContextsForParentContexts( [ context ] );
		var contextAndObjectFilter = {
			  filter       = "rules_engine_condition.context in ( :rules_engine_condition.context )"
			, filterParams = { "rules_engine_condition.context" = validContexts }
		};

		var validFilterObjects = [];
		for( var validContext in validContexts ) {
			var filterObject = rulesEngineContextService.getContextObject( validContext );
			if ( filterObject.len() ) {
				validFilterObjects.append( filterObject );
			}
		}
		if ( validFilterObjects.len() ) {
			contextAndObjectFilter.filter &= " or rules_engine_condition.filter_object in ( :rules_engine_condition.filter_object )"
			contextAndObjectFilter.filterParams[ "rules_engine_condition.filter_object" ] = validFilterObjects;
		}

		var records       = dataManagerService.getRecordsForAjaxSelect(
			  objectName   = "rules_engine_condition"
			, maxRows      = rc.maxRows ?: 1000
			, searchQuery  = rc.q       ?: ""
			, extraFilters = [ contextAndObjectFilter ]
			, ids          = ListToArray( rc.values ?: "" )
		);

		event.renderData( type="json", data=records );
	}

	public void function getFiltersForAjaxSelectControl() {
		var filterObject  = rc.filterObject ?: "";
		var records       = dataManagerService.getRecordsForAjaxSelect(
			  objectName   = "rules_engine_condition"
			, maxRows      = rc.maxRows ?: 1000
			, searchQuery  = rc.q       ?: ""
			, extraFilters = [ { filter={ "rules_engine_condition.filter_object" = filterObject } } ]
			, ids          = ListToArray( rc.values ?: "" )
		);

		event.renderData( type="json", data=records );
	}


	public void function getFilterCount( event, rc, prc ) {
		var objectName            = rc.objectName ?: "";
		var preSavedFilters       = ListToArray( rc.preSavedFilters ?: "" );
		var preRulesEngineFilters = ListToArray( rc.preRulesEngineFilters ?: "" );
		var extraFilters          = [];
		var expressionArray       = "";
		var count                 = 0;

		try {
			expressionArray = DeSerializeJson( rc.condition ?: "" );
		} catch ( any e ) {}

		if ( !IsArray( expressionArray ) ) {
			expressionArray = [];
		}

		for( var filterId in preRulesEngineFilters ) {
			extraFilters.append( rulesEngineFilterService.prepareFilter(
				  objectName = objectName
				, filterId   = filterId
			) );
		}

		if ( objectName.len() ) {
			try {
				var count = rulesEngineFilterService.getMatchingRecordCount(
					  objectName      = objectName
					, expressionArray = expressionArray
					, savedFilters    = preSavedFilters
					, extraFilters    = extraFilters
				);
			} catch ( any e ) {}
		}

		event.renderData( data=NumberFormat( count ), type="text" );
	}

	public void function quickAddConditionForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		prc.contextData  = {};

		try {
			prc.contextData = DeSerializeJson( rc.contextData ?: "" );
			if ( !IsStruct( prc.contextData ) ) {
				prc.contextData = {};
			}
		} catch( any e ) {}

		event.setView( view="/admin/rulesEngine/quickAddConditionForm", layout="adminModalDialog" );
	}

	public void function quickEditConditionForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";

		prc.record = rulesEngineConditionService.getConditionRecord( rc.id ?: "" );
		if ( prc.record.recordCount ) {
			prc.record       = queryRowToStruct( prc.record );
			rc.context       = prc.record.context;
			rc.filter_object = prc.record.filter_object;

			if ( Len( Trim( rc.filter_object ?: "" ) ) ) {
				event.setView( view="/admin/rulesEngine/quickEditConditionForm", layout="adminModalDialog" );
			} else {
				event.setView( view="/admin/rulesEngine/quickEditConditionForm", layout="adminModalDialog" );
			}
		} else {
			prc.record = {};
			event.setView( view="/admin/rulesEngine/quickEditConditionForm", layout="adminModalDialog" );
		}
	}

	public void function quickAddConditionAction( event, rc, prc ) {
		var object   = "rules_engine_condition";
		var formName = "preside-objects.#object#.admin.quickadd";
		var formData = event.getCollectionForForm( formName );

		_checkPermissions( argumentCollection=arguments, key="add" );

		if ( !_conditionToFilterCheck( argumentCollection=arguments, action="quickadd", formData=formData, ajax=true ) ) {
			if ( ( rc.convertAction ?: "" ) == "filter" && ( rc.filter_object ?: "" ).len() ) {
				rc.context = "";

				formName = "preside-objects.#object#.admin.quickadd.filter";
			} else {
				rc.filter_object = "";
			}
			runEvent(
				  event          = "admin.DataManager._quickAddRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object         = "rules_engine_condition"
					, formName       = formName
				  }
			);
		}
	}

	public void function quickEditConditionAction( event, rc, prc ) {
		var object      = "rules_engine_condition";
		var formName    = "preside-objects.#object#.admin.quickedit";
		var formData    = event.getCollectionForForm( formName );
		var conditionId = rc.id ?: "";
		var record      = rulesEngineConditionService.getConditionRecord( conditionId );

		_checkPermissions( argumentCollection=arguments, key="edit" );
		if ( !record.recordCount ) {
			event.notFound();
		}

		if ( Len( Trim( record.filter_object ) ) || !_conditionToFilterCheck( argumentCollection=arguments, action="quickedit", formData=formData, ajax=true ) ) {
			if ( Len( Trim( record.filter_object ) ) || ( rc.convertAction ?: "" ) == "filter" && ( rc.filter_object ?: "" ).len() ) {
				rc.context = "";

				formName = "preside-objects.#object#.admin.quickedit.filter";
				formName = "preside-objects.#object#.admin.quickedit.filter";
			} else {
				rc.filter_object = "";
			}

			runEvent(
				  event          = "admin.DataManager._quickEditRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object   = "rules_engine_condition"
					, formName = formName
				  }
			);
		}
	}


	public void function quickAddFilterForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		prc.contextData  = {};

		try {
			prc.contextData = DeSerializeJson( rc.contextData ?: "" );
			if ( !IsStruct( prc.contextData ) ) {
				prc.contextData = {};
			}
		} catch( any e ) {}

		event.include( "/js/admin/specific/datamanager/quickAddForm/" );
		event.setView( view="/admin/rulesEngine/quickAddFilterForm", layout="adminModalDialog" );
	}

	public void function quickEditFilterForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		event.include( "/js/admin/specific/datamanager/quickEditForm/" );
		prc.contextData  = {};

		try {
			prc.contextData = DeSerializeJson( rc.contextData ?: "" );
			if ( !IsStruct( prc.contextData ) ) {
				prc.contextData = {};
			}
		} catch( any e ) {}

		prc.record = rulesEngineConditionService.getConditionRecord( rc.id ?: "" );
		if ( prc.record.recordCount ) {
			prc.record = queryRowToStruct( prc.record );
		} else {
			prc.record = {};
		}

		event.setView( view="/admin/rulesEngine/quickEditFilterForm", layout="adminModalDialog" );
	}

	public void function superQuickAddFilterForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		event.include( "/js/admin/specific/datamanager/quickAddForm/" );
		event.setView( view="/admin/rulesEngine/superQuickAddFilterForm", layout="adminModalDialog" );
	}

	public void function quickAddFilterAction( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._quickAddRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object         = "rules_engine_condition"
				, formName       = "preside-objects.rules_engine_condition.admin.quickadd.filter"
			  }
		);
	}

	public void function quickEditFilterAction( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._quickEditRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object         = "rules_engine_condition"
				, formName       = "preside-objects.rules_engine_condition.admin.quickedit.filter"
			  }
		);
	}

	public void function superQuickAddFilterAction( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._quickAddRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object         = "rules_engine_condition"
				, formName       = "preside-objects.rules_engine_condition.admin.superquickaddfilter"
			  }
		);
	}

	public void function ajaxDataGridFavourites( event, rc, prc ) {
		event.renderData( type="html", data=renderViewlet( event="admin.rulesengine.dataGridFavourites", args={
			objectName = rc.objectName ?: ""
		} ) );
	}

// VIWLETS
	private string function dataGridFavourites( event, rc, prc, args ) {
		var objectName = args.objectName ?: "";

		args.favourites = rulesEngineFilterService.getFavourites( objectName );

		return renderView( view="/admin/rulesEngine/_dataGridFavourites", args=args );
	}


// PRIVATE HELPERS
	private void function _checkPermissions( event, rc, prc, required string key ) {
		var permKey = "rulesEngine." & arguments.key;

		if ( !hasCmsPermission( permissionKey=permKey ) ) {
			event.adminAccessDenied();
		}
	}

	private boolean function _conditionToFilterCheck( event, rc, prc, required string action, required struct formData, boolean ajax=false ) {
		if( Len( Trim( rc.convertAction ?: "" ) ) || Len( Trim( rc.filter_object ?: "" ) ) ) {
			return false;
		}

		try {
			var expressionArray = DeSerializeJson( formData.expressions ?: "" );
		} catch( any e ){
			return false;
		}

		if ( !isArray( expressionArray ) ) {
			return false;
		}
		var objectsFilterable = rulesEngineConditionService.listObjectsFilterableByCondition( expressionArray );

		if ( objectsFilterable.len() == 1 ) {
			if ( arguments.ajax ) {
				var objectName      = renderContent( "objectName", objectsFilterable[ 1 ] );
				var response = { success=false, convertPrompt=renderView( view="/admin/rulesEngine/convertConditionToFilter", args={
					  id                = rc.id ?: ""
					, formData          = arguments.formData
					, objectsFilterable = objectsFilterable
					, saveAction        = arguments.action
					, submitAction      = event.buildAdminLink( linkto="rulesEngine.#arguments.action#ConditionAction" )
					, pageDescription   = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.intro.single.object", data=[ objectName ] )
				} ) };

				event.renderData( data=response, type="json" );

				return true;
			} else {
				var persist = {
					  formData          = arguments.formData
					, objectsFilterable = objectsFilterable
					, saveAction        = arguments.action
					, id                = rc.id ?: ""
				}
				setNextEvent( url=event.buildAdminLink( linkto="rulesEngine.convertConditionToFilter" ), persistStruct=persist );
			}
		}

		return false;
	}
}