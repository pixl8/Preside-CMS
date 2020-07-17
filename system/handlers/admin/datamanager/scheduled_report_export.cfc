component {
	property name="scheduledReportService" inject="ScheduledReportService";

	private void function rootBreadcrumb( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( "preside-objects.saved_report:title.singular" )
			, link  = event.buildAdminLink( objectName="saved_report" )
		);
	}

	private void function postFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var records = args.records ?: queryNew("");

		for ( var r in records ) {
			if ( structKeyExists( r, "schedule" ) ) {
				querySetCell( records, "schedule", scheduledReportService.cronExpressionToHuman( r.schedule ), queryCurrentRow( records ) );
			}
		}
	}

	private void function postEditRecordAction( event, rc, prc, args={} ) {
		var recordId = rc.id       ?: "";
		var schedule = rc.schedule ?: "";

		if ( !isEmpty( recordId ) and !isEmpty( schedule ) ) {
			scheduledReportService.updateScheduleReport( recordId, schedule );
		}
	}

	private string function renderRecord( event, rc, prc, args={} ) {
		prc.pageTitle = prc.pageTitle & "'s history";

		return renderView( view="/admin/scheduledReport/exportHistory", args=args );
	}
}