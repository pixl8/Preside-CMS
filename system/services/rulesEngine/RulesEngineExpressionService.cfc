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
	 * @expressionDirectories.inject   presidecms:directories:/handlers/rules/expressions
	 *
	 */
	public any function init( required any expressionReaderService, required array expressionDirectories ) {
		_setExpressions( expressionReaderService.getExpressionsFromDirectories( expressionDirectories ) )

		return this;
	}

// PUBLIC API
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
		var expressions = _getExpressions();

		if ( !expressions.keyExists( arguments.expressionId ) ) {
			throw( type="preside.rule.expression.not.found", message="The expression [#arguments.expressionId#] could not be found." );
		}

		var expression  = Duplicate( expressions[ arguments.expressionId ] );

		expression.label = getExpressionLabel( expressionId );
		expression.text  = getExpressionText( expressionId );

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

// GETTERS AND SETTERS
	private struct function _getExpressions() {
		return _expressions;
	}
	private void function _setExpressions( required struct expressions ) {
		_expressions = arguments.expressions;
	}
}