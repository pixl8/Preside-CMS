/**
 * @singleton
 *
 */
component extends="MsSqlAdapter" {

// PUBLIC API METHODS
	public string function getSelectSql(
		  required string  tableName
		, required array   selectColumns
		,          any     filter        = {}
		,          string  orderBy       = ""
		,          string  groupBy       = ""
		,          string  tableAlias    = ""
		,          array   joins         = []
		,          numeric maxRows       = 0
		,          numeric startRow      = 1
		,          boolean distinct      = false

	) {
		var sql   = arguments.distinct ? "select distinct" : "select";
		var delim = " ";
		var col   = "";

		for( col in arguments.selectColumns ){
			sql &= delim & col;
			delim = ", ";
		}

		sql &= " from " & escapeEntity( arguments.tableName );
		if ( Len( arguments.tableAlias ) ) {
			sql &= " " & escapeEntity( arguments.tableAlias );
		}

		if ( ArrayLen( arguments.joins ) ) {
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, tableAlias = arguments.tableAlias
				, joins      = arguments.joins
			);
		}

		sql &= getClauseSql( tableAlias = arguments.tableAlias, filter = arguments.filter );

		if ( Len( Trim ( arguments.groupBy ) ) ) {
			sql &= " group by " & arguments.groupBy;
		}

		if ( Len( Trim ( arguments.having ) ) ) {
			sql &= " having " & arguments.having;
		}

		if ( Len( Trim( arguments.orderBy ) ) ) {
			sql &= " order by " & arguments.orderBy;
		}

		if ( arguments.maxRows ) {
			if ( IsEmpty( Trim( arguments.orderBy ) ) ) {
				// using offset/fetch requires 'order by'
				sql &= " order by 1";
			}
			sql &= " offset #arguments.startRow-1# rows fetch next #arguments.maxRows# rows only";
		}

		return sql;
	}

	public string function getConcatenationSql( required string leftExpression, required string rightExpression ) {
		return "Concat( #leftExpression#, #rightExpression# )";
	}
}