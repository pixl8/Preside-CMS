/**
 * Dynamic expression handler for checking whether or not a preside object
 * record matches (or not) one or more saved filters
 *
 */
component extends="preside.system.base.AutoObjectExpressionHandler" {

	property name="presideObjectService"     inject="presideObjectService";
	property name="rulesEngineFilterService" inject="rulesEngineFilterService";

	private boolean function evaluateExpression(
		  required string  objectName
		,          string  value = ""
		,          boolean _does = true
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
		,          string  filterPrefix = ""
		,          string  value = ""
		,          boolean _does = true
	){
		var extraFilters = [];

		for( var filter in ListToArray( arguments.value ) ) {
			ArrayAppend( extraFilters, rulesEngineFilterService.prepareFilter( arguments.objectName, filter ) );
		}

		if ( !ArrayLen( extraFilters ) ) {
			return [];
		}

		var dbAdapter = getPresideObject( arguments.objectName ).getDbAdapter();
		var idField   = presideObjectService.getIdField( arguments.objectName );
		var subQuery  = presideObjectService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ idField ]
			, extraFilters        = extraFilters
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		var subQueryAlias      = dbAdapter.escapeEntity( "subquery_#arguments.objectName#" );
		var idFieldEscaped     = dbAdapter.escapeEntity( idField );
		var idFieldEscapedFull = dbAdapter.escapeEntity( "#arguments.objectName#.#idField#" );

		var exists      = arguments._does ? "exists" : "not exists";
		var subQuerySql = obfuscateSqlForPreside( "
			select #idFieldEscaped#
			from (#subQuery.sql#) as #subQueryAlias#
			where #idFieldEscapedFull# = #subQueryAlias#.#idField#
		" );

		return [ {
			  filter       = "#exists# (#subQuerySql#)"
			, filterParams = subQuery.params
		}];
	}

	private string function getLabel(
		  required string  objectName
		,          string  parentObjectName   = ""
		,          string  parentPropertyName = ""
	) {
		var objectLabelSingular = translateObjectName( arguments.objectName );

		return translateResource( uri="rules.dynamicExpressions:recordMatchesFilters.label", data=[ objectLabelSingular ] );
	}

	private string function getText(
		  required string objectName
		,          string parentObjectName   = ""
		,          string parentPropertyName = ""

	){
		var objectLabelSingular = translateObjectName( arguments.objectName );

		return translateResource( uri="rules.dynamicExpressions:recordMatchesFilters.text", data=[ objectLabelSingular ] );
	}

}