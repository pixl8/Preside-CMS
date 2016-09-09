/**
 * Service that provides logic for dealing with rule engine expressions.
 * See [[rules-engine]] for further details.
 *
 * @singleton
 * @presideservice
 * @autodoc
 */
component displayName="RulesEngine Expression Service" {


// CONSTRUCTOR
	/**
	 * @expressionReaderService.inject rulesEngineExpressionReaderService
	 * @fieldTypeService.inject        rulesEngineFieldTypeService
	 * @expressionDirectories.inject   presidecms:directories:/handlers/rules/expressions
	 *
	 */
	public any function init( required any expressionReaderService, required any fieldTypeService, required array expressionDirectories ) {
		_setFieldTypeService( fieldTypeService );
		_setExpressions( expressionReaderService.getExpressionsFromDirectories( expressionDirectories ) )

		return this;
	}

// PUBLIC API
	/**
	 * Returns an array of expressions ordered by their translated
	 * labels and optionally filtered by context
	 *
	 * @autodoc
	 * @context.hint Expression context with which to filter the results
	 */
	public array function listExpressions( string context="" ) {
		var allExpressions  = _getExpressions();
		var list            = [];
		var filterOnContext = arguments.context.len() > 0;

		for( var expressionId in allExpressions ) {
			var contexts = allExpressions[ expressionId ].contexts ?: [];

			if ( !filterOnContext || contexts.findNoCase( arguments.context ) || contexts.findNoCase( "global" ) ) {
				list.append( getExpression( expressionId ) );
			}
		}

		list.sort( function( a, b ){
			return a.label > b.label ? 1 : -1;
		} );

		return list;
	}


	/**
	 * Returns a structure with all relevant info about the expression
	 * including:
	 * \n
	 * * fields
	 * * contexts
	 * * translated label
	 * * translated expression text
	 *
	 * @autodoc
	 * @expressionId.hint ID of the expression, e.g. "loggedIn.global"
	 */
	public struct function getExpression( required string expressionId ) {
		var expression = Duplicate( _getRawExpression( arguments.expressionId ) );

		expression.id     = expressionId;
		expression.label  = getExpressionLabel( expressionId );
		expression.text   = getExpressionText( expressionId );
		expression.fields = expression.fields ?: {};

		for( var fieldName in expression.fields ) {
			expression.fields[ fieldName ].defaultLabel = getDefaultFieldLabel( expressionId, fieldName );
		}

		return expression;
	}

	/**
	 * Returns a translated label for the given expression ID. The label
	 * is shown when rendering the expression in the list of optional
	 * expressions to use for the administrator. e.g.
	 * \n
	 * > User is logged in
	 *
	 * @autodoc
	 * @expressionId.hint ID of the expression, e.g. "loggedIn.global"
	 */
	public string function getExpressionLabel( required string expressionId ) {
		return $translateResource(
			  uri          = "rules.expressions.#arguments.expressionId#:label"
			, defaultValue = arguments.expressionId
		);
	}

	/**
	 * Returns a translated expression text for the given expression ID.
	 * Expression text is the text with placeholders that the administrator
	 * will see when building a condition. e.g.
	 * \n
	 * > User {_is} logged in
	 *
	 * @autodoc
	 * @expressionId.hint ID of the expression, e.g. "loggedIn.global"
	 */
	public string function getExpressionText( required string expressionId ) {
		return $translateResource(
			  uri          = "rules.expressions.#arguments.expressionId#:text"
			, defaultValue = arguments.expressionId
		);
	}

	/**
	 * Returns the default label for an expression field. This label is used when
	 * an administrator has not yet configured the field after inserting an expression
	 * into their condition builder. e.g.
	 * \n
	 * > Choose an event
	 *
	 * @audotodoc
	 * @expressionId.hint ID of the expression who's field we want to get the label of
	 * @fieldName.hint    Name of the field
	 */
	public string function getDefaultFieldLabel( required string expressionId, required string fieldName ) {
		var defaultFieldLabel = $translateResource( uri="rules.fields:#arguments.fieldName#.label", defaultValue=arguments.fieldName );

		return $translateResource( uri="rules.expressions.#arguments.expressionId#:field.#arguments.fieldName#.label", defaultValue=defaultFieldLabel );
	}

	/**
	 * Evaluates an expression, returning true or false,
	 * using the passed context, payload and field configuration.
	 *
	 * @autodoc
	 * @expressionId.hint     The ID of the expression to evaluate
	 * @context.hint          The context in which the expression is being evaluated. e.g. 'request', 'workflow' or 'marketing-automation'
	 * @payload.hint          A structure of data representing a payload against which the expression can be evaluated
	 * @configuredFields.hint A structure of fields configured for the expression instance being evaluated
	 */
	public boolean function evaluateExpression(
		  required string expressionId
		, required string context
		, required struct payload
		, required struct configuredFields
	) {
		var expression = _getRawExpression( expressionId );
		var contexts   = expression.contexts ?: [];

		if ( !contexts.findNoCase( arguments.context ) && !contexts.findNoCase( "global" ) ) {
			throw(
				  type    = "preside.rule.expression.invalid.context"
				, message = "The expression [#arguments.expressionId#] cannot be used in the [#arguments.context#] context."
			);
		}

		var handlerAction = "rules.expressions." & arguments.expressionId & ".evaluateExpression";
		var eventArgs     = { context=arguments.context, payload=arguments.payload };

		eventArgs.append( preProcessConfiguredFields( arguments.expressionId, arguments.configuredFields ) );

		var result = $getColdbox().runEvent(
			  event          = handlerAction
			, private        = true
			, prePostExempt  = true
			, eventArguments = eventArgs
		);

		return result;
	}

	/**
	 * Validates a configured expression for a given context.
	 * Returns true if valid, false otherwise and sets specific
	 * error messages using the passed [[api-validationresult]] object.
	 *
	 * @autodoc
	 * @expressionId.hint     ID of the expression to validate
	 * @fields.hint           Struct of saved field configurations for the expression instance to validate
	 * @context.hint          Context in which the expression is being used
	 * @validationResult.hint [[api-validationresult]] object with which to record errors
	 *
	 */
	public boolean function isExpressionValid(
		  required string expressionId
		, required struct fields
		, required string context
		, required any    validationResult
	) {
		var expression = _getRawExpression( arguments.expressionId, false );

		if ( expression.isEmpty() ) {
			arguments.validationResult.setGeneralMessage( "The [#arguments.expressionId#] expression could not be found" );
			return false;
		}

		if ( !expression.contexts.findNoCase( arguments.context ) && !expression.contexts.findNoCase( "global" ) ) {
			arguments.validationResult.setGeneralMessage( "The [#arguments.expressionId#] expression cannot be used in the [#arguments.context#] context" );
			return false;
		}

		for ( var fieldName in expression.fields ) {
			var field    = expression.fields[ fieldName ];
			var required = IsBoolean( field.required ?: "" ) && field.required;

			if ( required && IsEmpty( arguments.fields[ fieldName ] ?: "" ) ) {
				arguments.validationResult.setGeneralMessage( "The [#arguments.expressionId#] expression is missing one or more required fields" );
				return false;
			}
		}

		return true;
	}

	/**
	 * Accepts an expressionId and saved field configuration
	 * and preprocesses all the field values ready for evaluation.
	 *
	 * @autodoc
	 * @expressionId.hint     ID of the expression who's fields are configured
	 * @configuredFields.hint Saved field configuration for the expression instance
	 *
	 */
	public struct function preProcessConfiguredFields( required string expressionId, required struct configuredFields ) {
		var expression       = _getRawExpression( arguments.expressionId );
		var expressionFields = expression.fields ?: {};
		var fieldTypeService = _getFieldTypeService();
		var processed        = {};

		for( var fieldName in configuredFields ) {
			if ( expressionFields.keyExists( fieldName ) ) {
				configuredFields[ fieldName ] = fieldTypeService.prepareConfiguredFieldData(
					  fieldType          = expressionFields[ fieldName ].fieldType
					, fieldConfiguration = expressionFields[ fieldName ]
					, savedValue         = configuredFields[ fieldName ]
				);
			}
		}

		return configuredFields;
	}

// PRIVATE HELPERS
	private struct function _getRawExpression( required string expressionid, boolean throwOnMissing=true ) {
		var expressions = _getExpressions();

		if ( expressions.keyExists( arguments.expressionId ) ) {
			return expressions[ arguments.expressionId ];
		}

		if ( !arguments.throwOnMissing ) {
			return {};
		}

		throw( type="preside.rule.expression.not.found", message="The expression [#arguments.expressionId#] could not be found." );
	}

// GETTERS AND SETTERS
	private struct function _getExpressions() {
		return _expressions;
	}
	private void function _setExpressions( required struct expressions ) {
		_expressions = arguments.expressions;
	}

	private any function _getFieldTypeService() {
		return _fieldTypeService;
	}
	private void function _setFieldTypeService( required any fieldTypeService ) {
		_fieldTypeService = arguments.fieldTypeService;
	}
}