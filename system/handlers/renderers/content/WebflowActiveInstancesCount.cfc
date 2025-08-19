component {
	property name="webflowUtilsService" inject="WebflowUtilsService";

	public string function default( event, rc, prc, args={} ) {
		var recordId      = Trim( args.data ?: "" );
		var referenceId   = Trim( rc.reference ?: "" );
		var instanceCount = webflowUtilsService.getWebflowInstances(
			  recordId     = recordId
			, countOnly    = true
			, extraFilters = Len( referenceId ) ? [ { filter={ sub_reference=referenceId } } ] : []
		);

		return Val( instanceCount );
	}
}