component extends="preside.system.base.AdminHandler" {

	property name="emailServiceProviderService" inject="emailServiceProviderService";
	property name="messagebox"                  inject="coldbox:plugin:messagebox";

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		if ( !hasCmsPermission( "emailcenter.settings.navigate" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.settings.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="emailcenter.settings" )
		);

		event.setValue( "pageIcon", "envelope", true );
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.settings.page.title"    );
		prc.pageSubTitle = translateResource( "cms:emailcenter.settings.page.subTitle" );
	}

}