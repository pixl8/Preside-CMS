component output=false {
	processingdirective preserveCase=true;

	this.name = "Preside CI Test runner";

	this.mappings['/results']       = ExpandPath( "./results" );
	this.mappings['/mxunit' ]       = ExpandPath( "../../../system/externals/coldbox/system/testing/compat" );
	this.mappings['/tests']         = ExpandPath( "../../tests" );
	this.mappings['/app']           = ExpandPath( "../../tests/resources/testSite" );
	this.mappings['/preside']       = ExpandPath( "../../../" );
	this.mappings['/coldbox']       = ExpandPath( "../../../system/externals/coldbox" );
	this.mappings['/org/cfstatic']  = ExpandPath( "../../../system/externals/cfstatic/org/cfstatic" );

	this.datasources.preside_test_suite = {
		  class            = 'org.gjt.mm.mysql.Driver'
		, connectionString = 'jdbc:mysql://localhost:3306/preside_test?characterEncoding=UTF-8&useUnicode=true'
		, username         = 'root'
		, password         = ''
	};


	function onApplicationStart() output=false {
		application.dsn = "preside_test_suite";

		return true;
	}

	setting requesttimeout="600";
}