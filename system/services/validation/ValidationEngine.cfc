/**
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		_setRulesets( {} );
		_setValidators( {} );
		_setRulesetFactory( new RuleSetFactory() );
		_loadCoreValidators();

		return this;
	}

// PUBLIC API METHODS
	public ValidationResult function validate( required string ruleset, required struct data, any result=newValidationResult(), boolean ignoreMissing=false ) outut=false {
		var rules       = _getRuleset( arguments.ruleset );
		var validators  = _getValidators();
		var validator   = _getValidators();
		var providers   = "";
		var provider    = "";
		var rule        = "";
		var fieldResult = "";

		for( rule in rules ){
			if ( arguments.ignoreMissing && !arguments.data.keyExists( rule.fieldName ) ) {
				continue;
			}
			if ( not result.fieldHasError( rule.fieldName ) and _evaluateConditionalRule( rule, data ) ) {
				provider = validators[ rule.validator ];

				fieldResult = provider.runValidator(
					  name      = rule.validator
					, fieldName = rule.fieldName
					, value     = StructKeyExists( arguments.data, rule.fieldName ) ? arguments.data[ rule.fieldName ] : ""
					, params    = rule.params
					, data      = arguments.data
				);

				if ( not IsBoolean( fieldResult ) or not fieldResult ) {
					result.addError(
						  fieldName = rule.fieldName
						, message   = ( Len( Trim( rule.message ) ) ? rule.message : provider.getDefaultMessage( name=rule.validator ) )
						, params    = provider.getValidatorParamValues( name=rule.validator, params=rule.params )
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

		if ( rulesetExists( arguments.ruleset ) ) {
			rules = _getRuleset( arguments.ruleset );
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

	public array function newRuleset( required string name, any rules=[] ) {
		var rulesets = _getRulesets();

		rulesets[ arguments.name ] = _getRuleSetFactory().newRuleset( rules = arguments.rules );

		return rulesets[ arguments.name ];
	}

	public ValidationProvider function newProvider( required any sourceCfc ) {
		var providerFactory = new ValidationProviderFactory();
		var provider        = providerFactory.createProvider( sourceCfc = arguments.sourceCfc );

		_registerValidators( provider );

		return provider;
	}

	public array function listRulesets() {
		var ruleSets = StructKeyArray( _getRulesets() );
		ArraySort( ruleSets, "textnocase" );
		return ruleSets;
	}

	public array function listValidators() {
		var validators = StructKeyArray( _getValidators() );
		ArraySort( validators, "textnocase" );
		return validators;
	}

	public any function newValidationResult() {
		return new ValidationResult();
	}

	public boolean function rulesetExists( required string rulesetName ) {
		return StructKeyExists( _getRulesets(), arguments.rulesetName );
	}

// PRIVATE HELPERS
	private void function _loadCoreValidators() {
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

	private array function _getRuleset( required string rulesetName ) {
		var rulesets = _getRulesets();

		return rulesets[ arguments.rulesetName ];
	}

	private string function _generateCustomValidatorsJs( required array rules ) {
		var validators  = _getValidators();
		var provider    = "";
		var validatorJs = "";
		var js          = "";
		var rule        = "";
		var registered  = {};

		for( rule in arguments.rules ){
			if ( StructKeyExists( registered, rule.validator ) ) {
				continue;
			}

			provider   = validators[ rule.validator ];
			validatorJs = provider.getJsFunction( rule.validator );

			if ( Len( Trim( validatorJs ) ) ) {
				js &= '$.validator.addMethod( "#LCase( rule.validator )#", #validatorJs#, "" ); ';
			}

			registered[ rule.validator ] = true;
		}

		return Trim( js );
	}

	private struct function _generateRulesAndMessagesJs( required array rules ) {
		var validators = _getValidators();
		var jsRules    = {};
		var jsMessages = {};
		var rule       = "";
		var js         = { rules="", messages="" };
		var processed  = "";
		var params     = "";
		var message    = "";

		for( rule in arguments.rules ){
			if ( not StructKeyExists( jsRules, rule.fieldName ) ) {
				jsRules[ rule.fieldName ] = "";
				jsMessages[ rule.fieldName ] = "";
			}
			params  = validators[ rule.validator ].getValidatorParamValues( name=rule.validator, params=rule.params );
			message = Len( Trim( rule.message ) ) ? rule.message : validators[ rule.validator ].getDefaultMessage( name=rule.validator );

			jsRules[ rule.fieldName ] = ListAppend( jsRules[ rule.fieldName ], ' "#LCase( rule.validator )#" : { param : #_parseParamsForJQueryValidate( params, rule.validator )#' );
			if ( Len( Trim( rule.clientCondition ) ) ) {
				jsRules[ rule.fieldName ] &= ", depends : " & _generateClientCondition( rule.clientCondition );
			}
			jsRules[ rule.fieldName ] &= ' }';

			jsMessages[ rule.fieldName ] = ListAppend( jsMessages[ rule.fieldName ], ' "#LCase( rule.validator )#" : translateResource( "#message#", { data : #SerializeJson( params )# } )' );
		}

		for( rule in arguments.rules ){
			if ( not ListFind( processed, rule.fieldName ) ) {
				js.rules    = ListAppend( js.rules   , ' "#rule.fieldName#" : {#jsRules[ rule.fieldName ]# }' );
				js.messages = ListAppend( js.messages, ' "#rule.fieldName#" : {#jsMessages[ rule.fieldName ]# }' );
				processed   = ListAppend( processed, rule.fieldName );
			}
		}

		return js;
	}

	private boolean function _evaluateConditionalRule( required struct rule, required struct data ) {
		var condition = arguments.rule.serverCondition;
		var parsed    = "";
		var result    = true;

		if ( Len( Trim( condition ) ) ) {
			parsed = ReReplace( condition, "\$\{([a-zA-Z1-9_\$]+)\}", "arguments.data.\1", "all" );

			try {
				result = Evaluate( parsed );
			} catch ( any e ) {
				throw(
					  type    = "ValidationEngine.badCondition"
					, message = "The validator condition, [#condition#], for field, [#rule.fieldName#], caused an exception to be raised. See error detail for more information."
					, detail  = "Message: [#e.message#]. Detail: [#e.detail#]."
				);
			}

			if ( not IsBoolean( result ) ) {
				throw(
					  type    = "ValidationEngine.badCondition"
					, message = "The validator condition, [#condition#], for field, [#rule.fieldName#], did not evaulate to a boolean"
				);
			}
		}

		return result;
	}

	private string function _generateClientCondition( required string condition ) {
		var parsed = Trim( ReReplace( arguments.condition, "\$\{([a-zA-Z1-9_\$]+)\}", '$( this.form ).find( "[name=''\1'']" )', "all" ) );

		if ( Left( parsed, 8 ) eq "function" ) {
			return parsed;
		}

		return "function( element ){ return #parsed#; }";
	}

	private string function _parseParamsForJQueryValidate( required array params, required string validator ) {
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
	private struct function _getRulesets() {
		return _rulesets;
	}
	private void function _setRulesets( required struct rulesets ) {
		_rulesets = arguments.rulesets;
	}

	private struct function _getValidators() {
		return _validators;
	}
	private void function _setValidators( required struct validators ) {
		_validators = arguments.validators;
	}

	private any function _getRulesetFactory() {
		return _rulesetFactory;
	}
	private void function _setRulesetFactory( required any rulesetFactory ) {
		_rulesetFactory = arguments.rulesetFactory;
	}
}