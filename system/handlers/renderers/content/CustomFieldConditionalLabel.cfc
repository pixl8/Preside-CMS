/**
 * @feature admin and customFields
 */
component {

	property name="customFieldsService"     inject="customFieldsService";
	property name="customFieldBadgeService" inject="customFieldBadgeService";

	public string function admin( event, rc, prc, args={} ) {
		return index( argumentCollection=arguments );
	}

	public string function adminView( event, rc, prc, args={} ) {
		return index( argumentCollection=arguments );
	}

	public string function index( event, rc, prc, args={} ) {
		var rules    = _rulesFromArgs( argumentCollection=arguments );
		var rendered = [];

		for( var rule in rules ) {
			var badge = customFieldBadgeService.renderBadge(
				  label  = rule.label_text ?: ""
				, colour = rule.colour     ?: ( rule.style ?: "" )
			);

			if ( Len( badge ) ) {
				ArrayAppend( rendered, badge );
			}
		}

		return ArrayToList( rendered, " " );
	}

	private array function _rulesFromArgs( event, rc, prc, args={} ) {
		if ( ( args.objectName ?: "" ) == "custom_field_conditional_rule" ) {
			if ( IsStruct( args.record ?: "" ) && !StructIsEmpty( args.record ) ) {
				return [ args.record ];
			}

			return [ { label_text=args.data ?: "" } ];
		}

		var rules = [];

		for( var ruleId in customFieldsService.evaluateConditionalLabels( args.data ?: "" ) ) {
			var rule = customFieldsService.getConditionalRuleById( ruleId );
			if ( !StructIsEmpty( rule ) ) {
				ArrayAppend( rules, rule );
			}
		}

		return rules;
	}

}
