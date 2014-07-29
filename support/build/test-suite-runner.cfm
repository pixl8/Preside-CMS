<cfscript>
	reportPath = ExpandPath( "/results" );

	try {
		testbox = new coldbox.system.testing.TestBox( reporter="text", options={}, directory={
			recurse = true,
			mapping = "tests.integration",
			filter  = function( required path ){ return true; }
		} );

		plainTextResult = testbox.run();
		resultObject    = testbox.getResult();
		errors          = resultObject.getTotalFail() + resultObject.getTotalError();

		plainTextResult = ListToArray( plainTextResult, Chr(10) & Chr(13) );
		for( i=plainTextResult.len(); i >= 1; i-- ){
			if ( !Len( Trim( plainTextResult[i] ) ) ) {
				ArrayDeleteAt( plainTextResult, i );
			}
		}

		plainTextResult = ArrayToList( plainTextResult, Chr(10) );

		FileWrite( reportpath & "/testbox.properties", errors ? "testbox.failed=true" : "testbox.passed=true" );
		FileWrite( reportPath & "/output.txt", plainTextResult );
		content reset=true;Writeoutput( Trim( plainTextResult ) );
	} catch ( any e ) {
		plainTextResult = "An error occurred running the test suite. Message: #e.message#. Detail: #e.detail#. Serialized: #SerializeJson( e )#";

		FileWrite( reportpath & "/testbox.properties", "testbox.failed=true" );
		FileWrite( reportPath & "/output.txt", plainTextResult );
		content reset=true;Writeoutput( Trim( plainTextResult ) );
	}
</cfscript>