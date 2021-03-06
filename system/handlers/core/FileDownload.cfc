component {

	property name="assetManagerService"    inject="assetManagerService";
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

		var type = assetManagerService.getAssetType( name=ListLast( filename, "." ) );
		if( structIsEmpty( type ) ){
			type = {
				  serveAsAttachment = true
				, mimeType          = "application/octet-stream"
			}
		}
		var etag = LCase( Hash( SerializeJson( storageProvider.getObjectInfo( path=storagePath, private=storagePrivate ) ) ) );

		_doBrowserEtagLookup( etag );


		if ( type.serveAsAttachment ) {
			header name="Content-Disposition" value="attachment; filename=""#filename#""";
		} else {
			header name="Content-Disposition" value="inline; filename=""#filename#""";
		}

		announceInterception( "onDownloadFile", {
			  storageProvider = storageProvider
			, storagePath     = storagePath
			, storagePrivate  = storagePrivate
			, filename        = filename
			, type            = type
			, allowAccess     = allowAccess
		} );

		if ( isFalse( allowAccess ) ) {
			event.accessDenied( reason="The asset is restricted." );
		}

		header name="etag" value=etag;
		header name="cache-control" value="max-age=31536000";

		if ( storageProviderService.providerSupportsFileSystem( storageProvider ) ) {
			content
				reset = true
				file  = storageProvider.getObjectLocalPath( path=storagePath, private=storagePrivate )
				type  = type.mimeType;
		} else {
			content
				reset    = true
				variable = storageProvider.getObject( path=storagePath, private=storagePrivate )
				type     = type.mimeType;
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