<!---
	This h4ckt4st!c file builds the API reference documenation from the PresideCMS system services directory.
	It must be run with CommandBox from the command line (the easiest way to do this is using the build.sh file
	that also runs the sphinx build)
--->

<cfsetting enablecfoutputonly="true" />
<cfscript>

	// SERVICE LAYER CFCs
	cfcFiles         = DirectoryList( "/preside/system/services", true, "path", "*.cfc" );
	fullPresidePath  = ExpandPath( "/preside" );
	apiDocsPath      = "/preside/support/docs/docs/05.reference/01.api";
	indexDocPath     = apiDocsPath & "/chapter.md";
	srcToPresideDocs = new SourceToPresideDocs();
	createdDocs      = {};

	if ( DirectoryExists( apiDocsPath ) ) {
		DirectoryDelete( apiDocsPath, true );
	}
	DirectoryCreate( apiDocsPath );

	indexDoc = CreateObject( "java", "java.lang.StringBuffer" );

	indexDoc.append( "---" & Chr(10) );
	indexDoc.append( "id: systemservices" & Chr(10) );
	indexDoc.append( "title: System service APIs" & Chr(10) );
	indexDoc.append( "---" & Chr(10) & Chr(10) );


	for( file in cfcFiles ) {
		componentPath = Replace( file, fullPresidePath, "preside" );
		componentPath = ReReplace( componentPath, "\.cfc$", "" );
		componentPath = ListChangeDelims( componentPath, ".", "\/" );

		meta = GetComponentMetaData( componentPath );
		if ( IsBoolean( meta.autodoc ?: "" ) && meta.autodoc ) {
			result = srcToPresideDocs.createCFCDocumentation( componentPath, apiDocsPath );
			if ( result.success ) {
				createdDocs[ result.filename ] = { title = result.title };
			}
		}
	}

	sortedDocs = createdDocs.sort( "textnocase", "asc", "title" );
	for( doc in sortedDocs ){
		indexDoc.append( "* [[" & doc & "]]" & Chr(10) );
	}

	FileWrite( indexDocPath, indexDoc.toString() );

	// PRESIDE OBJECTS
	cfcFiles        = DirectoryList( "/preside/system/preside-objects", true, "path", "*.cfc" );
	fullPresidePath = ExpandPath( "/preside" );
	apiDocsPath     = "/preside/support/docs/docs/05.reference/02.presideobjects";
	indexDocPath    = apiDocsPath & "/chapter.md";
	createdDocs     = {};

	if ( DirectoryExists( apiDocsPath ) ) {
		DirectoryDelete( apiDocsPath, true );
	}
	DirectoryCreate( apiDocsPath );

	indexDoc = CreateObject( "java", "java.lang.StringBuffer" );
	indexDoc.append( "---" & Chr(10) );
	indexDoc.append( "id: systempresideobjects" & Chr(10) );
	indexDoc.append( "title: System Preside Objects" & Chr(10) );
	indexDoc.append( "---" & Chr(10) & Chr(10) );

	for( file in cfcFiles ) {
		componentPath = Replace( file, fullPresidePath, "preside" );
		componentPath = ReReplace( componentPath, "\.cfc$", "" );
		componentPath = ListChangeDelims( componentPath, ".", "\/" );

		result = srcToPresideDocs.createPresideObjectDocumentation( componentPath, apiDocsPath );
		if ( result.success ) {
			createdDocs[ result.filename ] = { title = result.title };
		}
	}

	sortedDocs = createdDocs.sort( "textnocase", "asc", "title" );
	for( doc in sortedDocs ){
		indexDoc.append( "* [[" & doc & "]]" & Chr(10) );
	}

	FileWrite( indexDocPath, indexDoc.toString() );

	// // FORMS
	xmlFiles        = DirectoryList( "/preside/system/forms", true, "path", "*.xml" );
	formsDocsPath   = "/preside/support/docs/docs/05.reference/03.systemforms";
	indexDocPath    = formsDocsPath & "/chapter.md";
	createdDocs     = {};

	if ( DirectoryExists( formsDocsPath ) ) {
		DirectoryDelete( formsDocsPath, true );
	}
	DirectoryCreate( formsDocsPath );

	indexDoc = CreateObject( "java", "java.lang.StringBuffer" );
	indexDoc.append( "---" & Chr(10) );
	indexDoc.append( "id: systemforms" & Chr(10) );
	indexDoc.append( "title: System form layouts" & Chr(10) );
	indexDoc.append( "---" & Chr(10) & Chr(10) );

	for( file in xmlFiles ) {
		result = srcToPresideDocs.writeXmlFormDocumentation( file, formsDocsPath );
		if ( result.success ) {
			createdDocs[ result.filename ] = { title = result.title }; 
		}
	}

	sortedDocs = createdDocs.sort( "textnocase", "asc", "title" );
	for( doc in sortedDocs ){
		indexDoc.append( "* [[form-" & doc & "]]" & Chr(10) );
	}

	FileWrite( indexDocPath, indexDoc.toString() );
</cfscript>
