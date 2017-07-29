component extends="preside.system.base.AdminHandler" {

	property name="presideRestService" inject="presideRestService";

	public void function preHandler( event ) {
		super.preHandler( argumentCollection = arguments );

		_permissionsCheck( "navigate", event );

		prc.pageIcon = "fa-code";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:apiManager.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo = "apimanager" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.apis = presideRestService.listApis();

		prc.pageTitle    = translateResource( "cms:apiManager.page.title" );
		prc.pageSubTitle = translateResource( "cms:apiManager.page.subtitle" );
	}

	// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "apiManager." & arguments.key;
		var permitted = hasCmsPermission( permissionKey = permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

}