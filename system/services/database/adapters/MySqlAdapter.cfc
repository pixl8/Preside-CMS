component output=false singleton=true {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

// PUBLIC API METHODS
	public string function escapeEntity( required string entityName ) output=false {
		var escaped = "`#arguments.entityName#`";

		return Replace( escaped, ".", "`.`", "all" );
	}

	public string function getColumnDefinitionSql(
		  required string   columnName
		, required string   dbType
		,          string   defaultValue
		,          numeric  maxLength     = 0
		,          boolean  nullable      = true
		,          boolean  primaryKey    = false
		,          boolean  autoIncrement = false

	) output=false {

		var columnDef  = escapeEntity( arguments.columnName )
		var isNullable = not arguments.primaryKey and ( arguments.nullable or StructKeyExists( arguments, 'defaultValue' ) );

		columnDef &= " #arguments.dbType#";


		if ( arguments.dbType eq "varchar" and not arguments.maxLength ) {
			arguments.maxLength = 200;
		}

		if ( arguments.maxLength ) {
			columnDef &= "(#arguments.maxLength#)";
		}

		columnDef &= ( isNullable ? " null" : " not null" );

		if ( StructKeyExists( arguments, 'defaultValue' ) ) {
			columnDef &= " default " & arguments.defaultValue;
		}

		if ( arguments.autoIncrement ) {
			columnDef &= " auto_increment";
		}

		if ( arguments.primaryKey ) {
			columnDef &= " primary key";
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


	) output=false {
		var columnDef = getColumnDefinitionSql(
			  columnName    = arguments.newName
			, dbType        = arguments.dbType
			, defaultValue  = arguments.defaultValue
			, maxLength     = arguments.maxLength
			, nullable      = arguments.nullable
			, autoIncrement = arguments.autoIncrement
		);

		return "alter table #escapeEntity( arguments.tableName )# change #escapeEntity( arguments.columnName )# #columnDef#";
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
	) output=false {
		var columnDef = getColumnDefinitionSql( argumentCollection = arguments );

		return "alter table #escapeEntity( arguments.tableName )# add #columnDef#";
	}

	public string function getTableDefinitionSql( required string tableName, required string columnSql ) output=false {
		return "create table #escapeEntity( arguments.tableName )# ( #arguments.columnSql# ) ENGINE=InnoDB";
	}

	public string function getForeignKeyConstraintSql(
		  required string sourceTable
		, required string sourceColumn
		, required string constraintName
		, required string foreignTable
		, required string foreignColumn
		,          string onDelete = "set null"
		,          string onUpdate = "cascade"
	) output=false {
		var sql = "alter table #escapeEntity( arguments.sourceTable )#";

		sql &= " add constraint #escapeEntity( arguments.constraintName )#";
		sql &= " foreign key ( #escapeEntity( arguments.sourceColumn )# )";
		sql &= " references #escapeEntity( arguments.foreignTable )# ( #escapeEntity( arguments.foreignColumn )# )";
		if ( arguments.onDelete neq "error" ) {
			sql &= " on delete #arguments.onDelete eq 'cascade' ? 'cascade' : 'set null'#";
		}
		if ( arguments.onUpdate neq "error" ) {
			sql &= " on update #arguments.onUpdate eq 'cascade' ? 'cascade' : 'set null'#";
		}

		return sql;
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) output=false {
		return "alter table #escapeEntity( arguments.tableName )# drop foreign key #escapeEntity( arguments.foreignKeyName )#";
	}

	public string function getIndexSql(
		  required string  indexName
		, required string  tableName
		, required string  fieldList
		,          boolean unique=false

	) output=false {
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

	public string function getDropIndexSql( required string indexName, required string tableName ) output=false {
		return "alter table #escapeEntity( arguments.tableName )# drop index #escapeEntity( arguments.indexName )#";
	}

	public string function getUpdateSql(
		  required string tableName
		, required array  updateColumns
		, required any    filter
		,          string tableAlias = ""
		,          array  joins      = []
	) output=false {
		var sql      = "update #escapeEntity( arguments.tableName )#";
		var delim    = "";
		var col      = "";
		var entity   = "";
		var hasAlias = Len( Trim( arguments.tableAlias ) );

		if ( Len( Trim( arguments.tableAlias ) ) ) {
			sql &= " " & escapeEntity( arguments.tableAlias );
		}
		if ( ArrayLen( arguments.joins ) ) {
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, tableAlias = arguments.tableAlias
				, joins      = arguments.joins
			);
		}

		sql &= " set";

		for( col in arguments.updateColumns ) {
			entity = hasAlias and ListLen( col, '.' ) eq 1 ? "#arguments.tableAlias#.#col#" : col;
			sql &= delim & " " & escapeEntity( entity ) & " = :set__" & col;
			delim = ",";
		}

		sql &= getClauseSql(
			  tableAlias = arguments.tableAlias
			, filter     = arguments.filter
		);

		return sql;
	}

	public string function getDeleteSql( required string tableName, required any filter, string tableAlias="" ) output=false {
		var sql = "delete from "

		if ( Len( Trim( arguments.tableAlias ) ) ) {
			sql &= "#escapeEntity( arguments.tableAlias )# using #escapeEntity( arguments.tableName )# as #escapeEntity( arguments.tableAlias )#";
		} else {
			sql &= " #escapeEntity( arguments.tableName )#";
		}

		return sql & getClauseSql(
			  filter     = arguments.filter
			, tableAlias = arguments.tableAlias
		);
	}

	public array function getInsertSql( required string tableName, required array insertColumns, numeric noOfRows=1 ) output=false {
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

	) output=false {
		var sql         = "select";
		var delim       = " ";
		var col         = "";

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

		if ( Len( Trim ( arguments.orderBy ) ) ) {
			sql &= " order by " & arguments.orderBy;
		}

		if ( arguments.maxRows ) {
			sql &= " limit #arguments.startRow-1#, #arguments.maxRows#";
		}

		return sql;
	}

	public string function getJoinSql( required string tableName, string tableAlias="", array joins=[] ) output=false {
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

			aliases[ join.tableName ] = Len( join.tableAlias ) ? escapeEntity( join.tableAlias ) : escapeEntity( join.tableName );
			aliases[ join.joinToTable ] = escapeEntity( join.joinToTable );

		}
		for( join in arguments.joins ){
			sql &= " " & ( join.type eq "left" ? "left" : "inner" ) & " join " & escapeEntity( join.tableName );
			if ( Len( join.tableAlias ) ) {
				sql &= " " & aliases[ join.tableName ];
			}
			sql &= " on (" & aliases[ join.tableName ] & "." & escapeEntity( join.tableColumn );
			sql &= " = " & aliases[ join.joinToTable ] & "." & escapeEntity( join.joinToColumn ) & ")";

			if ( Len( Trim( join.additionalClauses ?: "" ) ) ) {
				sql &= " and (" & join.additionalClauses & ")";
			}
		}

		return sql;
	}

	public string function getClauseSql( required any filter, string tableAlias="" ) output=false {
		var sql      = "";
		var delim    = " where";
		var col      = "";
		var hasAlias = Len( Trim( arguments.tableAlias ) );
		var entity   = "";
		var i        = 0;
		var n        = 0;
		var paramName = "";
		var filterKeys = "";
		var dottedSqlParamRegex = "([$\s]:[a-zA-Z_][a-zA-Z0-9_]*)\.([a-zA-Z_][a-zA-Z0-9_]*([\s\),]|$))";

		if ( IsSimpleValue( arguments.filter ) ) {
			return delim & " " & ReReplace( arguments.filter, dottedSqlParamRegex, "\1__\2", "all" );
		}

		filterKeys = StructKeyArray( arguments.filter );

		ArraySort( filterKeys, "textnocase" );

		for( i=1; i lte ArrayLen( filterKeys ); i++ ) {
			col = filterKeys[i];
			entity = hasAlias and ListLen( col, "." ) eq 1 ? "#arguments.tableAlias#.#col#" : col;
			paramName = Replace( col, ".", "__", "all" );
			sql &= delim & " " & escapeEntity( entity );

			if ( IsArray( arguments.filter[ col ] ) ) {
				sql &= " in (";
				for( n=1; n lte ArrayLen( arguments.filter[ col ] ); n++ ){
					if ( n gt 1 ){
						sql &= ",";
					}
					sql &= " :" & paramName & "__#n#";
				}

				sql &= " )";
			} else {
				sql &= " = :" & paramName;
			}
			delim = " and";
		}

		return sql;
	}

	public numeric function getTableNameMaxLength() output=false {
		return 64;
	}

	public string function sqlDataTypeToCfSqlDatatype( required string sqlDataType ) output=false {
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
}