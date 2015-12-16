component singleton=true {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function escapeEntity( required string entityName ) {
		var escaped = "";
		var checkDot = FindNoCase(".", entityName, 1);
		if(checkDot) {
				var indexOfDot = checkDot;
				var tempCol 	 = Mid(entityName, indexOfDot + 1, Len(entityName));
				escaped = Replace(entityName, "." & tempCol, ".[" & tempCol & "]", "one");
		}
		else {
				switch (arguments.entityName) {
						case "user":
						case "key":
						case "read":
								escaped = "[#arguments.entityName#] ";
								break;
						default:
								escaped = "#arguments.entityName# ";
								break;
				}
		}

		return escaped;
	}

	public string function getColumnDefinitionSql(
		  required string   columnName
		, required string   dbType
		,          numeric  maxLength     = 0
		,          boolean  nullable      = true
		,          boolean  primaryKey    = false
		,          boolean  autoIncrement = false

	) {

		var columnDef  = escapeEntity( arguments.columnName )
		var isNullable = not arguments.primaryKey and ( arguments.nullable or StructKeyExists( arguments, 'defaultValue' ) );

		switch(arguments.dbType) {
			case "boolean":
				columnDef &= "bit";
				break;
			case "timestamp":
				columnDef &= "datetime";
				break;
			case "longtext":
				columnDef &= "text";
				break;
			case "bigint":
			case "int":
			case "float":
			case "double":
			case "text":
				arguments.maxLength = 0;
				columnDef &= "#arguments.dbType#";
				break;
			default:
				columnDef &= "#arguments.dbType#";
				break;
		}

		if ( arguments.dbType eq "varchar" and not arguments.maxLength ) {
			arguments.maxLength = 200;
		}

		if ( arguments.maxLength ) {

			columnDef &= "(#arguments.maxLength#)";
		}

		columnDef &= ( isNullable ? " null" : " not null" );

		if ( arguments.autoIncrement ) {
			columnDef &= " IDENTITY(1,1)";
		}

		if ( arguments.primaryKey ) {
			columnDef &= " PRIMARY KEY";
		}

		return columnDef;
	}

	public string function getAlterColumnSql(
		  required string  tableName
		, required string  columnName
		, required string  dbType
		,          string  defaultValue
		,          numeric maxLength     = 0
		,          boolean nullable      = true
		,          boolean primaryKey    = false
		,          boolean autoIncrement = false
		,          string  newName       = arguments.columnName


	) {
		var columnDef = getColumnDefinitionSql(
			  columnName    = arguments.newName
			, dbType        = arguments.dbType
			, defaultValue  = arguments.defaultValue
			, maxLength     = arguments.maxLength
			, nullable      = arguments.nullable
			, autoIncrement = arguments.autoIncrement
		);

		return "alter table #escapeEntity( arguments.tableName )# alter column #columnDef#";
	}


	public string function getAddColumnSql(
		  required string  tableName
		, required string  columnName
		, required string  dbType
		,          string  defaultValue
		,          numeric maxLength     = 0
		,          boolean nullable      = true
		,          boolean primaryKey    = false
		,          boolean autoIncrement = false
	) {
		return "alter table #escapeEntity( arguments.tableName )# add #escapeEntity(arguments.columnName)#";
	}

	public string function getTableDefinitionSql( required string tableName, required string columnSql ) {
		return "create table #escapeEntity( arguments.tableName )# ( #arguments.columnSql# )";
	}

	public string function getForeignKeyConstraintSql(
		  required string sourceTable
		, required string sourceColumn
		, required string constraintName
		, required string foreignTable
		, required string foreignColumn
		,          string onDelete = "set null"
		,          string onUpdate = "cascade"
	) {
		var sql = "alter table #escapeEntity( arguments.sourceTable )#";

		sql &= " add constraint #escapeEntity( arguments.constraintName )#";
		sql &= " foreign key ( #escapeEntity( arguments.sourceColumn )# )";
		sql &= " references #escapeEntity( arguments.foreignTable )# ( #escapeEntity( arguments.foreignColumn )# )";
		if ( arguments.onDelete neq "error" ) {
			// sql &= " on delete #arguments.onDelete eq 'cascade' ? 'cascade' : 'set null'#";
		}
		if ( arguments.onUpdate neq "error" ) {
			// sql &= " on update #arguments.onUpdate eq 'cascade' ? 'cascade' : 'set null'#";
		}
		return sql;
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) {
		return "alter table #escapeEntity( arguments.tableName )# drop constraint #escapeEntity( arguments.foreignKeyName )#";
	}

	public string function getIndexSql(
		  required string  indexName
		, required string  tableName
		, required string  fieldList
		,          boolean unique=false

	) {
		var fields = ListToArray( arguments.fieldList );
		var field  = "";
		var sql    = "create ";
		var delim  = "";

		if ( arguments.unique ) {
			sql &= "unique ";
		}

		sql &= "index #escapeEntity( arguments.indexName)# on #escapeEntity( arguments.tableName )# (";

		for( field in fields ){
			sql &= delim & " " & escapeEntity( field );
			delim = ",";
		}

		sql &= " )";
		return sql;
	}

	public string function getDropIndexSql( required string indexName, required string tableName ) {
		return "drop index #escapeEntity( arguments.tableName )#.#escapeEntity( arguments.indexName )#";
	}

	public string function getUpdateSql(
		  required string tableName
		, required array  updateColumns
		, required any    filter
		,          string tableAlias = ""
		,          array  joins      = []
	) {
		var sql      = "update #escapeEntity( arguments.tableName )#";
		var delim    = "";
		var col      = "";
		var entity   = "";
		var hasAlias = Len( Trim( arguments.tableAlias ) );

		if ( ArrayLen( arguments.joins ) ) {
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, joins      = arguments.joins
			);
		}

		sql &= " set";

		for( col in arguments.updateColumns ) {
			entity = hasAlias and ListLen( col, '.' ) eq 1 ? "#col#" : col;
			sql &= delim & " " & escapeEntity( entity ) & " = :set__" & col;
			delim = ",";
		}

		if(Len(arguments.tableAlias)) {
			sql &= " from #arguments.tableName# as #arguments.tableAlias# ";
		}

		sql &= getClauseSql(
			filter     = arguments.filter,
			tableAlias = ""
		);

		return parseMysqlFuncToMsSqlFunc(sql);
	}

	public string function getDeleteSql( required string tableName, required any filter, string tableAlias="" ) {
		var sql = "delete from #escapeEntity( arguments.tableName )# "
		return sql & getClauseSql(
		  	filter = arguments.filter
		);
	}

	public array function getInsertSql( required string tableName, required array insertColumns, numeric noOfRows=1 ) {
		var sql          = "insert into #escapeEntity( arguments.tableName )# (";
		var delim        = " ";
		var rowdelim     = " (";
		var col          = "";
		var i            = "";
		var paramPostFix = "";

		for( col in arguments.insertColumns ){
			sql &= delim & escapeEntity( col );
			delim = ", ";
		}

		sql &= " ) values";

		for( i=1; i lte arguments.noOfRows; i++ ){
			sql &= rowDelim;
			rowDelim = " ), (";
			if ( arguments.noOfRows gt 1 ){
				paramPostFix = "_" & i;
			}

			delim = " ";
			for( col in arguments.insertColumns ){
				sql &= delim & ":" & col & paramPostFix;
				delim = ", ";
			}
		}

		sql &= " )";
		return [ sql ];
	}

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

	) {
		var newGroupBy  = "";
		var sql         = "select";
		var delim       = " ";
		var col         = "";

		for( col in arguments.selectColumns ){
				if(Len(Trim(arguments.tableAlias)) && !FindNoCase(".", col,1) && Len(col) > 1 && !checkAggregateFunction(col)) {
						sql &= delim & arguments.tableAlias & "." & col;
				}
				else {
					sql &= delim & col;
				}
				delim = ", ";
		}
		if ( checkAggregateFunction(sql) ) {
				delim = " ";
				for( col in arguments.selectColumns ){
					if ( !checkAggregateFunction("#col#") ) {
						newGroupBy &= delim & REReplace(col, "as\s\w+", "", "one");
						delim = ", ";
					}
				}
		}

		if ( arguments.maxRows ) {
				if ( Len( Trim ( arguments.orderBy ) ) ) {
						if ( !checkAggregateFunction(sql) ) {
							sql &= ", row_number() over (order by " & arguments.orderBy & ") as row ";
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
			if ( checkAggregateFunction(sql) ==  true ) {
					sql &= " group by " & newGroupBy;
			}
			else {
					sql = reCompileGroupByForMsSql(sql, arguments.selectColumns, arguments.groupBy, arguments.tableAlias);
			}
		}

		if ( Len( Trim ( arguments.orderBy ) )  && !arguments.maxRows) {
			if ( !checkAggregateFunction(sql) ) {
				sql &= " order by " & arguments.orderBy;
			}
		}

		if ( arguments.maxRows ) {
				if ( Len( Trim ( arguments.orderBy ) ) ) {
						sql = "select * from ( " & sql & " ) as Temp where row > #arguments.startRow-1# and row <= #arguments.maxRows#";
				}
				else {
					sql = Replace(sql, "select", "select top #arguments.maxRows#", "one");
				}
		}

		return parseMysqlFuncToMsSqlFunc(sql);
	}

	public string function getJoinSql( required string tableName, string tableAlias="", array joins=[] ) {
		var aliases     = {};
		var join        = "";
		var requiredCol = "";
		var sql         = "";

		aliases[ arguments.tableName ] = Len( arguments.tableAlias ) ? escapeEntity( arguments.tableAlias ) : escapeEntity( arguments.tableName );

		for( join in arguments.joins ){
			param name="join.tableAlias" default="";

			for( requiredCol in ["tableName","tableColumn","joinToTable","joinToColumn"] ) {
				if ( not StructKeyExists( join, requiredCol ) ){
					throw( type="MySqlAdapter.missingJoinParams", detail="[#requiredCol#] was not supplied", message="Missing param in supplied join. Required params are [tableName], [tableColumn], [joinToTable] and [joinToColumn]" );
				}
			}

			if ( !Len( join.tableAlias ) ) {
				aliases[ join.tableName & join.joinToColumn ] = escapeEntity( join.tableName );
			}
			aliases[ join.joinToTable ] = escapeEntity( join.joinToTable );

		}
		for( join in arguments.joins ){
			sql &= " " & ( join.type eq "left" ? "left" : "inner" ) & " join " & escapeEntity( join.tableName );
			if ( Len( join.tableAlias ) ) {
				sql &= " " & escapeEntity( join.tableAlias );
				sql &= " on (" & escapeEntity( join.tableAlias ) & "." & escapeEntity( join.tableColumn );
			} else {
				sql &= " on (" & aliases[ join.tableName & join.joinToColumn ] & "." & escapeEntity( join.tableColumn );
			}

			sql &= " = " & aliases[ join.joinToTable ] & "." & escapeEntity( join.joinToColumn ) & ")";

			if ( Len( Trim( join.additionalClauses ?: "" ) ) ) {
				sql &= " and (" & join.additionalClauses & ")";
			}
		}
		return sql;
	}

	public string function getClauseSql( required any filter, string tableAlias="" ) {
		var sql      = "";
		var delim    = " where";
		var col      = "";
		var hasAlias = Len( Trim( arguments.tableAlias ) );
		var entity   = "";
		var i        = 0;
		var n        = 0;
		var paramName = "";
		var filterKeys = "";
		var dottedSqlParamRegex = "([$\s]:[a-zA-Z_][a-zA-Z0-9_]*)[\.\$]([a-zA-Z_][a-zA-Z0-9_]*([\s\),]|$))";

		if ( IsSimpleValue( arguments.filter ) ) {
			return delim & " " & ReReplace( arguments.filter, dottedSqlParamRegex, "\1__\2", "all" );
		}

		filterKeys = StructKeyArray( arguments.filter );

		ArraySort( filterKeys, "textnocase" );

		for( i=1; i lte ArrayLen( filterKeys ); i++ ) {
			col = filterKeys[i];
			entity = hasAlias and ListLen( col, "." ) eq 1 ? "#arguments.tableAlias#.#col#" : col;

			paramName = ReReplace( col, "[\.\$]", "__", "all" );

			sql &= delim & " " & escapeEntity( entity );

			if ( IsArray( arguments.filter[ col ] ) ) {
				sql &= " in ( :" & paramName & " )";
			} else {
				sql &= " = :" & paramName;
			}
			delim = " and";
		}
		return sql;
	}

	public numeric function getTableNameMaxLength() {
		return 64;
	}

	public string function sqlDataTypeToCfSqlDatatype( required string sqlDataType ) {
		switch( arguments.sqlDataType ){
			case "bigint signed":
			case "int unsigned":
			case "bigint":
				return "cf_sql_bigint";

			case "binary":
				return "cf_sql_binary";

			case "bit":
			case "bool":
			case "boolean":
				return "cf_sql_bit";

			case "blob":
				return "cf_sql_blob";

			case "char":
				return "cf_sql_char";

			case "date":
				return "cf_sql_date";

			case "decimal":
				return "cf_sql_decimal";

			case "double":
			case "double precision":
			case "real":
				return "cf_sql_double";

			case "mediumint signed":
			case "mediumint unsigned":
			case "int signed":
			case "mediumint":
			case "int":
			case "integer":
				return "cf_sql_integer";

			case "mediumblob":
			case "longblob":
			case "tinyblob":
				return "cf_sql_longvarbinary";

			case "text":
			case "mediumtext":
			case "longtext":
				return "cf_sql_clob";

			case "numeric":
			case "bigint unsigned":
				return "cf_sql_numeric";

			case "float":
				return "cf_sql_real";

			case "smallint signed":
			case "smallint unsigned":
			case "tinyint signed":
			case "tinyint":
			case "smallint":
				return "cf_sql_smallint";

			case "datetime":
			case "timestamp":
				return "cf_sql_timestamp";

			case "tinyint unsigned":
				return "cf_sql_tinyint";

			case  "varbinary":
				return "cf_sql_varbinary";

			case "varchar":
			case "tinytext":
			case "enum":
			case "set":
				return "cf_sql_varchar";

			default:
				return "cf_sql_varchar";
		}
	}

	public boolean function canToggleForeignKeyChecks() {
		return true;
	}

	public string function getToggleForeignKeyChecks( required boolean checksEnabled ) {
		return "set foreign_key_checks=" & ( arguments.checksEnabled ? '1' : '0' );
	}

	public string function getIfNullStatement( required string statement, required string alternativeStatement, required string alias ) {
		return "IsNull( #arguments.statement#, #arguments.alternativeStatement# ) as #arguments.alias#";
	}

	public boolean function doesColumnTypeRequireLengthSpecification( required string sqlDataType ) {
		switch( arguments.sqlDataType ){
			case "char":
			case "varchar":
				return true;
		}

		return false;
	}

	private string function parseMysqlFuncToMsSqlFunc(required string sql) {
			sql = REReplace(sql, "(L|l)ength\(", "Len(", "all");
			return sql;
	}

	private string function reCompileGroupByForMsSql(string sql, array select, string groupBy, string tableAlias) {
			var sqlNonGroupBy = arguments.sql;
			var strNonGroupBy		= Replace(arguments.groupBy, "group by", "", "all");
			var arrColumnInGroupBy = [];
			arrColumnInGroupBy 		 = ListToArray(strNonGroupBy, ", ");

			var newSql   = "select";
			var delim       = " ";
			var col         = "";
			for( col in arrColumnInGroupBy ){
					newSql &= delim & col;
					delim = ", ";
			}

			newSql = REReplace(arguments.sql, "select.*?from", newSql & " from ", "one");
			newSql = " , ( " & newSql & " group by "  & strNonGroupBy &" ) as Temp ";

			delim = " ";

			if(FindNoCase("where", sqlNonGroupBy, 1) > 0) {
					newSql = Replace(sqlNonGroupBy, "where", newSql & " where ", "one");
					for( col in arrColumnInGroupBy) {
						newSql &=" and " & col & " = " & " Temp." & REReplace(col, ".*?\.", "", "one");
					}
			}
			else {
					newSql &= " where ";
					for( col in arrColumnInGroupBy) {
						newSql &= delim & col & " = " & " Temp." & REReplace(col, ".*?\.", "", "one");
						delim = " and ";
					}
			}
			return newSql;
	}

	private boolean function checkAggregateFunction (string columnName) {
			return ( FindNoCase("Sum(", arguments.columnName, 1) > 0 || FindNoCase("Count(", arguments.columnName, 1) > 0 || FindNoCase("Min(", arguments.columnName, 1) > 0 || FindNoCase("Max(", arguments.columnName, 1) > 0 || FindNoCase("AVG(", arguments.columnName, 1) > 0 );
	}
}
