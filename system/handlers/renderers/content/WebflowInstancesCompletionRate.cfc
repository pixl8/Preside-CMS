component {
	property name="webflowUtilsService" inject="WebflowUtilsService";

	public string function default( event, rc, prc, args={} ) {
		var recordId       = Trim( args.data ?: "" );
		var archivedCount  = webflowUtilsService.getWebflowInstances( recordId=recordId, archived=true, countOnly=true );
		var completedCount = webflowUtilsService.getWebflowInstances(
			  recordId     = recordId
			, archived     = true
			, countOnly    = true
			, extraFilters = [ { filter={ archive_reason="complete" } } ]
		);

		return NumberFormat( ( archivedCount > 0 ) ? ( completedCount / archivedCount * 100 ) : 0, "_.000" );
	}
}