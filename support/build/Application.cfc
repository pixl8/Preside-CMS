component output=false {
	this.name = "Preside CI Test runner";

	this.mappings['/results']       = ExpandPath( "./results" );
	this.mappings['/mxunit' ]       = ExpandPath( "../../system/externals/coldbox/system/testing/compat" );
	this.mappings['/tests']         = ExpandPath( "../tests" );
	this.mappings['/app']           = ExpandPath( "../tests/resources/testSite" );
	this.mappings['/preside']       = ExpandPath( "../../" );
	this.mappings['/coldbox']       = ExpandPath( "../../system/externals/coldbox" );
	this.mappings['/org/cfstatic']  = ExpandPath( "../../system/externals/cfstatic/org/cfstatic" );

	function onApplicationStart() output=false {
		application.dsn = "preside_test_suite";

		return true;
	}

	setting requesttimeout="600";
}