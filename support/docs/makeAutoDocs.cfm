<!---
	This h4ckt4st!c file builds the API reference documenation from the PresideCMS system services directory.
	It must be run with CommandBox from the command line (the easiest way to do this is using the build.sh file
	that also runs the sphinx build)
--->

<cfsetting enablecfoutputonly="true" />
<cfscript>

	// SERVICE LAYER CFCs
	cfcFiles        = DirectoryList( "/preside/system/services", true, "path", "*.cfc" );
	fullPresidePath = ExpandPath( "/preside" );
	apiDocsPath     = "/preside/support/docs/source/reference/api";
	indexDocPath    = apiDocsPath & "/index.rst";
	srcToRst        = new SourceCodeToRst();

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
			filename = LCase( ListLast( componentPath, '.' ) );
			FileWrite( "#apiDocsPath#/#filename#.rst", srcToRst.createCFCDocumentation( componentPath ) );
			indexDoc.append( "    " & filename & Chr(10) );
		}
	}

	FileWrite( indexDocPath, indexDoc.toString() );

	// PRESIDE OBJECTS
	cfcFiles        = DirectoryList( "/preside/system/preside-objects", true, "path", "*.cfc" );
	fullPresidePath = ExpandPath( "/preside" );
	apiDocsPath     = "/preside/support/docs/source/reference/presideobjects";
	indexDocPath    = apiDocsPath & "/index.rst";
	srcToRst        = new SourceCodeToRst();

	DirectoryDelete( apiDocsPath, true );
	DirectoryCreate( apiDocsPath );

	indexDoc = CreateObject( "java", "java.lang.StringBuffer" );
	indexDoc.append( "System Preside Objects" & Chr(10) & "======================" & Chr(10) & Chr(10) );
	indexDoc.append( ".. toctree::" & Chr(10) );
	indexDoc.append( "    " & ":maxdepth: 1" & Chr(10) & Chr(10) );

	for( file in cfcFiles ) {
		componentPath = Replace( file, fullPresidePath, "preside" );
		componentPath = ReReplace( componentPath, "\.cfc$", "" );
		componentPath = ListChangeDelims( componentPath, ".", "\/" );

		filename = LCase( ListLast( componentPath, '.' ) );
		FileWrite( "#apiDocsPath#/#filename#.rst", srcToRst.createPresideObjectDocumentation( componentPath ) );
		indexDoc.append( "    " & filename & Chr(10) );
	}

	FileWrite( indexDocPath, indexDoc.toString() );

	// FORMS
	xmlFiles        = DirectoryList( "/preside/system/forms", true, "path", "*.xml" );
	formsDocsPath   = "/preside/support/docs/source/reference/systemforms";
	indexDocPath    = formsDocsPath & "/index.rst";
	createdDocs     = [];

	DirectoryDelete( formsDocsPath, true );
	DirectoryCreate( formsDocsPath );

	indexDoc = CreateObject( "java", "java.lang.StringBuffer" );
	indexDoc.append( "System form layouts" & Chr(10) & "===================" & Chr(10) & Chr(10) );
	indexDoc.append( ".. toctree::" & Chr(10) );
	indexDoc.append( "    " & ":maxdepth: 1" & Chr(10) & Chr(10) );

	for( file in xmlFiles ) {
		result = srcToRst.writeXmlFormDocumentation( file, formsDocsPath );
		if ( result.success ) {
			createdDocs.append( result.filename );
		}
	}
	createdDocs.sort( "textnocase" );
	for( doc in createdDocs ){
		indexDoc.append( "    " & doc & Chr(10) );
	}

	FileWrite( indexDocPath, indexDoc.toString() )
</cfscript>
