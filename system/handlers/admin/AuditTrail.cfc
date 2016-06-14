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
		var dateFrom = rc.dateFrom ?: "";
		var dateTo   = rc.dateTo   ?: "";
		var user     = rc.user     ?: "";
		var recordId = rc.recordId ?: "";
		var action   = rc.action   ?: "";
		var type     = rc.type     ?: "";

		prc.logs = auditService.getTrail(
			  page     = 1
			, pageSize = 10
			, dateFrom = dateFrom
			, dateTo   = dateTo
			, user     = user
			, action   = action
			, type     = type
			, recordId = recordId
		);

		prc.pageTitle    = translateResource( "cms:auditTrail.page.title" );
		prc.pageSubTitle = translateResource( "cms:auditTrail.page.subtitle" );
	}

	public any function loadMore( event, rc, prc ) {
		var dateFrom = rc.dateFrom ?: "";
		var dateTo   = rc.dateTo   ?: "";
		var user     = rc.user     ?: "";
		var action   = rc.action   ?: "";
		var type     = rc.type     ?: "";
		var recordId = rc.recordId ?: "";
		var page     = Val( rc.page ?: 2 );
		var logs     = auditService.getTrail(
			  page     = page
			, pageSize = 10
			, dateFrom = dateFrom
			, dateTo   = dateTo
			, user     = user
			, action   = action
			, type     = type
			, recordId = recordId
		);

		if ( logs.recordCount ) {
			event.renderData( data=renderView( view="/admin/audittrail/_logs", args={ logs=logs } ), type="html" );
		} else {
			event.renderData( data="", type="html" );
		}
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