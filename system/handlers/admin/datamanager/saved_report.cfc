component {
	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var record     = args.record     ?: {};
		var recordId   = record.id       ?: "";

		args.actions = args.actions ?: [];

		if ( isFeatureEnabled( "scheduledReportExport" ) ) {
			args.actions.prepend( {
				  link       = event.buildAdminLink( linkto="scheduledReport.create", queryString="reportId=#recordId#" )
				, icon       = "fa-clock"
				, contextKey = "s"
			} );
		}

		args.actions.prepend( {
			  link       = event.buildAdminLink( objectName=objectName, operation="savedReportExport", recordId=recordId )
			, icon       = "fa-download green"
			, contextKey = "d"
		} );
	}

	private void function extraTopRightButtonsForObject( event, rc, prc, args={} ) {
		args.actions = args.actions ?: [];

		if ( isFeatureEnabled( "scheduledReportExport" ) ) {
			args.actions.append({
				  link      = event.buildAdminLink( objectName="scheduled_report_export" )
				, btnClass  = "btn-info"
				, iconClass = "fa-clock"
				, title     = translateResource( "preside-objects.scheduled_report_export:view.btn" )
			});
		}
	}
}