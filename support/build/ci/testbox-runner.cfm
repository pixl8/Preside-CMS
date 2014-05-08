<cfsetting showDebugOutput="false">
<cfparam name="url.reporter"       default="simple">
<cfparam name="url.directory"      default="/test/specs">
<cfparam name="url.componentpath"  default="test.specs">
<cfparam name="url.recurse"        default="true" type="boolean">
<cfparam name="url.bundles"        default="">
<cfparam name="url.labels"         default="">
<cfparam name="url.reportpath"     default="#expandPath( "/test/results" )#">
<cfscript>

// Run Tests using correct reporter
results = new mxunit.runner.DirectoryTestSuite().run(
	  directory     = ExpandPath( url.directory )
	, componentPath = url.componentpath
);

// do stupid JUnitReport task processing, if the report is ANTJunit
if( url.reporter eq "ANTJunit" ){
     xmlReport = xmlParse( results );
     for( thisSuite in xmlReport.testsuites.XMLChildren ){
          fileWrite( url.reportpath & "/TEST-" & thisSuite.XMLAttributes.name & ".xml", toString( thisSuite ) );
     }
}

testResult = testbox.getResult();
errors = testResult.getTotalFail() + testResult.getTotalError();
fileWrite( url.reportpath & "/testbox.properties", errors ? "testbox.failed=true" : "testbox.passed=true" );
// Writeout Results
fileWrite(url.reportPath & "/output.txt", results);
writeoutput( results );
</cfscript>