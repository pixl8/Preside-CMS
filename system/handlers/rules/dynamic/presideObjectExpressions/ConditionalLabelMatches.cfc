/**
 * @feature rulesEngine and customFields
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="customFieldsService" inject="customFieldsService";
	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string objectName
		, required string propertyName
		,          string enumValue = ""
	) {
		return presideObjectService.dataExists(
			  objectName   = arguments.objectName
			, id           = payload[ arguments.objectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string objectName
		, required string propertyName
		,          string enumValue = ""
	) {
		var fieldId = presideObjectService.getObjectPropertyAttribute(
			  objectName    = arguments.objectName
			, propertyName  = arguments.propertyName
			, attributeName = "customFieldId"
			, defaultValue  = ""
		);

		if ( !Len( Trim( fieldId ) ) || !Len( Trim( arguments.enumValue ) ) ) {
			return [ { filter="1=0" } ];
		}

		return [ customFieldsService.prepareConditionalLabelFilter(
			  objectName = arguments.objectName
			, fieldId    = fieldId
			, ruleId     = arguments.enumValue
		) ];
	}

	private string function getLabel(
		  required string objectName
		, required string propertyName
	) {
		return translateObjectProperty( arguments.objectName, arguments.propertyName );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
	) {
		return translateObjectProperty( arguments.objectName, arguments.propertyName );
	}

}
