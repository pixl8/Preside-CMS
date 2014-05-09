component output="false" {

	this.name = "Preside Test Suite " & Hash( ExpandPath( '/' ) );

	this.mappings['/tests']         = ExpandPath( "/" );
	this.mappings['/app']           = ExpandPath( "/resources/testSite" );
	this.mappings['/preside']       = ExpandPath( "/../../" );
	this.mappings['/coldbox']       = ExpandPath( "/../../system/externals/coldbox" );
	this.mappings['/mxunit' ]       = ExpandPath( "/../../system/externals/coldbox/system/testing/compat" );
	this.mappings['/org/cfstatic']  = ExpandPath( "/../../system/externals/cfstatic/org/cfstatic" );

	setting requesttimeout="6000";

	function onApplicationStart() output=false {
		_loadDsn();

		return true;
	}

	function onRequestStart() output=false {
		if ( StructKeyExists( url, 'fwreinit' ) ) {
			_loadDsn();
		}

		return true;
	}

	private void function _loadDsn() output=false {
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
}