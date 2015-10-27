component output=false {

	property name="assetManagerService" inject="assetManagerService";

	public function asset( event, rc, prc ) output=false {
		announceInterception( "preDownloadAsset" );

		_checkDownloadPermissions( argumentCollection=arguments );

		var assetId         = rc.assetId      ?: "";
		var versionId       = rc.versionId    ?: "";
		var derivativeName  = rc.derivativeId ?: "";
		var asset           = "";
		var assetSelectFields = [ "asset.title", ( Len( Trim( versionId ) ) ? "asset_version.asset_type" : "asset.asset_type" ) ];

		if ( Len( Trim( derivativeName ) ) ) {
			try {
				asset = assetManagerService.getAssetDerivative( assetId=assetId, versionId=versionId, derivativeName=derivativeName, selectFields=assetSelectFields );
			} catch ( "AssetManager.assetNotFound" e ) {
				asset = QueryNew('');
			} catch ( "AssetManager.versionNotFound" e ) {
				asset = QueryNew('');
			} catch ( "storageProvider.objectNotFound" e ) {
				asset = QueryNew('');
			}
		} elseif( Len( Trim( versionId ) ) ) {
			asset = assetManagerService.getAssetVersion( assetId=assetId, versionId=versionId, selectFields=assetSelectFields );
		} else {
			asset = assetManagerService.getAsset( id=assetId, selectFields=assetSelectFields );
		}

		if ( asset.recordCount ) {
			var assetBinary = "";
			var type        = assetManagerService.getAssetType( name=asset.asset_type, throwOnMissing=true );
			var etag        = assetManagerService.getAssetEtag( id=assetId, versionId=versionId, derivativeName=derivativeName, throwOnMissing=true );

			_doBrowserEtagLookup( etag );

			if ( Len( Trim( derivativeName ) ) ) {
				assetBinary = assetManagerService.getAssetDerivativeBinary( assetId=assetId, versionId=versionId, derivativeName=derivativeName );
			} else {
				assetBinary = assetManagerService.getAssetBinary( id=assetId, versionId=versionId );
			}

			announceInterception( "onDownloadAsset", {
				  assetId        = assetId
				, derivativeName = derivativeName
				, asset          = asset
			} );

			if(listlast(asset.title,'.') eq type.extension){
				asset.title = ListDeleteAt(asset.title, listlen(asset.title,'.') ,'.');
			}

			if ( type.serveAsAttachment ) {
				header name="Content-Disposition" value="attachment; filename=""#asset.title#.#type.extension#""";
			} else {
				header name="Content-Disposition" value="inline; filename=""#asset.title#.#type.extension#""";
			}

			header name="etag" value=etag;
			header name="cache-control" value="max-age=31536000";
			content
				reset    = true
				variable = assetBinary
				type     = type.mimeType;
			abort;
		}

		event.renderData( data="404 not found", type="text", statusCode=404 );

	}

	public function tempFile( event, rc, prc ) output=false {
		var tmpId           = rc.assetId ?: "";
		var fileDetails     = assetManagerService.getTemporaryFileDetails( tmpId );
		var fileTypeDetails = "";

		if ( StructCount( fileDetails ) ) {
			fileTypeDetails = assetManagerService.getAssetType( filename=filedetails.name );

			if ( ( fileTypeDetails.groupName ?: "" ) eq "image" ) {
				// brutal for now - no thumbnail generation, just spit out the file
				content reset=true variable="#assetManagerService.getTemporaryFileBinary( tmpId )#" type="#fileTypeDetails.mimeType#";abort;
			} else {
				var iconFile = "/preside/system/assets/images/asset-type-icons/48px/#ListLast( fileDetails.name, "." )#.png";
				content reset=true file="#iconFile#" deleteFile=false type="image/png";abort;
			}
		}

		event.renderData( data="404 not found", type="text", statusCode=404 );
	}


// private helpers
	private string function _doBrowserEtagLookup( required string etag ) output=false {
		if ( ( cgi.http_if_none_match ?: "" ) == arguments.etag ) {
			announceInterception( "onReturnAsset304", { etag = arguments.etag } );
			content reset=true;header statuscode=304 statustext="Not Modified";abort;
		}
	}

	private void function _checkDownloadPermissions( event, rc, prc ) output=false {
		var assetId        = rc.assetId      ?: "";
		var derivativeName = rc.derivativeId ?: "";

		if ( Len( Trim( derivativeName ) ) && assetManagerService.isDerivativePubliclyAccessible( derivativeName ) ) {
			return;
		}

		var permissionSettings = assetManagerService.getAssetPermissioningSettings( assetId );

		if ( permissionSettings.restricted ) {
			var hasPerm = event.isAdminUser() && hasCmsPermission(
				  permissionKey = "assetmanager.assets.download"
				, context       = "assetmanagerfolder"
				, contextKeys   = permissionSettings.contextTree
			);
			if ( hasPerm ) { return; }

			if ( !isLoggedIn() || ( permissionSettings.fullLoginRequired && isAutoLoggedIn() ) ) {
				event.accessDenied( reason="LOGIN_REQUIRED" );
			}

			hasPerm = hasWebsitePermission(
				  permissionKey = "assets.access"
				, context       = "asset"
				, contextKeys   = permissionSettings.contextTree
			)
			if ( !hasPerm ) {
				event.accessDenied( reason="INSUFFICIENT_PRIVILEGES" );
			}
		}
	}
}