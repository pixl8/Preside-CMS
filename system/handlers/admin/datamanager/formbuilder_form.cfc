component {

	private string function buildListingLink( event, rc, prc, args={} ) {
		return event.buildAdminLink(
			  linkto      = "formbuilder.index"
			, queryString = args.queryString ?: ""
		);
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		var recordId = args.recordId ?: "";
		var queryString = "id=#recordId#";

		return event.buildAdminLink(
			  linkto      = "formbuilder.manageForm"
			, queryString = _queryString( queryString, args )
		);
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var recordId = args.recordId ?: "";
		var queryString = "id=#recordId#";

		return event.buildAdminLink(
			  linkto      = "formbuilder.manageForm"
			, queryString = _queryString( queryString, args )
		);
	}

	private string function _queryString( required string querystring, struct args={} ) {
		var extraQs = args.queryString ?: "";

		if ( extraQs.len() ) {
			return arguments.queryString & "&" & extraQs;
		}

		return arguments.queryString;
	}
}

