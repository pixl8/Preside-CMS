component output="false" singleton=true {

// CONSTRUCTOR
	public any function init() output=false {
		_setRulesets( {} );
		_setValidators( {} );
		_loadCoreValidators();

		return this;
	}

// PUBLIC API METHODS
	public ValidationResult function validate( required string ruleset, required struct data, any result=newValidationResult() ) outut=false {
		var rules       = _getRuleset( arguments.ruleset ).getRules();
		var validators  = _getValidators();
		var validator   = _getValidators();
		var providers   = "";
		var provider    = "";
		var rule        = "";
		var fieldResult = "";

		for( rule in rules ){
			if ( not result.fieldHasError( rule.getFieldName() ) and _evaluateConditionalRule( rule, data ) ) {
				provider = validators[ rule.getValidator() ];

				fieldResult = provider.runValidator(
					  name      = rule.getValidator()
					, fieldName = rule.getFieldName()
					, value     = StructKeyExists( arguments.data, rule.getFieldName() ) ? arguments.data[ rule.getFieldName() ] : ""
					, params    = rule.getParams()
					, data      = arguments.data
				);

				if ( not IsBoolean( fieldResult ) or not fieldResult ) {
					result.addError(
						  fieldName = rule.getFieldName()
						, message   = ( Len( Trim( rule.getMessage() ) ) ? rule.getMessage() : provider.getDefaultMessage( name=rule.getValidator() ) )
						, params    = provider.getValidatorParamValues( name=rule.getValidator(), params=rule.getParams() )
					);
				}
			}
		}

		return result;
	}

	public string function getJqueryValidateJs( required string ruleset ) outut=false {
		var js    = "";
		var rules = "";
		var rulesAndMessagesJs = "";

		if ( _rulesetExists( arguments.ruleset ) ) {
			rules = _getRuleset( arguments.ruleset ).getRules();
			rulesAndMessagesJs = _generateRulesAndMessagesJs( rules )

			js = "( function( $ ){ ";
				js &= 'var translateResource = ( i18n && i18n.translateResource ) ? i18n.translateResource : function(a){ return a }; ';
				js &= _generateCustomValidatorsJs( rules ) & " ";
				js &= "return { ";
					js &= "rules : { "    & Trim( rulesAndMessagesJs.rules    ) & " }, ";
					js &= "messages : { " & Trim( rulesAndMessagesJs.messages ) & " } ";
				js &= "}; "
			js &= "} )( presideJQuery )";
		}

		return js;
	}

	public RuleSet function newRuleset( required string name, any rules=[] ) output=false {
		var rulesets = _getRulesets();

		rulesets[ arguments.name ] = new RuleSet( rules = arguments.rules );

		return rulesets[ arguments.name ];
	}

	public ValidationProvider function newProvider( required any sourceCfc ) output=false {
		var providerFactory = new ValidationProviderFactory();
		var provider        = providerFactory.createProvider( sourceCfc = arguments.sourceCfc );

		_registerValidators( provider );

		return provider;
	}

	public array function listRulesets() output=false {
		var ruleSets = StructKeyArray( _getRulesets() );
		ArraySort( ruleSets, "textnocase" );
		return ruleSets;
	}

	public array function listValidators() output=false {
		var validators = StructKeyArray( _getValidators() );
		ArraySort( validators, "textnocase" );
		return validators;
	}

	public any function newValidationResult() output=false {
		return new ValidationResult();
	}

// PRIVATE HELPERS
	private void function _loadCoreValidators() output=false {
		newProvider( sourceCfc = new CoreValidators() );
	}

	private void function _registerValidators( required ValidationProvider provider ){
		var currentValidators = _getValidators();
		var newValidators     = provider.listValidators();
		var validator         = "";

		for( validator in newValidators ){
			currentValidators[ validator ] = provider;
		}
	}

	private RuleSet function _getRuleset( required string rulesetName ) output=false {
		var rulesets = _getRulesets();

		return rulesets[ arguments.rulesetName ];
	}

	private boolean function _rulesetExists( required string rulesetName ) output=false {
		return StructKeyExists( _getRulesets(), arguments.rulesetName );
	}

	private string function _generateCustomValidatorsJs( required array rules ) output=false {
		var validators  = _getValidators();
		var provider    = "";
		var validatorJs = "";
		var js          = "";
		var rule        = "";
		var registered  = {};

		for( rule in arguments.rules ){
			if ( StructKeyExists( registered, rule.getValidator() ) ) {
				continue;
			}

			provider   = validators[ rule.getValidator() ];
			validatorJs = provider.getJsFunction( rule.getValidator() );

			if ( Len( Trim( validatorJs ) ) ) {
				js &= '$.validator.addMethod( "#LCase( rule.getValidator() )#", #validatorJs#, "" ); ';
			}

			registered[ rule.getValidator() ] = true;
		}

		return Trim( js );
	}

	private struct function _generateRulesAndMessagesJs( required array rules ) output=false {
		var validators = _getValidators();
		var jsRules    = {};
		var jsMessages = {};
		var rule       = "";
		var js         = { rules="", messages="" };
		var processed  = "";
		var params     = "";
		var message    = "";

		for( rule in arguments.rules ){
			if ( not StructKeyExists( jsRules, rule.getFieldName() ) ) {
				jsRules[ rule.getFieldName() ] = "";
				jsMessages[ rule.getFieldName() ] = "";
			}
			params  = validators[ rule.getValidator() ].getValidatorParamValues( name=rule.getValidator(), params=rule.getParams() );
			message = Len( Trim( rule.getMessage() ) ) ? rule.getMessage() : validators[ rule.getValidator() ].getDefaultMessage( name=rule.getValidator() );

			jsRules[ rule.getFieldName() ] = ListAppend( jsRules[ rule.getFieldName() ], ' "#LCase( rule.getValidator() )#" : { param : #_parseParamsForJQueryValidate( params, rule.getValidator() )#' );
			if ( Len( Trim( rule.getClientCondition() ) ) ) {
				jsRules[ rule.getFieldName() ] &= ", depends : " & _generateClientCondition( rule.getClientCondition() );
			}
			jsRules[ rule.getFieldName() ] &= ' }';

			jsMessages[ rule.getFieldName() ] = ListAppend( jsMessages[ rule.getFieldName() ], ' "#LCase( rule.getValidator() )#" : translateResource( "#message#", { data : #SerializeJson( params )# } )' );
		}

		for( rule in arguments.rules ){
			if ( not ListFind( processed, rule.getFieldName() ) ) {
				js.rules    = ListAppend( js.rules   , ' "#rule.getFieldName()#" : {#jsRules[ rule.getFieldName() ]# }' );
				js.messages = ListAppend( js.messages, ' "#rule.getFieldName()#" : {#jsMessages[ rule.getFieldName() ]# }' );
				processed   = ListAppend( processed, rule.getFieldName() );
			}
		}

		return js;
	}

	private boolean function _evaluateConditionalRule( required Rule rule, required struct data ) output=false {
		var condition = arguments.rule.getServerCondition();
		var parsed    = "";
		var result    = true;

		if ( Len( Trim( condition ) ) ) {
			parsed = ReReplace( condition, "\$\{([a-zA-Z1-9_\$]+)\}", "arguments.data.\1", "all" );

			try {
				result = Evaluate( parsed );
			} catch ( any e ) {
				throw(
					  type    = "ValidationEngine.badCondition"
					, message = "The validator condition, [#condition#], for field, [#rule.getFieldName()#], caused an exception to be raised. See error detail for more information."
					, detail  = "Message: [#e.message#]. Detail: [#e.detail#]."
				);
			}

			if ( not IsBoolean( result ) ) {
				throw(
					  type    = "ValidationEngine.badCondition"
					, message = "The validator condition, [#condition#], for field, [#rule.getFieldName()#], did not evaulate to a boolean"
				);
			}
		}

		return result;
	}

	private string function _generateClientCondition( required string condition ) output=false {
		var parsed = Trim( ReReplace( arguments.condition, "\$\{([a-zA-Z1-9_\$]+)\}", '$( this.form ).find( "[name=''\1'']" )', "all" ) );

		if ( Left( parsed, 8 ) eq "function" ) {
			return parsed;
		}

		return "function( element ){ return #parsed#; }";
	}

	private string function _parseParamsForJQueryValidate( required array params, required string validator ) output=false {
		switch( validator ){
			case "min":
			case "max":
			case "minLength":
			case "maxLength":
				return ArrayLen( params ) ? Val( params[1] ) : 0;

			default:
				return SerializeJson( params );
		}
	}

// GETTERS AND SETTERS
	private struct function _getRulesets() output=false {
		return _rulesets;
	}
	private void function _setRulesets( required struct rulesets ) output=false {
		_rulesets = arguments.rulesets;
	}

	private struct function _getValidators() output=false {
		return _validators;
	}
	private void function _setValidators( required struct validators ) output=false {
		_validators = arguments.validators;
	}
}