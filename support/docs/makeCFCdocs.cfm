<!---
	This h4ckt4st!c file builds the API reference documenation from the PresideCMS system services directory.
	It must be run with CommandBox from the command line (the easiest way to do this is using the build.sh file
	that also runs the sphinx build)
--->

<cfsetting enablecfoutputonly="true" />
<cfscript>
	cfcFiles        = DirectoryList( "/preside/system/services", true, "path", "*.cfc" );
	fullPresidePath = ExpandPath( "/preside" );
	apiDocsPath     = "/preside/support/docs/source/reference/api";
	indexDocPath    = apiDocsPath & "/index.rst";
	cfcToRst        = new CFCToRst();

	DirectoryDelete( apiDocsPath, true );
	DirectoryCreate( apiDocsPath );

	indexDoc = CreateObject( "java", "java.lang.StringBuffer" );
	indexDoc.append( "System Service API" & Chr(10) & "==================" & Chr(10) & Chr(10) );
	indexDoc.append( ".. toctree::" & Chr(10) );
	indexDoc.append( "    " & ":maxdepth: 1" & Chr(10) & Chr(10) );

	for( file in cfcFiles ) {
		componentPath = Replace( file, fullPresidePath, "preside" );
		componentPath = ReReplace( componentPath, "\.cfc$", "" );
		componentPath = ListChangeDelims( componentPath, ".", "\/" );

		meta = GetComponentMetaData( componentPath );
		if ( IsBoolean( meta.autodoc ?: "" ) && meta.autodoc ) {
			FileWrite( "#apiDocsPath#/#ListLast( componentPath, '.' )#.rst", cfcToRst.createDocumentation( componentPath ) );
			indexDoc.append( "    " & ListLast( componentPath, "." ) & Chr(10) );
		}
	}

	FileWrite( indexDocPath, indexDoc.toString() )
</cfscript>
