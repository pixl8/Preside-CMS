/**
 * @feature webflow
 */
component {
	property name="webflowConfigurationService" inject="webflowConfigurationService";

	public string function index( event, rc, prc, args={} ) {
		var fieldName    = args.name         ?: "";
		var webflowField = args.webflowField ?: "webflow";
		var typeField    = args.typeField    ?: "type";

		args.removeObjectPickerClass = true;
		args.class                   = "form-control";

		args.webflowId    = rc.webflowId    ?: ( args.savedData[ webflowField ] ?: "" );
		args.selectedType = rc.selectedType ?: ( args.savedData[ typeField ] ?: "" );
		args.values       = [ "" ];
		args.labels       = [ translateResource( uri="cms:option.pleaseselect" ) ];

		var options = getInstanceOptions( argumentCollection=arguments );
		if ( ArrayLen( options.values ) ) {
			args.values = options.values;
			args.labels = options.labels;
		}

		event.include( "/js/admin/specific/webflowInstancePicker/" )
		     .includeData( {
		     	  instancePickerField         = fieldName
		     	, instancePickerWebflowField  = webflowField
		     	, instancePickerTypeField     = typeField
		     	, instancePickerGetOptionsUrl = event.buildLink( linkto="formcontrols.webflowInstancePicker.getInstanceOptions" )
		     } );

		return renderView( view="formcontrols/select/index", args=args );
	}

	public struct function getInstanceOptions( event, rc, prc, args={} ) {
		var webflowId    = args.webflowId    ?: ( rc.webflowId    ?: "" );
		var selectedType = args.selectedType ?: ( rc.selectedType ?: "" );
		var options      = { values=[], labels=[] };

		if ( Len( webflowId ) && Len( selectedType ) ) {
			var wfConfig = getPresideObject( "webflow_configuration" ).selectData(
				  id           = webflowId
				, selectFields = [ "webflow_id" ]
				, returntype   = "singleRecordStruct"
			);

			if ( StructCount( wfConfig ) ) {
				var sourceObject      = ( selectedType == "current" ) ? "cfflow_workflow_instance" : "cfflow_workflow_archived_instance";
				var refGroupingConfig = webflowConfigurationService.getInstanceRefGroupingConfig( webflowId=wfConfig.webflow_id, sourceObject=sourceObject );

				if ( IsQuery( refGroupingConfig.groupedRefs ?: "" ) && refGroupingConfig.groupedRefs.recordcount ) {
					options = {
						  values = [ "" ]
						, labels = [ translateResource( uri="cms:option.pleaseselect" ) ]
					};

					for ( var row in refGroupingConfig.groupedRefs ) {
						ArrayAppend( options.values, row.reference_id );
						ArrayAppend( options.labels, renderContent(
							  renderer = "webflowInstanceReference"
							, data     = row.reference_id
							, context  = "plainText"
							, args     = { webflowId=wfConfig.webflow_id }
						) );
					}
				}
			}
		}

		return options;
	}
}
