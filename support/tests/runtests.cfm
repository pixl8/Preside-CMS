<cfscript>
	reporter = url.reporter ?: "simple";
	testbox = new testbox.system.TestBox( options={}, reporter=reporter, directory={
		  recurse  = true
		, mapping  = "integration"
		, filter   = function( required path ){ return true; }
	} );

	results = Trim( testbox.run() );

	content reset=true; echo( results ); abort;
</cfscript>