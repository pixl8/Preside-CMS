component {

	this.name = "Preside Test Suite " & Hash( ExpandPath( '/' ) );

	currentDir = GetDirectoryFromPath( GetCurrentTemplatePath() );

	this.mappings['/tests']       = currentDir;
	this.mappings['/integration'] = currentDir & "integration";
	this.mappings['/resources']   = currentDir & "resources";
	this.mappings['/testbox']     = currentDir & "testbox";
	this.mappings['/mxunit' ]     = currentDir & "testbox/system/compat";
	this.mappings['/app']         = currentDir & "resources/testSite";
	this.mappings['/preside']     = currentDir & "../../";
	this.mappings['/coldbox']     = currentDir & "../../system/externals/coldbox";

	setting requesttimeout="6000";
	_loadDsn();

	function onApplicationStart() {
		_checkDsn();
		return true;
	}

	function onRequestStart() {
		if ( StructKeyExists( url, 'fwreinit' ) ) {
			_loadDsn();
		}

		return true;
	}

	private void function _checkDsn() {
		var info = "";
		var dsn = "preside_test_suite";

		try {
			dbinfo type="version" name="info" datasource="#dsn#";

		} catch ( database e ) {
			if ( cfcatch.message contains "datasource" and cfcatch.message contains "exist" ) {
				throw(
					  type    = "presidetestsuite.nodsn"
					, message = "No datasource has been created for the test suite."
					, detail  = "Please create a MySql (version 5 or higher) datasource named 'preside_test_suite'. Note: USE AN EMPTY DATABASE FOR THIS."
				);
			} else {
				rethrow;
			}
		}

		if ( info.database_productname neq "MySql" or Val( info.database_version ) lt 5 ) {
			throw(
				  type    = "presideTestSuite.invalidDsn"
				, message = "Invalid Datasource. Only MySQL version 5 and above is supported at this time."
				, detail  = "The db product of the datasource is reported as: #info.database_productname# #info.database_version#"
			);
		}

		application.dsn = dsn;
	}

	private void function _loadDsn() {
		var dbConfig = {
			  port     = _getEnvironmentVariable( "PRESIDETEST_DB_PORT"    , "3306" )
			, host     = _getEnvironmentVariable( "PRESIDETEST_DB_HOST"    , "localhost" )
			, database = _getEnvironmentVariable( "PRESIDETEST_DB_NAME"    , "preside_test" )
			, username = _getEnvironmentVariable( "PRESIDETEST_DB_USER"    , "travis" )
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
}