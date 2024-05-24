component extends="preside.system.Bootstrap" {

	super.setupApplication(
		  id                       = "End to End test site"
		, presideSessionManagement = true
	);

	_loadDsn();

	private void function _loadDsn() {
		if ( _dsnExists() ) {
			return;
		}

		var dbConfig = {
			  port     = _getEnvironmentVariable( "PRESIDETEST_DB_PORT"    , "3306" )
			, host     = _getEnvironmentVariable( "PRESIDETEST_DB_HOST"    , "127.0.0.1" )
			, database = _getEnvironmentVariable( "PRESIDETEST_DB_NAME"    , "endtoenddb" )
			, username = _getEnvironmentVariable( "PRESIDETEST_DB_USER"    , "root" )
			, password = _getEnvironmentVariable( "PRESIDETEST_DB_PASSWORD", "root" )
		};

		try {
			this.datasources[ "preside" ] = {
				  type     : 'MySQL'
				, port     : dbConfig.port
				, host     : dbConfig.host
				, database : dbConfig.database
				, username : dbConfig.username
				, password : dbConfig.password
				, custom   : {
					  characterEncoding : "UTF-8"
					, useUnicode        : true
				  }
			};
		} catch( any e ) {}
	}

	private boolean function _dsnExists() {
		try {
			var info = "";

			dbinfo type="version" name="info" datasource="preside";

			return info.recordcount > 0;
		} catch ( database e ) {
			return false;
		}
	}

	private string function _getEnvironmentVariable( required string variableName, string default="" ) {
		var result = CreateObject("java", "java.lang.System").getenv().get( arguments.variableName );

		return IsNull( result ) ? arguments.default : result;
	}

}
