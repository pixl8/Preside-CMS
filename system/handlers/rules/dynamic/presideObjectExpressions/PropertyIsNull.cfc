/**
 * Dynamic expression handler for checking whether or not a preside object
 * property value is null
 *
 * @feature rulesEngine
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          boolean _is     = true
		,          string  variety = "isEmpty"
	) {
		return presideObjectService.dataExists(
			  objectName   = arguments.objectName
			, id           = payload[ arguments.objectName ].id ?: ""
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          boolean _is     = true
		,          string  variety = "isEmpty"
	){
		var isIsNot  = ( _is == ( variety == "isEmpty" ) ) ? "is" : "is not";

		return [ { filter="#arguments.objectName#.#arguments.propertyName# #isIsNot# null" } ];
	}

	private string function getLabel(
		  required string objectName
		, required string propertyName
		,          string variety = "isEmpty"
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );
			return translateResource( uri="rules.dynamicExpressions:related.propertyIsNull.#variety#.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:propertyIsNull.#variety#.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		,          string variety = "isEmpty"
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = super._getExpressionPrefix( argumentCollection=arguments );

			return translateResource( uri="rules.dynamicExpressions:related.propertyIsNull.#variety#.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:propertyIsNull.#variety#.text", data=[ propNameTranslated ] );
	}
}