component {
	property name="webflowUtilsService" inject="WebflowUtilsService";

	public string function default( event, rc, prc, args={} ) {
		var recordId      = Trim( args.data ?: "" );
		var referenceId   = Trim( rc.reference ?: "" );
		var webflowConfig = args.record ?: {};
		var extraFilters  = [];

		ArrayAppend( extraFilters, {
			  filter       = "datemodified < :datemodified"
			, filterParams = { datemodified = DateAdd( "n", -1 * Val( webflowConfig?.timeout_in_minutes ), Now() ) }
		} );

		if ( Len( referenceId ) ) {
			ArrayAppend( extraFilters, { filter={ sub_reference=referenceId } } );
		}

		var instanceCount = webflowUtilsService.getWebflowInstances(
			  recordId     = recordId
			, countOnly    = true
			, extraFilters = extraFilters
		);

		return Val( instanceCount );
	}
}