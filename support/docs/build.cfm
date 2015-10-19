<cfprocessingdirective suppressWhitespace="true" />
<cfsetting requesttimeout="1200" />
<cfscript>
	newline = Chr( 10 );

	function exitCode( required numeric code ) {
		var exitcodeFile = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/.exitcode";
		FileWrite( exitcodeFile, code );
	}

	try {
		include template="generateDocs.cfm";

		savecontent variable="suppressingwhitespacehere" {
			new api.build.BuildRunner().buildAll();
		}
	} catch ( any e ) {
		exitCode( 1 );

		echo( "" & newline );
		echo( "Documentation build error" & newline );
		echo( "-------------------------" & newline );
		echo( "" & newline );
		echo( "[#e.type#] error occurred while building the docs. Message: [#e.message#]. Detail: [#e.detail#]." & newline );
		if ( ( e.tagContext ?: [] ).len() ) {
			echo( "" & newline );
			echo( "Stacktrace:" & newline );
			for( var tracePoint in e.tagContext ) {
				echo( "    " & tracepoint.template & " (line #tracepoint.line#)" & newline );
			}
		}
	}
</cfscript>
