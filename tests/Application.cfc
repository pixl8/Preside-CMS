component {

	this.name = "Preside Test Suite " & Hash( ExpandPath( '/' ) );

	currentDir = GetDirectoryFromPath( GetCurrentTemplatePath() );

	this.mappings['/tests']       = currentDir;
	this.mappings['/integration'] = currentDir & "integration";
	this.mappings['/resources']   = currentDir & "resources";
	this.mappings['/testbox']     = currentDir & "testbox";
	this.mappings['/mxunit' ]     = currentDir & "testbox/system/compat";
	this.mappings['/app']         = currentDir & "resources/testSite";
	this.mappings['/preside']     = currentDir & "../";
	this.mappings['/coldbox']     = currentDir & "../system/externals/coldbox";

	setting requesttimeout="6000";
	_loadDsn();

	function onApplicationStart() {
		if ( !_checkDsn() ) {
			return false;
		}
		return true;
	}

	function onRequestStart() {
		if ( StructKeyExists( url, 'fwreinit' ) ) {
			_loadDsn();
		}

		return true;
	}

	private boolean function _checkDsn() {
		var info = "";
		var dsn = "preside_test_suite";

		try {
			dbinfo type="version" name="info" datasource="#dsn#";

		} catch ( database e ) {
			var isCommandLineExecuted = cgi.server_protocol == "CLI/1.0";
			var nl          = isCommandLineExecuted ? Chr( 13 ) & Chr( 10 ) : "<br>";
			var errorDetail =  "Test datasource not setup. Datasource checked using the following details (either defaults or env vars): " & nl & nl;
			    errorDetail &= "Host     : #_getEnvironmentVariable( "PRESIDETEST_DB_HOST"    , "localhost"    )#" & nl & nl;
			    errorDetail &= "Port     : #_getEnvironmentVariable( "PRESIDETEST_DB_PORT"    , "3306"         )#" & nl & nl;
			    errorDetail &= "DB Name  : #_getEnvironmentVariable( "PRESIDETEST_DB_NAME"    , "preside_test" )#" & nl & nl;
			    errorDetail &= "User     : #_getEnvironmentVariable( "PRESIDETEST_DB_USER"    , "root"         )#" & nl & nl;
			    errorDetail &= "Password : #_getEnvironmentVariable( "PRESIDETEST_DB_PASSWORD", "(empty)"      )#" & nl & nl;

			    errorDetail &= nl & "These defaults can be overwritten by setting the following environment variables: " & nl & nl;
			    errorDetail &= "PRESIDETEST_DB_HOST"     & nl;
			    errorDetail &= "PRESIDETEST_DB_PORT"     & nl;
			    errorDetail &= "PRESIDETEST_DB_NAME"     & nl;
			    errorDetail &= "PRESIDETEST_DB_USER"     & nl;
			    errorDetail &= "PRESIDETEST_DB_PASSWORD" & nl;

			if ( isCommandLineExecuted ) {
				writeOutput( errorDetail );
				return false;
			} else {
				throw(
					  type    = "presidetestsuite.nodsn"
					, message = "No datasource has been created for the test suite."
					, detail  = errorDetail
				);
			}
		}

		switch( info.database_productname ) {
			case "MySQL":
				if ( Val( info.database_version ) lt 5 ) {
					throw(
						  type    = "presideTestSuite.invalidDsn"
						, message = "Invalid Datasource. Only MySQL version 5 and above is supported at this time."
						, detail  = "The db product of the datasource is reported as: #info.database_productname# #info.database_version#"
					);
				}
				break;
			case "Microsoft SQL Server":
				break;
			case "PostgreSQL":
				break;
			default:
				throw(
					  type    = "presideTestSuite.invalidDsn"
					, message = "Invalid Datasource. Only MySQL (version 5 and above) and Microsoft SQL Server are supported at this time."
					, detail  = "The db product of the datasource is reported as: #info.database_productname# #info.database_version#"
				);
		}

		application.dsn = dsn;

		return true;
	}

	private void function _loadDsn() {
		if ( _dsnExists() ) {
			return;
		}

		var dbConfig = {
			  port     = _getEnvironmentVariable( "PRESIDETEST_DB_PORT"    , "3306" )
			, host     = _getEnvironmentVariable( "PRESIDETEST_DB_HOST"    , "localhost" )
			, database = _getEnvironmentVariable( "PRESIDETEST_DB_NAME"    , "preside_test" )
			, username = _getEnvironmentVariable( "PRESIDETEST_DB_USER"    , "root" )
			, password = _getEnvironmentVariable( "PRESIDETEST_DB_PASSWORD", "" )
		};

		try {
			this.datasources[ "preside_test_suite" ] = {
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

	private string function _getEnvironmentVariable( required string variableName, string default="" ) {
		var result = CreateObject("java", "java.lang.System").getenv().get( arguments.variableName );

		return IsNull( result ) ? arguments.default : result;
	}

	private boolean function _dsnExists() {
		try {
			var info = "";

			dbinfo type="version" name="info" datasource="preside_test_suite";

			return info.recordcount > 0;
		} catch ( database e ) {
			return false;
		}
	}
}