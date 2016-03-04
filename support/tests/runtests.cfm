<cfscript>
	processingdirective suppressWhiteSpace=true {
		isCommandLineExecuted = cgi.server_protocol == "CLI/1.0";

		function exitCode( required numeric code ) {
			var exitcodeFile = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/.exitcode";
			FileWrite( exitcodeFile, code );
		}

		try {
			testbox  = new testbox.system.TestBox( options={}, reporter="simple", directory={
				  recurse  = true
				, mapping  = "integration"
				, filter   = function( required path ){ return true; }

			} );

			results = Trim( testbox.run() );
			if ( isCommandLineExecuted ) {
				resultsDir       = "/preside/support/build/artifacts/testresults/";
				testsResultsFile = "testresults_#DateTimeFormat( Now(), 'yyyy-mm-dd_HHNN' )#.html"

				if ( !DirectoryExists( resultsDir ) ) {
					DirectoryCreate( resultsDir )
				}
				FileWrite( resultsDir & testsResultsFile, results );

				resultObject = testbox.getResult();
				errors       = resultObject.getTotalFail() + resultObject.getTotalError();

				totalDuration = resultObject.getTotalDuration();
				totalSpecs    = resultObject.getTotalSpecs();
				totalPass     = resultObject.getTotalPass();
				totalFail     = resultObject.getTotalFail();
				totalError    = resultObject.getTotalError();
				totalSkipped  = resultObject.getTotalSkipped();

				echo( "Tests complete in #NumberFormat( totalDuration )#ms. " );
				if ( errors ) {
					echo( "One or more tests failed or created an error. Please see #resultsDir##testsResultsFile# for further details." );
				} else {
					echo( "All tests passed!" );
				}

				echo( Chr( 13 ) & Chr( 10 ) );

				echo( 'Total: #NumberFormat( totalSpecs )#. Pass: #NumberFormat( totalPass )#. Fail: #NumberFormat( totalFail )#. Error: #NumberFormat( totalError )#. Skipped: #NumberFormat( totalSkipped )#' );
				echo( Chr( 13 ) & Chr( 10 ) );
				echo( Chr( 13 ) & Chr( 10 ) );
				echo( 'Full results have been written to #resultsDir#' & testsResultsFile );

				exitCode( errors ? 1 : 0 );
			} else {
				echo( results );
			}

		} catch ( any e ) {
			if ( isCommandLineExecuted ) {
				echo( "An error occurred running the tests. Message: [#e.message#], Detail: [#e.detail#]" );
				exitCode( 1 );
			} else {
				rethrow;
			}
		}
	}
</cfscript>