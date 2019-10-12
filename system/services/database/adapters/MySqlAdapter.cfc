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
		var escaped = "`#arguments.entityName#`";

		return Replace( escaped, ".", "`.`", "all" );
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

		columnDef &= " #arguments.dbType#";


		if ( arguments.dbType eq "varchar" and not arguments.maxLength ) {
			arguments.maxLength = 200;
		}

		if ( arguments.maxLength ) {
			columnDef &= "(#arguments.maxLength#)";
		}

		columnDef &= ( isNullable ? " null" : " not null" );

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


	) {
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

	public string function getTableDefinitionSql( required string tableName, required string columnSql ) {
		return "create table #escapeEntity( arguments.tableName )# ( #arguments.columnSql# ) ENGINE=InnoDB";
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) {
		return "alter table #escapeEntity( arguments.tableName )# drop foreign key #escapeEntity( arguments.foreignKeyName )#";
	}

	public string function getDropIndexSql( required string indexName, required string tableName ) {
		return "alter table #escapeEntity( arguments.tableName )# drop index #escapeEntity( arguments.indexName )#";
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

	public string function getDeleteSql( 
		  required string tableName
		, required any    filter
		,          string tableAlias = ""
		,          array  joins      = []
	) {
		var sql = "delete from "

		if ( Len( Trim( arguments.tableAlias ) ) ) {
			sql &= "#escapeEntity( arguments.tableAlias )# using #escapeEntity( arguments.tableName )# as #escapeEntity( arguments.tableAlias )#";
		} else {
			sql &= "#escapeEntity( arguments.tableName )#";
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
		,          string  having        = ""
		,          string  groupBy       = ""
		,          string  tableAlias    = ""
		,          array   joins         = []
		,          numeric maxRows       = 0
		,          numeric startRow      = 1
		,          boolean distinct      = false

	) {
		var sql         = arguments.distinct ? "select distinct" : "select";
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

		if ( Len( Trim ( arguments.having ) ) ) {
			sql &= " having " & arguments.having;
		}

		if ( Len( Trim ( arguments.orderBy ) ) ) {
			sql &= " order by " & arguments.orderBy;
		}

		if ( arguments.maxRows ) {
			sql &= " limit #arguments.startRow-1#, #arguments.maxRows#";
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
		return "set foreign_key_checks=" & ( arguments.checksEnabled ? '1' : '0' );
	}

	public string function getConcatenationSql( required string leftExpression, required string rightExpression ) {
		return "Concat( #leftExpression#, #rightExpression# )";
	}

	public boolean function autoCreatesFkIndexes(){
		return true;
	}

	public string function getDatabaseNameSql() {
		return "select database() as db";
	}

	public string function getAllForeignKeysSql() {
		return "select distinct u.table_name
		                      , u.column_name
		                      , u.constraint_name
		                      , u.referenced_table_name
		                      , u.referenced_column_name
		        from            information_schema.key_column_usage u
		        where           u.table_schema = :databasename
		        and             u.referenced_column_name is not null";
	}
}