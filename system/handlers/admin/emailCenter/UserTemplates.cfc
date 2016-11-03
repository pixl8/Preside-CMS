component extends="preside.system.base.AdminHandler" {

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		if ( !hasCmsPermission( "emailcenter.userTemplates.navigate" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.userTemplates.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="emailcenter.userTemplates" )
		);

		event.setValue( "pageIcon", "envelope", true );
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.userTemplates.page.title"    );
		prc.pageSubTitle = translateResource( "cms:emailcenter.userTemplates.page.subTitle" );
	}

}