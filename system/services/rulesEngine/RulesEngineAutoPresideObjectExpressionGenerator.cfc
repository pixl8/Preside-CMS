/**
 * Service that provides logic for automatically generating rules
 * engine expressions from the preside object library.
 *
 * @autodoc        true
 * @singleton      true
 * @presideService true
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	/**
	 * Generates all the expressions for a given property (does the hard work)
	 *
	 */
	public array function generateExpressionsForProperty(
		  required string objectName
		, required struct propertyDefinition
	) {
		var isRequired  = IsBoolean( propertyDefinition.required ?: "" ) && propertyDefinition.required;
		var propType    = propertyDefinition.type ?: "string";
		var expressions = [];

		if ( !isRequired ) {
			if ( propType == "string" ) {
				expressions.append( _createStringIsEmptyExpression( objectName, propertyDefinition.name ) );
			}
		}

		return expressions;
	}

// PRIVATE HELPERS
	private struct function _createStringIsEmptyExpression( required string objectName, required string propertyName ) {
		var expression  = _getCommonExpressionDefinition( objectName, propertyName );

		expression.append( {
			  id                = "presideobject_textPropertyIsNull"
			, fields            = { _is={ fieldtype="boolean", variety="isIsNot" } }
			, expressionHandler = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
			, filterHandler     = "rules.dynamic.presideObjectExpressions.PropertyIsNull.evaluateExpression"
		} );

		return expression;
	}

	private struct function _getCommonExpressionDefinition( required string objectName, required string propertyName ){
		var i18nBaseUri = $getPresideObjectService().getResourceBundleUriRoot( objectName );

		return {
			  contexts              = [ "presideobject_" & objectName ]
			, filterObjects         = [ objectName ]
			, expressionHandlerArgs = { objectName=objectName, propertyName=propertyName }
			, filterHandlerArgs     = { objectName=objectName, propertyName=propertyName }
			, i18nLabelArgs         = [ i18nBaseUri & "title.singular", i18nBaseUri & "field.#propertyName#.title" ]
			, i18nTextArgs          = [ i18nBaseUri & "title.singular", i18nBaseUri & "field.#propertyName#.title" ]
		};
	}

}