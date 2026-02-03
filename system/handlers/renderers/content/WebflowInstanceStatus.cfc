component {

	public string function default( event, rc, prc, args={} ) {
		var typeI18nKey  = "active";
		var recordId     = Trim( args.data ?: "" );
		var recordDetail = getPresideObject( "cfflow_workflow_instance" ).selectData(
			  returntype   = "singleRecordStruct"
			, id           = recordId
			, selectFields = [
				  "reference"
				, "sub_reference"
				, "sub_sub_reference"
				, "datemodified"
			]
		);

		if ( IsDate( recordDetail.datemodified ?: "" ) && Len( recordDetail.reference ?: "" ) ) {
			var webflowConfig = getPresideObject( "webflow_configuration" ).selectData(
				  returntype   = "singleRecordStruct"
				, filter       = { webflow_id=recordDetail.reference }
				, selectFields = [ "timeout_in_minutes" ]
			);

			if ( DateCompare( recordDetail.datemodified, DateAdd( "n", -1 * Val( webflowConfig?.timeout_in_minutes ), Now() ) ) < 0 ) {
				typeI18nKey = "activetimedout";
			}
		}

		return translateResource( uri="enum.webflowSessionType:#typeI18nKey#.label" );
	}
}