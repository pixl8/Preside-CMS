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
		,          struct  _time
	) {
		var recordId = payload[ objectName ].id ?: "";

		return presideObjectService.$dataExists(
			  objectName   = objectName
			, id           = recordId
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	private array function prepareFilters(
		  required string  objectName
		, required string  propertyName
		,          string  filterPrefix = ""
		,          struct  _time = {}
	){
		var params      = {};
		var sql         = "";
		var prefix      = filterPrefix.len() ? filterPrefix : objectName;
		var propertySql = "#prefix#.#propertyName#";
		var delim       = "";

		if ( IsDate( _time.from ?: "" ) ) {
			var fromParam = "datePropertyInRange" & CreateUUId().lCase().replace( "-", "", "all" );
			sql   = propertySql & ">= :#fromParam#";
			params[ fromParam ] = { value=_time.from, type="cf_sql_timestamp" };
			delim = " and ";
		}
		if ( IsDate( _time.to ?: "" ) ) {
			var toParam = "datePropertyInRange" & CreateUUId().lCase().replace( "-", "", "all" );
			sql   &= delim & propertySql & "<= :#toParam#";
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
	) {
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:datePropertyInRange.label", data=[ propNameTranslated ] );
	}

	private string function getText(
		  required string objectName
		, required string propertyName
	){
		var propNameTranslated = translateObjectProperty( objectName, propertyName );

		return translateResource( uri="rules.dynamicExpressions:datePropertyInRange.text", data=[ propNameTranslated ] );
	}
}