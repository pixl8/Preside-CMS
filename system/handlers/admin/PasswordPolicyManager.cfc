component extends="preside.system.base.AdminHandler" output=false {

// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "passwordPolicyManager" ) ) {
			event.notFound();
		}

		if ( !hasCmsPermission( permissionKey="passwordPolicyManager.manage" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:passwordPolicyManager.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="passwordPolicyManager" )
		);

		prc.pageIcon = "key";
	}

// EVENTS
	function index( event, rc, prc ) output=false {
		prc.pageTitle    = translateResource( "cms:passwordPolicyManager.page.title" );
		prc.pageSubTitle = translateResource( "cms:passwordPolicyManager.page.subtitle" );

		event.setView( "/admin/passwordPolicyManager/index" );
	}

	function downloadIsComplete( event, rc, prc ) output=false {
		event.renderData( data={ complete=updateManagerService.downloadIsComplete( rc.version ?: "" ) }, type="json" );
	}

}