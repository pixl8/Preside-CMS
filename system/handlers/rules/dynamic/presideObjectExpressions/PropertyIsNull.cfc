/**
 * Dynamic expression handler for checking whether or not a preside object
 * property value is null
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is     = true
		,          string  variety = "isEmpty"
	) {
		var recordId = payload[ objectName ].id ?: "";
		var isIsNot  = ( _is && variety == "isEmpty" ) ? "is" : "is not";

		return presideObjectService.dataExists(
			  objectName   = objectName
			, filter       = "#objectname#.id = :id and #objectName#.#propertyName# #isIsNot# null"
			, filterParams = { id=recordId }
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          string  filterPrefix = ""
		,          boolean _is     = true
		,          string  variety = "isEmpty"
	){
		var prefix = filterPrefix.len() ? filterPrefix : objectName;
		var isIsNot  = ( _is == ( variety == "isEmpty" ) ) ? "is" : "is not";

		return [ { filter="#prefix#.#propertyName# #isIsNot# null" } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		,          string  variety = "isEmpty"
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:propertyIsNull.#variety#.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		,          string variety = "isEmpty"
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:propertyIsNull.#variety#.text", data=[ propNameTranslated ] );
	}
}