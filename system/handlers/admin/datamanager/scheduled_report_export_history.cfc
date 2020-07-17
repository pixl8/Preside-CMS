component {
	property name="scheduledReportService" inject="ScheduledReportService";

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var record     = args.record     ?: {};
		var recordId   = record.id       ?: "";

		args.actions = args.actions ?: [];

		if ( !isEmpty( recordId ) ) {
			var filepath = scheduledReportService.getHistoryExportFile( recordId );

			if ( !isEmpty( filepath ) ) {
				args.actions.prepend( {
					  link       = event.buildLink( fileStorageProvider="ScheduledReportStorageProvider", fileStoragePath="/#filepath#" )
					, icon       = "fa-download green"
					, contextKey = "d"
				} );
			}
		}
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var scheduled_report = rc.id ?: "";

		return "scheduled_report=#scheduled_report#";
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var scheduledReport = rc.scheduled_report ?: "";

		if ( !isEmpty( scheduledReport ) ) {
			args.extraFilters = args.extraFilters ?: [];

			args.extraFilters.append( { filter={ scheduled_report=scheduledReport } } );
		}
	}

	public void function postDeleteRecordAction( event, rc, prc, args={} ) {
		var scheduledReportExportRecordUrl = args.cancelUrl ?: "";

		if ( !isEmpty( scheduledReportExportRecordUrl ) ) {
			setNextEvent( url=scheduledReportExportRecordUrl );
		}
	}
}