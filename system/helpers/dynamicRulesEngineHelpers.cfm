<cffunction name="getExistsFilterForEntityMatchingFilters" access="public" returntype="struct" output="false">
	<cfargument name="objectName"  type="string" required="true" />
	<cfargument name="savedFilter" type="string" required="true" />
	<cfargument name="outerTable"  type="string" required="true" />
	<cfargument name="outerKey"    type="string" required="true" />

	<cfscript>
		var filter         = {};
		var filterService  = getSingleton( "rulesEngineFilterService" );
		var poService      = getSingleton( "presideObjectService" );
		var outerJoin      = "#outerTable#.#outerKey# = #arguments.objectName#.#poService.getIdField( arguments.objectName )#";
		var subQueryFilter = filterService.prepareFilter( arguments.objectName, arguments.savedFilter );
		var subQuery       = poService.selectData(
			  objectName          = arguments.objectName
			, selectFields        = [ "1" ]
			, extraFilters        = [ subQueryFilter ]
			, filter              = obfuscateSqlForPreside( outerjoin )
			, getSqlAndParamsOnly = true
			, formatSqlParams     = true
		);

		filter.filter = obfuscateSqlForPreside( "exists (#subQuery.sql#)" );
		filter.filterparams = subQuery.params;

		return filter;
	</cfscript>
</cffunction>

<cffunction name="rulesEngineNumericOperatorToSqlOperator" access="public" returntype="any" output="false">
	<cfargument name="operator" type="string" required="true" />
	<cfscript>
		switch ( arguments.operator ) {
			case "neq":
				return "!=";
			case "gt":
				return ">";
			case "gte":
				return ">=";
			case "lt":
				return "<";
			case "lte":
				return "<=";
		}

		return "=";
	</cfscript>
</cffunction>