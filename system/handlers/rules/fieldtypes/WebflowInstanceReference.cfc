/**
 * Handler for rules engine 'webflow instance reference' type
 *
 * @feature rulesEngine and webflow
 */
component {

	property name="webflowConfigurationService" inject="WebflowConfigurationService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var webflowId  = Trim( rc.webflow ?: "" );
		var references = ListToArray( Trim( arguments.value ) );
		var rendered   = [];

		if ( Len( webflowId ) ) {
			for ( var ref in references ) {
				ArrayAppend( rendered, _renderInstanceLabel(
					  webflowId = webflowId
					, reference = ref
				) );
			}
		}

		if ( ArrayLen( rendered ) ) {
			return ArrayToList( rendered, ", " );
		}

		return arguments.config.defaultLabel ?: "";
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		var multiple  = IsTrue( arguments.config.multiple ?: false );
		var values    = [];
		var labels    = [];
		var webflowId = Trim( rc.webflow ?: "" );

		if ( Len( webflowId ) ) {
			var sourceObject      = ArrayFindNoCase( [ "active", "activetimedout" ], ( rc.type ?: "active" ) ) ? "cfflow_workflow_instance" : "cfflow_workflow_archived_instance";
			var refGroupingConfig = webflowConfigurationService.getInstanceRefGroupingConfig( webflowId=webflowId, sourceObject=sourceObject, includeNonSingleton=true );

			if ( IsQuery( refGroupingConfig.groupedRefs ?: "" ) && refGroupingConfig.groupedRefs.recordcount ) {
				for ( var row in refGroupingConfig.groupedRefs ) {
					var referenceLabel = _renderInstanceLabel(
						  webflowId = webflowId
						, reference = row.reference_id
					);

					if ( Len( referenceLabel ) ) {
						ArrayAppend( values, row.reference_id );
						ArrayAppend( labels, referenceLabel );
					}
				}
			}
		}

		rc.delete( "value" );

		return renderFormControl(
			  name               = "value"
			, type               = "select"
			, multiple           = multiple
			, values             = values
			, labels             = labels
			, label              = translateResource( "cms:rulesEngine.fieldtype.webflowInstanceReference.config.label" )
			, savedValue         = arguments.value
			, defaultValue       = arguments.value
			, includeEmptyOption = true
			, required           = isTrue( arguments.config.required ?: false )
		);
	}

// HELPERs
	private string function _renderInstanceLabel(
		  required string webflowId
		, required string reference
	) {
		return renderContent(
			  renderer = "webflowInstanceReference"
			, data     = reference
			, context  = "plainText"
			, args     = { webflowId=webflowId }
		);
	}
}