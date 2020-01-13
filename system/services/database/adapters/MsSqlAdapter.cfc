/**
 * @singleton
 *
 */
component extends="BaseAdapter" {

// CONSTRUCTOR
	public any function init( required boolean useVarcharMaxForText ) {
	
		_setUseVarcharMaxForText( arguments.useVarcharMaxForText );
		
		return this;
	}

// PUBLIC API METHODS
	public string function escapeEntity( required string entityName ) {
		var escaped = "[#arguments.entityName#]";

		return Replace( escaped, ".", "].[", "all" );
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

		switch( arguments.dbType ) {
			case "boolean":
				columnDef &= "bit";
				break;
			case "timestamp":
				columnDef &= "datetime";
				break;
			case "longtext":
			case "text":
				arguments.maxLength = 0;
				columnDef &= _getUseVarcharMaxForText() ? "varchar(max)" : "text";
				break;
			case "bigint":
			case "int":
			case "float":
			case "double":
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
				sql &= " on delete cascade";
				break;
			case 'cascade-if-no-cycle-check':
			case 'set-null-if-no-cycle-check':
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
				sql &= " on update cascade";
				break;
			case 'cascade-if-no-cycle-check':
			case 'no action':
				sql &= " on update no action";
				break;
			default:
				sql &= " on update set null";
		}

		return sql;
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) {
		return "alter table #escapeEntity( arguments.tableName )# drop constraint #escapeEntity( arguments.foreignKeyName )#";
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
		var sql      = "update ";
		var delim    = "";
		var col      = "";
		var hasAlias = Len( Trim( arguments.tableAlias ) );

		if ( hasAlias ) {
			sql &= arguments.tableAlias;
		} else {
			sql &= arguments.tableName;
		}

		sql &= " set";

		for( col in arguments.updateColumns ) {
			if( col != "id" ) {
				sql &= delim & " " & escapeEntity( col ) & " = :set__" & col;
				delim = ",";
			}
		}

		if ( hasAlias ) {
			sql &= " from #escapeEntity( arguments.tableName )# as #escapeEntity( arguments.tableAlias )# ";
		}

		if ( arguments.joins.len() ) {
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, joins      = arguments.joins
			);
		}

		sql &= getClauseSql(
			filter     = arguments.filter,
			tableAlias = ""
		);

		return sql;
	}

	public string function getDeleteSql( 
		  required string tableName
		, required any    filter
		,          string tableAlias = "" 
		,          array  joins      = []
	) {
		var sql = "delete "

		if ( Len( Trim( arguments.tableAlias ) ) ) {
			sql &= "#escapeEntity( arguments.tableAlias )# from #escapeEntity( arguments.tableName )# as #escapeEntity( arguments.tableAlias )#";
		} else {
			sql &= "from #escapeEntity( arguments.tableName )#";
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
		var sql         = arguments.distinct ? "select distinct" : "select";
		var delim       = " ";
		var col         = "";

		for( col in arguments.selectColumns ){
			sql &= delim & col;
			delim = ", ";
		}

		if ( arguments.maxRows ) {
			if ( Len( Trim ( arguments.orderBy ) ) ) {
				sql &= ", row_number() over (order by " & arguments.orderBy & ") as _rownumber ";
			} else {
				sql &= ", row_number() over ( order by (SELECT 1) ) as _rownumber ";
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
			sql &= " group by " & arguments.groupBy;
		}

		if ( Len( Trim ( arguments.having ) ) ) {
			sql &= " having " & arguments.having;
		}

		if ( Len( Trim ( arguments.orderBy ) )  && !arguments.maxRows ) {
			sql &= " order by " & arguments.orderBy;
		}

		if ( arguments.maxRows ) {
			sql = "select * from ( " & sql & " ) as recordset where _rownumber between #( arguments.startRow )# and #( ( arguments.startRow + arguments.maxRows ) - 1 )#";
		}

		return sql;
	}

	public string function sqlDataTypeToCfSqlDatatype( required string sqlDataType ) {
		switch( arguments.sqlDataType ){
			case "text":
			case "mediumtext":
			case "longtext":
				return "cf_sql_longvarchar";

			default:
				return super.sqlDataTypeToCfSqlDatatype( argumentCollection=arguments );
		}
	}

	public string function getIfNullStatement( required string statement, required string alternativeStatement, required string alias ) {
		return "IsNull( #arguments.statement#, #arguments.alternativeStatement# ) as #arguments.alias#";
	}

	public string function getToggleForeignKeyChecks(
		  required boolean checksEnabled
		, required string  tableName
	) {
		return "alter table #escapeEntity( arguments.tableName )# " & ( arguments.checksEnabled ? 'nocheck' : 'with check check' ) & " constraint all";
	}

	private boolean function containsAggregateFunctions( required string sql ) {
		return ReFindNoCase( "\b(SUM|COUNT|AVG|MIN|MAX)\(", arguments.sql );
	}

	public string function getLengthFunctionSql( required string expression ) {
		return "Len( #expression# )";
	}

	public string function getConcatenationSql( required string leftExpression, required string rightExpression ) {
		return "Cast( #leftExpression# as nvarchar( MAX ) ) + Cast( #rightExpression# as nvarchar( MAX ) )";
	}


	public boolean function supportsCascadeUpdateDelete() {
		return false;
	}

	public boolean function supportsRenameInAlterColumnStatement() {
		return false;
	}

	public string function getRenameColumnSql( required string tableName, required string oldColumnName, required string newColumnName ) {
		return "EXEC sp_rename "
		     & "@objname = '#arguments.tableName#.#arguments.oldColumnName#', "
			 & "@newname = '#arguments.newColumnName#', "
			 & "@objtype = 'COLUMN' ";
	}

	public string function getNowFunctionSql() {
		return "GetDate()";
	}

	public string function getIndexSql(
		  required string  indexName
		, required string  tableName
		, required string  fieldList
		,          boolean unique=false

	) {
		var ix = super.getIndexSql( argumentCollection=arguments );

		if ( arguments.unique ) {
			var delim = " where ";
			for( var field in ListToArray( arguments.fieldList ) ) {
				ix &= delim & escapeEntity( field ) & " is not null";
				delim = " and ";
			}
		}

		return ix;
	}

	public string function getDatabaseNameSql() {
		return "select db_name() as db";
	}

	public string function getAllForeignKeysSql() {
		return "select     object_name( f.parent_object_id )                            as table_name
	                     , col_name( fc.parent_object_id, fc.parent_column_id )         as column_name
	                     , object_name ( f.referenced_object_id )                       as referenced_table_name
	                     , col_name( fc.referenced_object_id, fc.referenced_column_id ) as referenced_column_name
	                     , f.name as constraint_name
	            from       sys.foreign_keys        as f
	            inner join sys.foreign_key_columns as fc on f.object_id = fc.constraint_object_id
	            inner join sys.objects             as o  on o.object_id = fc.referenced_object_id";
	}
	
// GETTERS AND SETTERS	
	private boolean function _getUseVarcharMaxForText() {
		return _useVarcharMaxForText;
	}
	private void function _setUseVarcharMaxForText( required boolean useVarcharMaxForText ) {
		_useVarcharMaxForText = arguments.useVarcharMaxForText;
	}
}
