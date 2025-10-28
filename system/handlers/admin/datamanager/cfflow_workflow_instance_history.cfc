component {

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var qs         = [];
		var objectName = Trim( prc.objectName ?: "" );

		if ( ( objectName == "cfflow_workflow_instance" ) && Len( Trim( prc.recordId ?: "" ) ) ) {
			return "instance_id=#prc.recordId#";
		}
		return "";
	}
	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters    ?: [];
		var instanceId    = Trim( rc.instance_id ?: "" );

		if ( Len( instanceId ) ) {
			ArrayAppend( args.extraFilters, { filter={ instance=instanceId } } );
		}
	}

	private void function postFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var records = args.records ?: QueryNew('');

		for ( var record in records ) {
			if ( IsDate( record.datecreated ?: "" ) ) {
				QuerySetCell( records, "datecreated", renderContent( "datetime", record.datecreated, "relative" ) , QueryCurrentRow( records ) );
			}
		}
	}
}