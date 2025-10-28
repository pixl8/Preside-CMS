component {
	property name="webflowUtilsService" inject="WebflowUtilsService";

	public string function default( event, rc, prc, args={} ) {
		var recordId      = Trim( args.data ?: "" );
		var instanceCount = webflowUtilsService.getWebflowInstances(
			  recordId     = recordId
			, archived     = true
			, countOnly    = true
			, extraFilters = [ { filter={ archive_reason="complete" } } ]
		);

		return Val( instanceCount );
	}
}