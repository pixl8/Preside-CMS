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


// VIEWLETS, ETC
	private string function _generalSettingsTabs( event, rc, prc, args={} ) {
		if ( hasCmsPermission( "emailCenter.serviceProviders.navigate" ) ) {
			args.providers = emailServiceProviderService.listProviders();
		}

		return renderView( view="/admin/emailCenter/settings/_generalSettingsTabs", args=args );
	}

// HELPERS
	private void function _checkPermissions( required any event, required string key ) {
		if ( !hasCmsPermission( "emailCenter.settings." & arguments.key ) ) {
			event.adminAccessDenied();
		}
	}
}