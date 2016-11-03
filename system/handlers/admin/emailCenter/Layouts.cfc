component extends="preside.system.base.AdminHandler" {

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		if ( !hasCmsPermission( "emailcenter.layouts.navigate" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.layouts.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="emailcenter.layouts" )
		);

		event.setValue( "pageIcon", "envelope", true );
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.layouts.page.title"    );
		prc.pageSubTitle = translateResource( "cms:emailcenter.layouts.page.subTitle" );
	}

}