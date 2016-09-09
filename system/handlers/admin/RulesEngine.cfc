component extends="preside.system.base.AdminHandler" {

	property name="rulesEngineContextService"   inject="rulesEngineContextService";
	property name="rulesEngineConditionService" inject="rulesEngineConditionService";
	property name="rulesEngineFieldTypeService" inject="rulesEngineFieldTypeService";
	property name="dataManagerService"          inject="dataManagerService";

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

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "rules_engine_condition"
				, errorAction      = "rulesEngine.addCondition"
				, viewRecordAction = "rulesEngine.editCondition"
				, addAnotherAction = "rulesEngine.addCondition"
				, successAction    = "rulesEngine"
				, audit             = true
				, auditType         = "rulesEngine"
				, auditAction       = "add_rules_engine_condition"
			}
		);
	}

	public void function editCondition( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="edit" );

		var id = rc.id ?: "";


		prc.record = rulesEngineConditionService.getConditionRecord( id );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:rulesEngine.condition.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="rulesEngine" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		rc.context = prc.record.context;

		prc.pageTitle    = translateResource( uri="cms:rulesEngine.edit.condition.page.title", data=[ prc.record.condition_name ] );
		prc.pageSubTitle = translateResource( uri="cms:rulesEngine.edit.condition.page.subtitle", data=[ prc.record.condition_name ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:rulesEngine.edit.condition.breadcrumb.title", data=[ prc.record.condition_name ] )
			, link  = event.buildAdminLink( linkTo="rulesengine.editCondition", queryString="id=" & id )
		);

	}

	public void function editConditionAction( event, rc, prc ) {
		var conditionId = rc.id ?: "";
		_checkPermissions( argumentCollection=arguments, key="edit" );

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object        = "rules_engine_condition"
				, errorUrl      = event.buildAdminLink( linkTo="rulesEngine.editCondition", queryString="id=" & conditionId )
				, successUrl    = event.buildAdminLink( linkTo="rulesEngine" )
				, audit         = true
				, auditType     = "rulesEngine"
				, auditAction   = "edit_rules_engine_condition"
			}
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

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "rules_engine_condition"
				, gridFields  = "condition_name,context,datemodified"
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
		var context       = rc.context ?: "";
		var validContexts = rulesEngineContextService.listValidExpressionContextsForParentContexts( [ context ] );
		var records       = dataManagerService.getRecordsForAjaxSelect(
			  objectName   = "rules_engine_condition"
			, maxRows      = rc.maxRows ?: 1000
			, searchQuery  = rc.q       ?: ""
			, extraFilters = [ { filter={ "rules_engine_condition.context" = validContexts } } ]
			, ids          = ListToArray( rc.values ?: "" )
		);

		event.renderData( type="json", data=records );
	}

// PRIVATE HELPERS
	private void function _checkPermissions( event, rc, prc, required string key ) {
		var permKey = "rulesEngine." & arguments.key;

		if ( !hasCmsPermission( permissionKey=permKey ) ) {
			event.adminAccessDenied();
		}
	}
}