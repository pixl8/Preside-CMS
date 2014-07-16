<!---
	This h4ckt4st!c file builds the API reference documenation from the PresideCMS system services directory.
	It must be run with CommandBox from the command line (the easiest way to do this is using the makeCFCdocs.sh file)
--->

<cfsetting enablecfoutputonly="true" />
<cfscript>
	cfcFiles = DirectoryList( "/preside/system/services", true, "path", "*.cfc" );
	fullPresidePath = ExpandPath( "/preside" );
	apiDocsPath     = "/preside/support/docs/source/reference/api";
	indexDocPath    = apiDocsPath & "/index.rst";
	newline         = Chr( 10 );
	doubleLine      = newline & newline;
	indent          = "    ";

	string function title( required string title, required string lineChar ) output=false {
		return arguments.title & newline & RepeatString( arguments.lineChar, Len( arguments.title ) );
	}

	void function writeDocs( required string componentPath ) {
		var objMeta     = GetComponentMetaData( arguments.componentPath );
		var objName     = ListLast( arguments.componentPath, '.' );
		var docFilePath = "#apiDocsPath#/#objName#.rst";
		var doc         = CreateObject( "java", "java.lang.StringBuffer" );


		doc.append( title( objName, "=" ) );

		doc.append( doubleLine & title( "Overview", "-" ) & doubleLine );
		doc.append( "**Full path:** *#arguments.componentPath#*" );

		if ( Len( Trim( objMeta.hint ?: "" ) ) ) {
			doc.append( doubleLine & Replace( objMeta.hint, newline, doubleLine, "all" ) );
		}

		doc.append( doubleLine & title( "Public API Methods", "-" ) );

		for( var fun in objMeta.functions ){
			if ( ( fun.access ?: "" ) == "public" && fun.name != "init" ) {
				doc.append( doubleLine & title( fun.name, "~" ) );
			}
		}

		FileWrite( docFilePath, doc.toString() );
	}

	indexDoc = CreateObject( "java", "java.lang.StringBuffer" );
	indexDoc.append( title( "System Service API", "=" ) & doubleline );
	indexDoc.append( ".. toctree::" & newline );
	indexDoc.append( indent & ":maxdepth: 1" & doubleline );

	for( file in cfcFiles ) {
		componentPath = Replace( file, fullPresidePath, "preside" );
		componentPath = ReReplace( componentPath, "\.cfc$", "" );
		componentPath = ListChangeDelims( componentPath, ".", "\/" );

		WriteDocs( componentPath );
		indexDoc.append( indent & ListLast( componentPath, "." ) & newline );
	}

	FileWrite( indexDocPath, indexDoc.toString() )
</cfscript>
