component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function escapeEntity( required string entityName ) {
		return arguments.entityName;
	}


	public boolean function requiresManualCommitForTransactions(){
		return false;
	}

	public string function getInsertReturnType(){
		return 'info';
	}

	public string function getGeneratedKey(required any result){
		return arguments.result.generatedKey ?: "";
	}

	public string function getColumnDefinitionSql(
		  required string   columnName
		, required string   dbType
		,          numeric  maxLength     = 0
		,          boolean  nullable      = true
		,          boolean  primaryKey    = false
		,          boolean  autoIncrement = false

	) {
		return "getColumnDefinitionSql() not implemented. Must be implemented by extended adapters.";
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
		return "getAlterColumnSql() not implemented. Must be implemented by extended adapters.";
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
		var columnDef = getColumnDefinitionSql( argumentCollection = arguments );

		return "alter table #escapeEntity( arguments.tableName )# add #columnDef#";
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

		switch( arguments.onDelete ) {
			case 'error':
				break;
			case 'cascade':
			case 'cascade-if-no-cycle-check':
				sql &= " on delete cascade";
				break;
			case 'no action':
				sql &= " on delete no action";
				break;
			default:
				sql &= " on delete set null";
		}
		switch( arguments.onUpdate ) {
			case 'error':
				break;
			case 'cascade':
			case 'cascade-if-no-cycle-check':
				sql &= " on update cascade";
				break;
			case 'no action':
				sql &= " on update no action";
				break;
			default:
				sql &= " on update set null";
		}

		return sql;
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) {
		return "getDropForeignKeySql() not implemented. Must be implemented by extended adapters.";
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

		sql &= "index #escapeEntity( ensureValidIndexName ( arguments.indexName ) )# on #escapeEntity( arguments.tableName )# (";

		for( field in fields ){
			sql &= delim & " " & escapeEntity( field );
			delim = ",";
		}

		sql &= " )";

		return sql;
	}

	public string function ensureValidIndexName( required string indexName ) {
	    if ( len(arguments.indexName) < 64 ) {
	        return arguments.indexName;
	    }
	    return ReReplaceNoCase( arguments.indexName, "([ui]x_).*", "\1" & LCase( Hash( arguments.indexName ) ) );
	}

	public string function getDropIndexSql( required string indexName, required string tableName ) {
		return "getDropIndexSql() not implemented. Must be implemented by extended adapters.";
	}

	public string function getUpdateSql(
		  required string tableName
		, required array  updateColumns
		, required any    filter
		,          string tableAlias = ""
		,          array  joins      = []
	) {
		return "getUpdateSql() not implemented. Must be implemented by extended adapters.";
	}

	public string function getDeleteSql( required string tableName, required any filter, string tableAlias="" ) {
		return "getDeleteSql() not implemented. Must be implemented by extended adapters.";
	}

	public array function getInsertSql( required string tableName, required array insertColumns, numeric noOfRows=1 ) {
		var sql          = "insert into #escapeEntity( arguments.tableName )# (";
		var delim        = " ";
		var rowdelim     = " (";
		var col          = "";
		var i            = "";
		var paramPostFix = "";

		for( col in arguments.insertColumns ){
			sql &= delim & escapeEntity( lcase(col) );
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
		return "getSelectSql() not implemented. Must be implemented by extended adapters.";
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

	public string function getColumnDBType( required string dataType ){
		return arguments.dataType;
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

			case "time":
				return "cf_sql_time";

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

	public string function getToggleForeignKeyChecks(
		  required boolean checksEnabled
		, required string  tableName
	) {
		return "getToggleForeignKeyChecks() not implemented. Must be implemented by extended adapters.";
	}

	public string function getIfNullStatement( required string statement, required string alternativeStatement, required string alias ) {
		return "getIfNullStatement() not implemented. Must be implemented by extended adapters.";
	}

	public boolean function doesColumnTypeRequireLengthSpecification( required string sqlDataType ) {
		switch( arguments.sqlDataType ){
			case "char":
			case "varchar":
				return true;
		}

		return false;
	}

	public string function getLengthFunctionSql( required string expression ) {
		return "Length( #expression# )";
	}

	public string function getNowFunctionSql() {
		return "Now()";
	}

	public string function getConcatenationSql( required string leftExpression, required string rightExpression ) {
		return "getConcatenationSql() not implemented. Must be implemented by extended adapters.";
	}

	public boolean function supportsRenameInAlterColumnStatement() {
		return true;
	}

	public boolean function supportsCascadeUpdateDelete() {
		return true;
	}

	public string function getRenameColumnSql( required string tableName, required string oldColumnName, required string newColumnName ) {
		return "getRenameColumnSql() not implemented. Must be implemented by extended adapters.";
	}
}