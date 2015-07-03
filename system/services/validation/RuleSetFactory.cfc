component {

	public array function newRuleset( any rules ){
		var rule        = "";
		var rules       = [];
		var parsedRules = Duplicate( arguments.rules );

		if ( IsSimplevalue( parsedRules ) ) {
			if ( FileExists( parsedRules ) ) {
				parsedRules = FileRead( parsedRules );
			}

			if ( IsJson( parsedRules ) ) {
				parsedRules = DeserializeJSON( parsedRules );
			}
		}

		if ( not IsArray( parsedRules ) ) {
			throw(
				  type    = "RuleSet.badRuleSet"
				, message = "Invalid ruleset. Rulesets must be either an array of valid rules, a json string that deserializes to an array of valid rules or a path to a file containing such a json string."
				, detail  = "The following ruleset (serialized) was invalid: [#SerializeJson( arguments.rules )#]"
			);
		}

		for( rule in parsedRules ){
			try {
				rules.append( {
					  fieldName       = rule.fieldName
					, validator       = rule.validator
					, params          = rule.params          ?: {}
					, message         = rule.message         ?: ""
					, serverCondition = rule.serverCondition ?: ""
					, clientCondition = rule.clientCondition ?: ""
				} );
			} catch ( any e ) {
				throw(
					  type    = "RuleSet.badRule"
					, message = "Invalid rule. Please see the documentation on creating validation rulesets."
					, detail  = "The following rule (serialized) was invalid: [#SerializeJson( rule )#]"
				);
			}
		}

		return rules;
	}
}