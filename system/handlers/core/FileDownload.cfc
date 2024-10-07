component {

	property name="fileTypesService"       inject="fileTypesService";
	property name="storageProviderService" inject="storageProviderService";

	public function index( event, rc, prc ) output=false {
		announceInterception( "preDownloadFile" );

		var storageProvider = rc.storageProvider ?: "";
		var storagePath     = rc.storagePath     ?: "";
		var filename        = rc.filename        ?: ListLast( storagePath, "/" );
		var storagePrivate  = booleanFormat( rc.fileIsPrivate ?: false );
		var allowAccess     = !( storagePrivate ?: false ) || event.isAdminUser();

		if ( !Len( Trim( storageProvider ) ) || !Len( Trim( storagePath ) ) ) {
			event.notFound();
		}

		try {
			storageProvider = getModel( storageProvider );
		} catch( any e ) {
			event.notFound();
		}

		if ( !storageProvider.objectExists( path=storagePath, private=storagePrivate ) ) {
			event.notFound();
		}

		var type = fileTypesService.getAssetType( name=ListLast( filename, "." ) );
		if( StructIsEmpty( type ) ){
			type = {
				  serveAsAttachment = true
				, mimeType          = "application/octet-stream"
			}
		}

		var etag = LCase( Hash( SerializeJson( storageProvider.getObjectInfo( path=storagePath, private=storagePrivate ) ) ) );
		var args = {
			  storageProvider = storageProvider
			, storagePath     = storagePath
			, storagePrivate  = storagePrivate
			, filename        = filename
			, type            = type
			, allowAccess     = allowAccess
			, etag            = etag
		};
		announceInterception( "onDownloadFile", args );

		if ( isFalse( args.allowAccess ?: "" ) ) {
			event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
		}

		_doBrowserEtagLookup( args.etag );

		if ( args.type.serveAsAttachment ) {
			header name="Content-Disposition" value="attachment; filename=""#args.filename#""";
		} else {
			header name="Content-Disposition" value="inline; filename=""#args.filename#""";
		}

		header name="etag" value=args.etag;
		header name="cache-control" value="max-age=31536000";

		if ( storageProviderService.providerSupportsFileSystem( args.storageProvider ) ) {
			content
				reset = true
				file  = args.storageProvider.getObjectLocalPath( path=args.storagePath, private=args.storagePrivate )
				type  = args.type.mimeType;
		} else {
			content
				reset    = true
				variable = args.storageProvider.getObject( path=args.storagePath, private=args.storagePrivate )
				type     = args.type.mimeType;
		}

		abort;
	}

// private helpers
	private string function _doBrowserEtagLookup( required string etag ) output=false {
		if ( ( cgi.http_if_none_match ?: "" ) == arguments.etag ) {
			announceInterception( "onReturnFile304", { etag = arguments.etag } );
			content reset=true;header statuscode=304 statustext="Not Modified";abort;
		}
	}
}