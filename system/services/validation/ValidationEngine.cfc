/**
 * The core API for Preside's Validation Engine. See [[validation-framework]] for full usage documentation.
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component displayName="Validation Engine" {

// CONSTRUCTOR
	public any function init() {
		_setRulesets( {} );
		_setValidators( {} );
		_setRulesetFactory( new RuleSetFactory() );
		_loadCoreValidators();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Validates the passed data struct against a
	 * registered ruleset. Returns a [[api-validationresult]]
	 * object that contains validation result information.
	 * See [[validation-framework]] for full usage documentation.
	 *
	 * @autodoc
	 * @ruleset.hint         Name of the ruleset to validate against
	 * @data.hint            The data set to validate
	 * @result.hint          Optional existing validation result to which to append validation errors
	 * @ignoreMissing.hint   Whether or not to ignore fields that are entirely missing from the passed data
	 * @fieldNamePrefix.hint Prefix to add to fieldnames in error messages
	 * @fieldNameSuffix.hint Suffix to add to fieldnames in error messages
	 */
	public ValidationResult function validate(
		  required string  ruleset
		, required struct  data
		,          any     result          = newValidationResult()
		,          boolean ignoreMissing   = false
		,          string  fieldNamePrefix = ""
		,          string  fieldNameSuffix = ""
		,          array   suppressFields  = []
	) {
		var rules       = _getRuleset( arguments.ruleset );
		var validators  = _getValidators();
		var validator   = _getValidators();
		var providers   = "";
		var provider    = "";
		var rule        = "";
		var fieldResult = "";

		for( rule in rules ){
			var expandedFieldName = arguments.fieldNamePrefix & rule.fieldName & arguments.fieldNameSuffix;


			if ( ( arguments.ignoreMissing && !StructKeyExists( arguments.data, rule.fieldName ) ) || ( arrayLen( arguments.suppressFields ) && arrayFind( arguments.suppressFields, rule.fieldName ) ) ) {
				continue;
			}
			if ( !result.fieldHasError( rule.fieldName ) && _evaluateConditionalRule( rule, data ) ) {
				provider = validators[ rule.validator ];

				fieldResult = provider.runValidator(
					  name      = rule.validator
					, fieldName = rule.fieldName
					, value     = arguments.data[ expandedFieldName ] ?: ( arguments.data[ rule.fieldName ] ?: "" )
					, params    = rule.params
					, data      = arguments.data
				);

				if ( !IsBoolean( fieldResult ) || !fieldResult ) {
					result.addError(
						  fieldName = expandedFieldName
						, message   = ( Len( Trim( rule.message ) ) ? rule.message : provider.getDefaultMessage( name=rule.validator ) )
						, params    = provider.getValidatorParamValues( name=rule.validator, params=rule.params )
					);
				}
			}
		}

		return result;
	}

	/**
	 * Returns jQuery Validate configuration options,
	 * as a javascript string, for the given ruleset.
	 * See [[validation-framework]] for full usage documentation.
	 *
	 * @autodoc
	 * @ruleset.hint         The name of the registered ruleset
	 * @jQueryReference.hint Name of the global jQuery reference variable (for Preside admin, this is "presideJQuery")
	 * @fieldNamePrefix.hint Prefix string to place before all field names (useful when outputting multiple instances of the same form in a single page)
	 * @fieldNameSuffix.hint Suffix string to place after all field names (useful when outputting multiple instances of the same form in a single page)
	 *
	 */
	public string function getJqueryValidateJs(
		  required string ruleset
		,          string jqueryReference = "presideJQuery"
		,          string fieldNamePrefix = ""
		,          string fieldNameSuffix = ""
	) {
		var js    = "";
		var rules = "";
		var rulesAndMessagesJs = "";

		if ( rulesetExists( arguments.ruleset ) ) {
			rules = _getRuleset( arguments.ruleset );
			rulesAndMessagesJs = _generateRulesAndMessagesJs( rules, arguments.fieldNamePrefix, arguments.fieldNameSuffix );

			js = "( function( $ ){ ";
				js &= _generateCustomValidatorsJs( rules ) & " ";
				js &= "return { ";
					js &= "rules : { "    & Trim( rulesAndMessagesJs.rules    ) & " }, ";
					js &= "messages : { " & Trim( rulesAndMessagesJs.messages ) & " } ";
				js &= "}; ";
			js &= "} )( #jqueryReference# )";
		}

		return js;
	}

	/**
	 * Registers a new ruleset. See [[validation-framework]] for full usage documentation.
	 *
	 * @autodoc
	 * @name.hint Name for the ruleset
	 * @rules.hint Either: an array of structs, json string evaluating to array of structs, or a filepath containing json
	 *
	 */
	public array function newRuleset( required string name, any rules=[] ) {
		var rulesets = _getRulesets();

		rulesets[ arguments.name ] = _getRuleSetFactory().newRuleset( rules = arguments.rules );

		return rulesets[ arguments.name ];
	}

	/**
	 * Registers a new Validation Provider. See [[validation-framework]] for full usage documentation.
	 *
	 * @autodoc
	 * @sourceCfc.hint Instantiated CFC that contains validators
	 */
	public ValidationProvider function newProvider( required any sourceCfc ) {
		var providerFactory = new ValidationProviderFactory();
		var provider        = providerFactory.createProvider( sourceCfc = arguments.sourceCfc );

		_registerValidators( provider );

		return provider;
	}

	/**
	 * Returns an array of registered ruleset names
	 *
	 * @autodoc
	 */
	public array function listRulesets() {
		var ruleSets = StructKeyArray( _getRulesets() );
		ArraySort( ruleSets, "textnocase" );
		return ruleSets;
	}

	/**
	 * Returns an array of registered validator names
	 *
	 * @autodoc
	 */
	public array function listValidators() {
		var validators = StructKeyArray( _getValidators() );
		ArraySort( validators, "textnocase" );
		return validators;
	}

	/**
	 * Returns a newly instantiated validation result.
	 * This can be useful for manually building your own
	 * validation results, prior to calling `validate()`
	 *
	 * @autodoc
	 */
	public any function newValidationResult() {
		return new ValidationResult();
	}

	/**
	 * Returns whether or not the passed ruleset
	 * is already registered.
	 *
	 * @autodoc
	 * @rulesetName.hint The name of the ruleset
	 *
	 */
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

	private boolean function _rulesetExists( required string rulesetName ) {
		return StructKeyExists( _getRulesets(), arguments.rulesetName );
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

	private struct function _generateRulesAndMessagesJs(
		  required array  rules
		,          string fieldNamePrefix = ""
		,          string fieldNameSuffix = ""
	) {
		var validators = _getValidators();
		var jsRules    = {};
		var jsMessages = {};
		var rule       = "";
		var js         = { rules="", messages="" };
		var processed  = "";
		var params     = "";
		var message    = "";

		for( rule in arguments.rules ){
			var fieldName = arguments.fieldNamePrefix & rule.fieldName & arguments.fieldNameSuffix;

			if ( not StructKeyExists( jsRules, fieldName ) ) {
				jsRules[ fieldName ] = "";
				jsMessages[ fieldName ] = "";
			}
			params  = validators[ rule.validator ].getValidatorParamValues( name=rule.validator, params=rule.params );
			message = Len( Trim( rule.message ) ) ? rule.message : validators[ rule.validator ].getDefaultMessage( name=rule.validator );

			jsRules[ fieldName ] = ListAppend( jsRules[ fieldName ], ' "#LCase( rule.validator )#" : { param : #_parseParamsForJQueryValidate( params, rule.validator )#' );
			if ( Len( Trim( rule.clientCondition ) ) ) {
				jsRules[ fieldName ] &= ", depends : " & _generateClientCondition( rule.clientCondition );
			}
			jsRules[ fieldName ] &= ' }';

			jsMessages[ fieldName ] = ListAppend( jsMessages[ fieldName ], ' "#LCase( rule.validator )#" : #SerializeJson( $translateResource( uri=message, data=params ) )#' );
		}

		for( rule in arguments.rules ){
			var fieldName = arguments.fieldNamePrefix & rule.fieldName & arguments.fieldNameSuffix;
			if ( not ListFind( processed, fieldName ) ) {
				js.rules    = ListAppend( js.rules   , ' "#fieldName#" : {#jsRules[ fieldName ]# }' );
				js.messages = ListAppend( js.messages, ' "#fieldName#" : {#jsMessages[ fieldName ]# }' );
				processed   = ListAppend( processed, fieldName );
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