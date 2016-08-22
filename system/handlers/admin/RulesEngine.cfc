component extends="preside.system.base.AdminHandler" {

	property name="rulesEngineConditionService" inject="rulesEngineConditionService";

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

		prc.contexts     = rulesEngineConditionService.listContexts();
	}

	public void function addCondition( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="add" );

		var contextId = rc.context ?: "";
		var contexts  = rulesEngineConditionService.listContexts();

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

// PRIVATE HELPERS
	private void function _checkPermissions( event, rc, prc, required string key ) {
		var permKey = "rulesEngine." & arguments.key;

		if ( !hasCmsPermission( permissionKey=permKey ) ) {
			event.adminAccessDenied();
		}
	}
}