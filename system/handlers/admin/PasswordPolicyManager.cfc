component extends="preside.system.base.AdminHandler" {

	property name="passwordPolicyService" inject="passwordPolicyService";

// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) {
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
	function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:passwordPolicyManager.page.title" );
		prc.pageSubTitle = translateResource( "cms:passwordPolicyManager.page.subtitle" );

		prc.policyContexts = passwordPolicyService.listContexts();
		prc.currentContext = rc.context ?: "cms";

		if ( !prc.policyContexts.findNoCase( prc.currentContext ) ) {
			setNextEvent( url=event.buildAdminLink( linkto="passwordPolicyManager" ) );
		}

		prc.savedPolicy = passwordPolicyService.getPolicy( prc.currentContext );

		event.setView( "/admin/passwordPolicyManager/index" );
	}

	function downloadIsComplete( event, rc, prc ) output=false {
		event.renderData( data={ complete=updateManagerService.downloadIsComplete( rc.version ?: "" ) }, type="json" );
	}

}