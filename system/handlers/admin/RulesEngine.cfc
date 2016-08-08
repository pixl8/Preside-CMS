component extends="preside.system.base.AdminHandler" {


	function preHandler() {
		super.preHandler( argumentCollection=arguments );

		if ( !isFeatureEnabled( "rulesEngine" ) ) {
			event.notFound();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:rulesEngine.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="rulesengine" )
		);

		_checkPermissions( argumentCollection=arguments, key="navigate" );
	}

	public void function index( event, rc, prc ) {
		prc.pageIcon     = translateResource( "cms:rulesEngine.iconClass" );
		prc.pageTitle    = translateResource( "cms:rulesEngine.page.title" );
		prc.pageSubTitle = translateResource( "cms:rulesEngine.page.subtitle" );
	}

// PRIVATE HELPERS
	private void function _checkPermissions( event, rc, prc, required string key ) {
		var permKey = "rulesEngine." & arguments.key;

		if ( !hasCmsPermission( permissionKey=permKey ) ) {
			event.adminAccessDenied();
		}
	}
}