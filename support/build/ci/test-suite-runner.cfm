<cfsetting showDebugOutput="false">
<cfparam name="url.reportpath" default="#expandPath( "/test/results" )#">

<cfscript>
	try {

		testbox = new coldbox.system.testing.TestBox( reporter="text", options={}, directory={
			recurse = true,
			mapping = "integration",
			filter  = function( required path ){ return true; }
		} );

		plainTextResult = testbox.run();
		resultObject    = testbox.getResult();
		errors          = resultObject.getTotalFail() + resultObject.getTotalError();

		FileWrite( url.reportpath & "/testbox.properties", errors ? "testbox.failed=true" : "testbox.passed=true" );
		FileWrite( url.reportPath & "/output.txt", plainTextResult );
		content reset=true;Writeoutput( Trim( plainTextResult ) );
	} catch ( any e ) {
		plainTextResult = "An error occurred running the test suite. Message: #e.message#. Detail: #e.detail#. Serialized: #SerializeJson( e )#";

		FileWrite( url.reportpath & "/testbox.properties", "testbox.failed=true" );
		FileWrite( url.reportPath & "/output.txt", plainTextResult );
		content reset=true;Writeoutput( Trim( plainTextResult ) );
	}
</cfscript>