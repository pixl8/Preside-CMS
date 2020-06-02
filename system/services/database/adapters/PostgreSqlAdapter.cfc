/**
 * @singleton
 *
 */
component extends="BaseAdapter" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function escapeEntity( required string entityName ) {
		var escaped = '"#lcase(arguments.entityName)#"';
		return Replace( escaped, '.', '"."', "all" );
	}

	public boolean function requiresManualCommitForTransactions(){
		return true;
	}

	public array function getInsertSql( required string tableName, required array insertColumns, numeric noOfRows=1 ) {
		var sql = super.getInsertSql( argumentCollection=arguments );
		sql[1] &= " RETURNING *";
		return sql;
	}

	public string function getInsertReturnType(){
		return 'recordset';
	}

	public string function getGeneratedKey(required any result){
		return arguments.result.id ?: "";
	}


	public string function getColumnDBType( required string dataType, string extraInfo ){
		if (arguments.extraInfo == "autoIncrement"){
			return "serial";
		} else {
			switch( arguments.dataType ) {
				case "datetime":
					return "timestamp";
				case "longtext":
					return "text";
				case "double":
					return "float";
				case "bit":
					return "bool";
				default:
					return arguments.dataType;
			}
		}
	}

	public string function getColumnDefinitionSql(
		  required string   columnName
		, required string   dbType
		,          numeric  maxLength     = 0
		,          boolean  nullable      = true
		,          boolean  primaryKey    = false
		,          boolean  autoIncrement = false

	) {

		var columnDef  = escapeEntity( arguments.columnName );
		var isNullable = not arguments.primaryKey and ( arguments.nullable or StructKeyExists( arguments, 'defaultValue' ) );

		if ( arguments.autoIncrement ) {
			   columnDef &= " serial";
			   arguments.maxLength = 0;
		} else {
		   switch( arguments.dbType ) {
				case "datetime":
				   columnDef &= " timestamp";
				   break;
				case "longtext":
				   columnDef &= " text";
				   break;
				case "double":
					   columnDef &= " float";
				case "bigint":
				case "int":
				case "float":
				case "text":
				   arguments.maxLength = 0;
				   columnDef &= " #arguments.dbType#";
				   break;
				default:
				   columnDef &= " #arguments.dbType#";
				   break;
			}
		}


		if ( arguments.dbType == "varchar" and not arguments.maxLength ) {
			arguments.maxLength = 200;
		}

		if ( arguments.maxLength ) {
			columnDef &= "(#arguments.maxLength#)";
		}

		if ( arguments.primaryKey ) {
			columnDef &= " primary key";
		}

		columnDef &= ( isNullable ? " null" : " not null" );

		return columnDef;
	}


	public numeric function getTableNameMaxLength() {
		return 63;
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
		var columnDef = getColumnDefinitionAlterSql(
			  columnName    = arguments.newName
			, dbType        = arguments.dbType
			, defaultValue  = arguments.defaultValue
			, maxLength     = arguments.maxLength
			, nullable      = arguments.nullable
			, autoIncrement = arguments.autoIncrement
		);

		if(structKeyExists(columnDef, "columnType")){
			var qAlter = "alter table " & escapeEntity( arguments.tableName ) &" alter column "& columnDef.columnType;
		}
		if(len(columnDef.columnSet)){
			qAlter &= ", alter column " & columnDef.columnSet;
		}
		return qAlter;
	}

	public string function getTableDefinitionSql( required string tableName, required string columnSql ) {
		return 'create table '& escapeEntity( arguments.tableName ) &' ( '& arguments.columnSql &' ) ';
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) {
		return "alter table "& escapeEntity( arguments.tableName ) &" drop constraint " & escapeEntity( arguments.foreignKeyName );
	}

	public string function getDropIndexSql( required string indexName, required string tableName ) {
		return "drop index " & escapeEntity( arguments.indexName );
	}

	public string function getUpdateSql(
		  required string tableName
		, required array  updateColumns
		, required any    filter
		,          string tableAlias = ""
		,          array  joins      = []
	) {


		var sql      			= "update "& escapeEntity( arguments.tableName );
		var delim    			= "";
		var col      			= "";
		var clauseSqlFromJoin	= "";
		var clauseSql 			= "";

		if ( Len( Trim( arguments.tableAlias ) ) ) {
			sql &= " " & escapeEntity( arguments.tableAlias );
		}
		sql &= " set";

		for( col in arguments.updateColumns ) {
			sql &= delim & " " & col & " = :set__" & col;
			delim = ",";
		}

		if ( ArrayLen( arguments.joins ) ) {

			var firstJoinTable = arguments.joins[1];
			sql &= " from #escapeEntity( firstJoinTable.tablename )# #escapeEntity( firstJoinTable.tablealias )#";
			clauseSqlFromJoin = " #escapeEntity( firstJoinTable.tablealias )#.#escapeEntity( firstJoinTable.tablecolumn )# = #escapeEntity( firstJoinTable.jointotable )#.#escapeEntity( firstJoinTable.jointocolumn )#";

			ArrayDeleteAt(arguments.joins,1);
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, tableAlias = arguments.tableAlias
				, joins      = arguments.joins
			);
		}

		clauseSql = getClauseSql(
			  tableAlias = arguments.tableAlias
			, filter     = arguments.filter
		);

		if ( Len(clauseSql) ){
			clauseSql &= len(clauseSqlFromJoin) ? ' and ' & clauseSqlFromJoin : '';
		} else {
			clauseSql &= len(clauseSqlFromJoin) ? ' where ' & clauseSqlFromJoin : '';
		}

		sql &= clauseSql;

		return sql;
	}

	public string function getDeleteSql( 
		  required string tableName
		, required any    filter
		,          string tableAlias = ""
		,          array  joins      = []
	) {
		var sql = "delete from "

		if(Len( Trim( arguments.tableAlias ) ) ) {
			sql &= escapeEntity( arguments.tableName ) & ' as ' & escapeEntity( arguments.tableAlias );
		} else {
			sql &= escapeEntity( arguments.tableName );
		}

		if ( ArrayLen( arguments.joins ) ) {
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, tableAlias = arguments.tableAlias
				, joins      = arguments.joins
			);
		}
		
		return sql & getClauseSql(
			  filter     = arguments.filter
			, tableAlias = arguments.tableAlias
		);
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

		sql &= " from " & escapeEntity( arguments.tableName ) ;
		if ( Len( arguments.tableAlias ) ) {
			sql &= " " & escapeEntity( arguments.tableAlias ) ;
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
				sql = reCompileGroupByForPostgreSql( sql, arguments.selectColumns, arguments.groupBy, arguments.tableAlias );
			}
		}

		if ( Len( Trim ( arguments.having ) ) ) {
			sql &= " having " & arguments.having;
		}

		if ( Len( Trim ( arguments.orderBy ) ) ) {
			sql &= " order by " & arguments.orderBy;
		}

		if ( arguments.maxRows ) {
			sql &= " limit " & arguments.maxRows & " offset " & arguments.startRow-1;
		}

		return sql;
	}

	public string function getIfNullStatement( required string statement, required string alternativeStatement, required string alias ) {
		return "IfNull( #arguments.statement#, #arguments.alternativeStatement# ) as #arguments.alias#";
	}

	public string function getToggleForeignKeyChecks(
		  required boolean checksEnabled
		, required string  tableName
	) {
		return "alter table "& escapeEntity(arguments.tableName) &" "&( arguments.checksEnabled ? 'enable' : 'disable' ) & " trigger all";
	}

		private string function reCompileGroupByForPostgreSql( string sql, array select, string groupBy, string tableAlias ) {
		var sqlNonGroupBy      = arguments.sql;
		var strNonGroupBy      = Replace( arguments.groupBy, "group by", "", "all" );
		var arrColumnInGroupBy = ListToArray( strNonGroupBy, ", " );
		var newSql             = "select";
		var delim              = " ";
		var col                = "";

		for( col in arrColumnInGroupBy ){
			newSql &= delim & col;
			delim  = ", ";
		}

		newSql = REReplace( arguments.sql, "select.*?from", newSql & " from ", "one" );
		newSql = " , ( " & newSql & " group by "  & strNonGroupBy & " ) as Temp ";
		delim = " ";

		if ( FindNoCase( "where", sqlNonGroupBy, 1 ) > 0 ) {
			newSql = Replace( sqlNonGroupBy, "where", newSql & " where ", "one" );
			for( col in arrColumnInGroupBy) {
				newSql &=" and " & col & " = " & " Temp." & REReplace( col, ".*?\.", "", "one" );
			}
		} else {
			newSql &= " where ";
			for( col in arrColumnInGroupBy ) {
				newSql &= delim & col & " = " & " Temp." & REReplace( col, ".*?\.", "", "one" );
				delim = " and ";
			}
		}

		return newSql;
	}

	private boolean function containsAggregateFunctions( required string sql ) {
		return ReFindNoCase( "\b(SUM|COUNT|AVG|MIN|MAX)\(", arguments.sql );
	}

	public string function getConcatenationSql( required string leftExpression, required string rightExpression ) {
		return "#leftExpression# || #rightExpression#";
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
				return "cf_sql_longvarchar";
			case "mediumtext":
			case "longtext":
				return "cf_sql_longvarchar";
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


	public boolean function supportsRenameInAlterColumnStatement() {
		return false;
	}

	public string function getRenameColumnSql( required string tableName, required string oldColumnName, required string newColumnName ) {
		return "alter table #escapeEntity( arguments.tableName )# rename #escapeEntity( arguments.oldColumnName )#  to #escapeEntity( arguments.newColumnName )#";
	}

	private struct function getColumnDefinitionAlterSql(
				 required string   columnName
			   , required string   dbType
			   ,          numeric  maxLength     = 0
			   ,          boolean  nullable      = true
			   ,          boolean  primaryKey    = false
			   ,          boolean  autoIncrement = false

	   ) {
			var columnAlter = structNew();
			var columnType  = escapeEntity( arguments.columnName );

			columnType &= " Type";

			var isNullable = not arguments.primaryKey and ( arguments.nullable or StructKeyExists( arguments, 'defaultValue' ) );

			if ( arguments.autoIncrement ) {
				// "serial" doesn't work for ALTER - it's just a convenience type for column creation
				columnType &= " int";
				arguments.maxLength = 0;
			} else {
				switch( arguments.dbType ) {
					case "datetime":
						columnType &= " timestamp";
						break;
					case "longtext":
						columnType &= " text";
						break;
					case "double":
						columnType &= " float";
					case "bigint":
					case "int":
					case "float":
					case "bit":
						arguments.maxLength = 0;
						columnType &= " #arguments.dbType# USING (#arguments.columnName#::::#arguments.dbType#)";
						break;
					case "text":
						arguments.maxLength = 0;
						columnType &= " #arguments.dbType#";
						break;
					default:
						columnType &= " #arguments.dbType#";
					break;
				}
			}

			if ( arguments.dbType == "varchar" and not arguments.maxLength ) {
				arguments.maxLength = 200;
			}

			if ( arguments.maxLength ) {
				columnType &= "(#arguments.maxLength#)";
			}

			if ( arguments.primaryKey ) {
				columnType &= " primary key";
			}

			columnAlter['columnSet'] = escapeEntity( arguments.columnName ) & ( isNullable ? " Drop not null" : " Set not null" );
			columnAlter['columnType'] = columnType;
			return columnAlter;
	}

	public string function getDatabaseNameSql() {
		return "select current_database() as db";
	}

	public string function getAllForeignKeysSql() {
		return "select tc.table_name       as table_name
	                 , kcu.column_name    as column_name
	                 , ccu.table_name     as referenced_table_name
	                 , ccu.column_name    as referenced_column_name
	                 , tc.constraint_name as constraint_name
	           from information_schema.table_constraints as tc
	           join information_schema.key_column_usage  as kcu
	             on tc.constraint_name = kcu.constraint_name
	            and tc.table_schema    = kcu.table_schema
	           join information_schema.constraint_column_usage as ccu
	             on ccu.constraint_name = tc.constraint_name
	            and ccu.table_schema    = tc.table_schema
	           where constraint_type = 'foreign key'";
	}
}