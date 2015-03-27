component extends="preside.system.base.AdminHandler" output=false {

	public void function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !hasCmsPermission( "maintenanceMode.configure" ) ) {
			event.adminAccessDenied();
		}

		prc.pageIcon = "medkit";

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:maintenanceMode" )
			, link  = event.buildAdminLink( linkTo="maintenanceMode" )
		);
	}

	function index( event, rc, prc ) output=false {
		prc.pageTitle = translateResource( "cms:maintenanceMode" );
	}

}