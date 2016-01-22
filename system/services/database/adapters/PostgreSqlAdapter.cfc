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
		var escaped = '"#arguments.entityName#"';
		return (listlen(escaped,'.') gt 1) ? Replace( escaped, Chr(34), " ", "all" ) : escaped;
	}

	public boolean function requiresManualCommitForTransactions(){
		return true;
	}

	public array function getInsertSql( required string tableName, required array insertColumns, numeric noOfRows=1 ) {
		var sql = super.getInsertSql( argumentCollection=arguments );
		sql[1] &= " RETURNING id"
		return sql;
	}

	public string function getInsertReturnType(){
		return 'recordset';
	}

	public string function getGeneratedKey(required any result){
		return arguments.result.id;
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
           }else{
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


       if ( arguments.dbType eq "varchar" and not arguments.maxLength ) {
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
			var qAlter = "alter table #escapeEntity( arguments.tableName )# alter column #columnDef.columnType#";
		}
		if(len(columnDef.columnSet)){
			qAlter &= ", alter column #columnDef.columnSet#";
		}
		return qAlter;
	}

	public string function getTableDefinitionSql( required string tableName, required string columnSql ) {
		return "create table #escapeEntity( arguments.tableName )# ( #arguments.columnSql# )";
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) {
		return "alter table #escapeEntity( arguments.tableName )# drop constraint #escapeEntity( arguments.foreignKeyName )#";
	}

	public string function getDropIndexSql( required string indexName, required string tableName ) {
		return "drop index #escapeEntity( arguments.indexName )#";
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
			entity = hasAlias and ListLen( col, '.' ) eq 1 ? "#col#" : col;
			sql &= delim & " " & escapeEntity( entity ) & " = :set__" & col;
			delim = ",";
		}

		sql &= getClauseSql(
			  tableAlias = arguments.tableAlias
			, filter     = arguments.filter
		);

		return sql;
	}

	public string function getDeleteSql( required string tableName, required any filter, string tableAlias="" ) {
		var sql = "delete from "

		if(Len( Trim( arguments.tableAlias ) ) ) {
			sql &= "#arguments.tableName# as #arguments.tableAlias#";
		} else {
			sql &= "#arguments.tableName#";
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

	) {
		var sql         = "select";
		var delim       = " ";
		var col         = "";

		for( col in arguments.selectColumns ){
			sql &= delim & col;
			delim = ", ";
		}

		sql &= " from " & arguments.tableName ;
		if ( Len( arguments.tableAlias ) ) {
			sql &= " " & arguments.tableAlias ;
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
			if ( ArrayLen( arguments.joins ) ) {
				for( aliasCol in arguments.joins) {
					sql &= ", #aliasCol.tableAlias#.#aliasCol.tableColumn#"
				}
			}
		}

		if ( Len( Trim ( arguments.orderBy ) ) ) {
			sql &= " order by " & arguments.orderBy;
		}

		if ( arguments.maxRows ) {
			sql &= " limit #arguments.maxRows# offset #arguments.startRow-1#";
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
		return "alter table "& "#escapeEntity(arguments.tableName)#" &" "&( arguments.checksEnabled ? 'ENABLE' : 'DISABLE' ) & " TRIGGER ALL";
	}

	public string function getConcatenationSql( required string leftExpression, required string rightExpression ) {
		return "#leftExpression# || #rightExpression#";
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
                   columnType &= " serial";
                   arguments.maxLength = 0;
           }else{

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
                   case "text":
                           arguments.maxLength = 0;
                           columnType &= " #arguments.dbType#";
                           break;
                   default:
                           columnType &= " #arguments.dbType#";
                           break;
               }
       }

       if ( arguments.dbType eq "varchar" and not arguments.maxLength ) {
               arguments.maxLength = 200;
       }

       if ( arguments.maxLength ) {
               columnType &= "(#arguments.maxLength#)";
       }

       if ( arguments.primaryKey ) {
               columnType &= " primary key";
       }

       columnAlter['columnSet'] = ( isNullable ? "" : escapeEntity( arguments.columnName ) & " Set not null" );
       columnAlter['columnType'] = columnType;
       return columnAlter;
   }
}