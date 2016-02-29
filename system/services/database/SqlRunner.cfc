component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @logger.inject defaultLogger
	 */
	public any function init( required any logger ) output=false {
		_setLogger( arguments.logger );

		return this;
	}

// PUBLIC API METHODS
	public any function runSql(
		  required string sql
		, required string dsn
		,          array  params
		,          string returntype="recordset"
	) output=false {
		var q      = new query();
		var result = "";
		var param  = "";

		_getLogger().debug( arguments.sql );

		q.setDatasource( arguments.dsn );
		q.setSQL( arguments.sql );

		if ( StructKeyExists( arguments, "params" ) ) {
			for( param in arguments.params ){
				param.value = param.value ?: "";

				if ( not IsSimpleValue( param.value ) ) {
					throw(
						  type = "SqlRunner.BadParam"
						, message = "SQL Param values must be simple values"
						, detail = "The value of the param, [#param.name#], was not of a simple type"
					);
				}

				if ( param.type eq 'cf_sql_bit' and not IsNumeric( param.value ) ) {
					param.value = IsBoolean( param.value ) and param.value ? 'true' : 'false';
				}

				if ( not Len( Trim( param.value ) ) ) {
					param.null = true;
				}

				param.cfsqltype = param.type; // mistakenly had thought we could do param.type - alas no, so need to fix it to the correct argument name here

				q.addParam( argumentCollection = param );
			}
		}
		result = q.execute();

		if ( arguments.returntype eq "info" ) {
			return result.getPrefix();
		} else {
			return result.getResult();
		}
	}

// GETTERS AND SETTERS
	private any function _getLogger() output=false {
		return _logger;
	}
	private void function _setLogger( required any logger ) output=false {
		_logger = arguments.logger;
	}
}