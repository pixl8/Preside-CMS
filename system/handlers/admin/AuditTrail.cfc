component extends="preside.system.base.AdminHandler" {

	property name="auditService" inject="auditService";

	public void function preHandler( event ) {
		super.preHandler( argumentCollection = arguments );

		_permissionsCheck( "navigate", event );

		prc.pageIcon = "fa-history";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:auditTrail.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo = "auditTrail" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.logs          = auditService.getTrail( 1, 10 );

		prc.pageTitle     = translateResource( "cms:auditTrail.page.title" );
		prc.pageSubTitle  = translateResource( "cms:auditTrail.page.subtitle" );
	}

	public any function loadMore( event, rc, prc ) {
		var page = Val( rc.page ?: 2 );
		var args = { logs = auditService.getTrail( page, 10 ) };
		var logs = renderView( view="/admin/audittrail/_logs", args=args );

		event.renderData( data=logs, type="html" );
	}

	// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "auditTrail." & arguments.key;
		var permitted = hasCmsPermission( permissionKey = permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

}