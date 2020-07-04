component extends="preside.system.base.AdminHandler" {

	public void function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection=arguments );

		prc.pageIcon = "download";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:savedreport.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="savedreport" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:savedreport.page.title"    );
		prc.pageSubTitle = translateResource( "cms:savedreport.page.subtitle" );
	}
}