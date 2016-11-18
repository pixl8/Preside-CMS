/*
evaluateExpression
prepareFilters
getLabel
getText
*/
/**
 * Expression handler for "User is / is not IP Logbook candidate"
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

		return presideObjectService.$dataExists(
			  objectName   = objectName
			, filter       = "#objectname#.id = :id and #objectName#.#propertyName# #isIsNot# null"
			, filterParams = { id=recordId }
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          boolean _is     = true
		,          string  variety = "isEmpty"
	){
		var isIsNot  = ( _is == ( variety == "isEmpty" ) ) ? "is" : "is not";

		return [ { filter="#objectName#.#propertyName# #isIsNot# null" } ];
	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		,          string  variety = "isEmpty"
	) {
		var objectBaseUri = presideObjectService.getResourceBundleUriRoot( objectName );
		var properyName   = translateResource( objectBaseUri & "field.#propertyName#.title", propertyName );

		return translateResource( uri="rules.dynamicExpressions:propertyIsNull.#variety#.label", data=[ propertyName ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		,          string variety = "isEmpty"
	){
		var objectBaseUri = presideObjectService.getResourceBundleUriRoot( objectName );
		var properyName   = translateResource( objectBaseUri & "field.#propertyName#.title", propertyName );

		return translateResource( uri="rules.dynamicExpressions:propertyIsNull.#variety#.text", data=[ propertyName ] );
	}

}