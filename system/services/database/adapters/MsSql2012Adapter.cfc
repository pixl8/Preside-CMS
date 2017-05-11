/**
 * @singleton
 *
 */
component extends="MsSqlAdapter" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

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
		var newGroupBy  = "";
		var sql         = arguments.distinct ? "select distinct" : "select";
		var delim       = " ";
		var col         = "";

		for( col in arguments.selectColumns ){
			sql &= delim & col;
			delim = ", ";
		}
		if ( containsAggregateFunctions( sql ) ) {
			delim = " ";
			for( col in arguments.selectColumns ){
				if ( !containsAggregateFunctions( col ) ) {
					newGroupBy &= delim & REReplace(col, "as\s\w+", "", "one");
					delim = ", ";
				}
			}
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
			if ( containsAggregateFunctions( sql ) ) {
				sql &= " group by " & newGroupBy;
			} else {
				sql = reCompileGroupByForMsSql( sql, arguments.selectColumns, arguments.groupBy, arguments.tableAlias );
			}
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
				sql &= " order by (select 0)";
			}
			sql &= " offset #arguments.startRow-1# rows fetch next #arguments.maxRows# rows only";
		}

		return sql;
	}
}