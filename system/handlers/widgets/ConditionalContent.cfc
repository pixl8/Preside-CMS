component {
	property name="rulesEngineWebRequestService" inject="rulesEngineWebRequestService";

	/**
	 * @cacheable false
	 *
	 */
	private function index( event, rc, prc, args={} ) {
		var conditionIsTrue = rulesEngineWebRequestService.evaluateCondition( args.condition ?: "" );
		var renderType      = prc.cbox_renderdata.type ?: "";

		var content = "";
		if ( conditionIsTrue ) {
			content = args.content;
		} else if ( Len( Trim( args.alternative_content ?: "" ) ) ) {
			content = args.alternative_content;
		}

		switch ( renderType ) {
			case "json":
				content = serializeJSON( content );
				content = reReplace( content, "^\""|\""$", "", "ALL");
				break;
		}

		return content;
	}

	private string function placeholder( event, rc, prc, args={} ) {
		var conditionName = renderLabel( objectName="rules_engine_condition", recordId=args.condition );

		return translateResource( uri="widgets.conditionalContent:placeholder", data=[ conditionName ] );
	}
}