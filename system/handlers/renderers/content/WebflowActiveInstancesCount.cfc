component {
	property name="webflowUtilsService" inject="WebflowUtilsService";

	public string function default( event, rc, prc, args={} ) {
		var recordId      = Trim( args.data ?: "" );
		var referenceId   = Trim( rc.reference ?: "" );
		var extraFilters  = [];
		var webflowConfig = args.record ?: getPresideObject( args.objectName ).selectData(
			  id           = recordId
			, returntype   = "singleRecordStruct"
			, selectFields = [ "timeout_in_minutes" ]
		);

		ArrayAppend( extraFilters, {
			  filter       = "datemodified >= :datemodified"
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