component extends="preside.system.base.AdminHandler" output=false {

	public void function preHandler( event ) output=false {
		super.preHandler( argumentCollection=arguments );

		_permissionsCheck( "navigate", event );

		prc.pageIcon = "fa-history";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:auditTrail.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="auditTrail" )
		);
	}

	public void function index( event, rc, prc ) output=false {
		param type="numeric" default=1 name="rc.start";

		prc.logs         = getModel( "AuditService" ).getAuditLog();
		prc.perpage      = 10;
		prc.start        = rc.start;
		prc.totalPages   = ceiling( prc.logs.recordCount / prc.perpage );
		prc.thisPage     = ceiling( prc.start / prc.perpage );
		prc.pageTitle    = translateResource( "cms:auditTrail.page.title" );
		prc.pageSubTitle = translateResource( "cms:auditTrail.page.subtitle" );
	}

	// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "auditTrail." & arguments.key;
		var permitted = hasCmsPermission( permissionKey=permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}
}