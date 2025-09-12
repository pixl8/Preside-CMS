component {
	property name="webflowUtilsService" inject="WebflowUtilsService";

	public string function default( event, rc, prc, args={} ) {
		var recordId       = Trim( args.data ?: "" );
		var webflowConfig  = args.record ?: {};
		var archivedCount  = webflowUtilsService.getWebflowInstances( recordId=recordId, archived=true, countOnly=true );
		var timingOutCount = webflowUtilsService.getWebflowInstances(
			  recordId     = recordId
			, countOnly    = true
			, filter       = "datemodified < :datemodified"
			, filterParams = { datemodified=DateAdd( "n", -1 * Val( webflowConfig?.timeout_in_minutes ), Now() ) }
		);
		var totalCount     = archivedCount + timingOutCount;
		var completedCount = webflowUtilsService.getWebflowInstances(
			  recordId     = recordId
			, archived     = true
			, countOnly    = true
			, extraFilters = [ { filter={ archive_reason="complete" } } ]
		);

		return NumberFormat( ( totalCount > 0 ) ? ( completedCount / totalCount * 100 ) : 0, "0" );
	}
}