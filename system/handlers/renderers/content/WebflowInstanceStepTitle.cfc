component {
	property name="webflowConfigService" inject="WebflowConfigurationService";

	private string function default( event, rc, prc, args={} ) {
		var recordId    = Len( args.recordId ?: "" ) ? args.recordId : ( args.record?.id ?: "" );
		var recordData  = Trim( args.data        ?: "" );
		var webflowId   = Trim( args.webflowId   ?: "" );
		var instanceRef = Trim( args.instanceRef ?: "" );

		if ( Len( recordData ) ) {
			if ( !Len( webflowId ) || !Len( instanceRef ) ) {
				var webflowDetail = getPresideObject( "cfflow_workflow_instance_history" ).selectData(
					  id           = recordId
					, returntype   = "singleRecordStruct"
					, selectFields = [ "instance.reference", "instance.sub_reference" ]
				);

				webflowId   = Len( webflowId   ) ? webflowId   : ( webflowDetail.reference     ?: "" );
				instanceRef = Len( instanceRef ) ? instanceRef : ( webflowDetail.sub_reference ?: "" );
			}

			if ( Len( webflowId ) ) {
				var webflowSteps = webflowConfigService.getStepTitles( webflowId=webflowId, instanceRef=instanceRef );

				return webflowSteps[ recordData ] ?: recordData;
			}
		}
		return recordData;
	}
}