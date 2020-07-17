component {
	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var record     = args.record     ?: {};
		var recordId   = record.id       ?: "";

		args.actions = args.actions ?: [];
		args.actions.prepend( {
			  link       = event.buildAdminLink( objectName=objectName, operation="savedReportExport", recordId=recordId )
			, icon       = "fa-download green"
			, contextKey = "d"
		} );
	}
}