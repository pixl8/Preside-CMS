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
		prc.logs         = getModel( "AuditService" ).getAuditLog(1,10);
		prc.pageTitle    = translateResource( "cms:auditTrail.page.title" );
		prc.pageSubTitle = translateResource( "cms:auditTrail.page.subtitle" );
	}

	public any function loadMore(event, rc, prc) output=false {
		prc.logs         = getModel( "AuditService" ).getAuditLog(rc.start,10);
		event.noLayout();
	}

	// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "auditTrail." & arguments.key;
		var permitted = hasCmsPermission( permissionKey=permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

	public void function viewAuditTrail( event, rc, prc ) {
		prc.auditTrail = getModel( "AuditService" ).getAuditTrail( rc.id ?: "" );

		if ( !prc.auditTrail.recordCount ) {
			event.adminNotFound();
		}
		event.nolayout();
	}
}