/**
 * Dynamic expression handler for checking whether or not a preside object
 * property value is within a given date range
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";

	private boolean function evaluateExpression(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          struct  _time
	) {
		var sourceObject = parentObjectName.len() ? parentObjectName : objectName;
		var recordId     = payload[ sourceObject ].id ?: "";

		return presideObjectService.dataExists(
			  objectName   = sourceObject
			, id           = recordId
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
		,          string  filterPrefix = ""
		,          struct  _time = {}
	){
		var params      = {};
		var sql         = "";
		var prefix      = filterPrefix.len() ? filterPrefix : ( parentPropertyName.len() ? parentPropertyName : objectName );
		var propertySql = "#prefix#.#propertyName#";
		var delim       = "";

		if ( IsDate( _time.from ?: "" ) ) {
			var fromParam = "datePropertyInRange" & CreateUUId().lCase().replace( "-", "", "all" );
			sql   = propertySql & " >= :#fromParam#";
			params[ fromParam ] = { value=_time.from, type="cf_sql_timestamp" };
			delim = " and ";
		}
		if ( IsDate( _time.to ?: "" ) ) {
			var toParam = "datePropertyInRange" & CreateUUId().lCase().replace( "-", "", "all" );
			sql   &= delim & propertySql & " <= :#toParam#";
			params[ toParam ] = { value=_time.to, type="cf_sql_timestamp" };
		}

		if ( Len( Trim( sql ) ) ) {
			return [ { filter=sql, filterParams=params } ];
		}

		return [];

	}

	private string function getLabel(
		  required string  objectName
		, required string  propertyName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.datePropertyInRange.label", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:datePropertyInRange.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		if ( Len( Trim( parentPropertyName ) ) ) {
			var parentPropNameTranslated = translateObjectProperty( parentObjectName, parentPropertyName, translateObjectName( objectName ) );
			return translateResource( uri="rules.dynamicExpressions:related.datePropertyInRange.text", data=[ propNameTranslated, parentPropNameTranslated ] );
		}

		return translateResource( uri="rules.dynamicExpressions:datePropertyInRange.text", data=[ propNameTranslated ] );
	}
}