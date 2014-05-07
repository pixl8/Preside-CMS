<cfscript>
	testResults = new mxunit.runner.DirectoryTestSuite().run(
		  directory     = ExpandPath( "/integration" )
		, componentPath = "integration"
	);

	WriteOutput( testResults.getResultsOutput() );
</cfscript>