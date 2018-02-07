/**
 * Base object for auto generated rules engine condition handlers. See /system/handlers/rules/dynamic/presideObjectExpressions/*.cfc
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private string function _getExpressionPrefix(
		  required string objectName
		, required string parentObjectName
		, required string parentPropertyName
	) {
		var objectBaseUri            = presideObjectService.getResourceBundleUriRoot( parentObjectName );
		var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
		var alternativeParentNameUri = objectBaseUri & "filter.prefix." & parentPropertyname.replace( "$", ".", "all" );

		return translateResource( uri=alternativeParentNameUri, defaultValue=parentPropNameTranslated );
	}

}