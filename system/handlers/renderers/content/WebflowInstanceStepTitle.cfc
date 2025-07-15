component {
	property name="webflowConfigService" inject="WebflowConfigurationService";

	private string function default( event, rc, prc, args={} ) {
		var recordId   = Len( args.recordId ?: "" ) ? args.recordId : ( args.record?.id ?: "" );
		var recordData = Trim( args.data ?: "" );

		if ( Len( recordData ) ) {
			var webflowDetail = getPresideObject( "cfflow_workflow_instance_history" ).selectData(
				  id           = recordId
				, returntype   = "singleRecordStruct"
				, selectFields = [ "instance.reference", "instance.sub_reference" ]
			);

			if ( !StructIsEmpty( webflowDetail ) ) {
				var webflowSteps = webflowConfigService.getStepTitles( webflowId=webflowDetail.reference, instanceRef=webflowDetail.sub_reference );

				return webflowSteps[ recordData ] ?: recordData;
			}
		}
		return recordData;
	}
}