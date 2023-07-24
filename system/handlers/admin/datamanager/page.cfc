component extends="preside.system.base.AdminHandler" {

	private string function preRenderListing( event, rc, prc, args={} ) {
		return '<p class="alert alert-warning">This listing is an alternate view of your sitetree.</p>';
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		return buildEditRecordLink( argumentCollection=arguments );
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo="sitetree.editPage", querystring="id=#( args.recordId ?: "" )#" );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
			args.extraFilters = args.extraFilters ?: [];
			args.extraFilters.append( { filter={ trashed = false } } );
	}

	private void function postDecorateRecordsForGridListing( event, rc, prc, args={} ) {
		var i=1;
		var records = args.records ?: queryNew( '' );

		for ( var record in records ) {
			querySetCell( records, "page_type", renderContent( "ObjectName", record.page_type, "admindatatable" ), i++ );
		}
	}

}