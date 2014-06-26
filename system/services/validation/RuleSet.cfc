component output="false" {

	variables._rules = [];

	public any function init( any rules ){
		if ( StructKeyExists( arguments, "rules" ) ) {
			addRules( arguments.rules );
		}

		return this;
	}

	public array function getRules(){
		return _getRules();
	}

	public void function addRule( required string fieldName, required string validator, struct params = {}, string message = "", string serverCondition = "", string clientCondition = "" ) {
		var rules = _getRules();

		ArrayAppend( rules, new Rule( argumentCollection = arguments ) );
		_setRules( rules );
	}

	public void function addRules( required any rules ){
		var rule = "";
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
				addRule( argumentCollection = rule );
			} catch ( any e ) {
				throw(
					  type    = "RuleSet.badRule"
					, message = "Invalid rule. Please see the documentation on creating validation rulesets."
					, detail  = "The following rule (serialized) was invalid: [#SerializeJson( rule )#]"
				);
			}
		}
	}

// GETTERS AND SETTERS
	private array function _getRules(){
		return _rules;
	}
	private void function _setRules( required array rules ){
		_rules = rules;
	}

}