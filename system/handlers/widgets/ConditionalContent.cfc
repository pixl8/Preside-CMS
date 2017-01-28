component {
	property name="rulesEngineWebRequestService" inject="rulesEngineWebRequestService";

	private function index( event, rc, prc, args={} ) {
		var conditionIsTrue = rulesEngineWebRequestService.evaluateCondition( args.condition ?: "" );

		if ( conditionIsTrue ) {
			return args.content;
		} else if ( Len( Trim( args.alternative_content ?: "" ) ) ) {
			return args.alternative_content;
		}

		return "";
	}

	private string function placeholder( event, rc, prc, args={} ) {
		var conditionName = renderLabel( objectName="rules_engine_condition", recordId=args.condition );

		return translateResource( uri="widgets.conditionalContent:placeholder", data=[ conditionName ] );
	}
}