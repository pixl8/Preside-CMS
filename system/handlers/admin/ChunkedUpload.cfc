/**
 * Handler for chunked file uploads
 *
 * @feature admin and assetManager
 */
component extends="preside.system.base.AdminHandler" {

	property name="chunkedUploadService" inject="chunkedUploadService";
	property name="assetManagerService"  inject="assetManagerService";

	function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "assetManager" ) ) {
			event.notFound();
		}

		_checkPermissions( argumentCollection=arguments, key="assets.upload" );
	}

	/**
	 * Receive a single chunk and write it to temp storage.
	 * The UUID is generated client-side and passed with every chunk.
	 */
	function uploadChunk( event, rc, prc ) {
		var uuid        = rc.uuid        ?: "";
		var chunkNumber = Val( rc.chunkNumber ?: 0 );

		if ( !Len( Trim( uuid ) ) || chunkNumber <= 0 ) {
			event.renderData( type="json", data={
				  success = false
				, message = translateResource( "cms:assetmanager.chunked.upload.error.invalid.chunk" )
			} );
			return;
		}

		var chunkPath = "";
		try {
			var fileUpload = runEvent(
				  event          = "preprocessors.FileUpload.index"
				, eventArguments = { fieldName="chunkData", readBinary=true }
				, private        = true
				, prePostExempt  = true
			);

			chunkPath = fileUpload.path ?: "";

			if ( !Len( Trim( chunkPath ) ) ) {
				event.renderData( type="json", data={
					  success = false
					, message = translateResource( "cms:assetmanager.chunked.upload.error.no.chunk.data" )
				} );
				return;
			}

			var saved = chunkedUploadService.saveChunk(
				  uuid        = uuid
				, chunkNumber = chunkNumber
				, chunkData   = FileReadBinary( chunkPath )
			);

			event.renderData( type="json", data={
				  success = saved
				, message = saved ? "" : translateResource( "cms:assetmanager.chunked.upload.error.save.chunk" )
			} );

		} catch ( any e ) {
			event.renderData( type="json", data={
				  success = false
				, message = translateResource( "cms:assetmanager.chunked.upload.error.chunk", { data=[ e.message ] } )
			} );
		} finally {
			if ( Len( Trim( chunkPath ) ) && FileExists( chunkPath ) ) { FileDelete( chunkPath ); }
		}
	}

	/**
	 * Verify all chunks are present, assemble and save as a Preside asset.
	 */
	function finalize( event, rc, prc ) {
		var uuid             = rc.uuid             ?: "";
		var folder           = rc.folder           ?: "";
		var totalChunks      = Val( rc.totalChunks ?: 0 );
		var originalFilename = rc.originalFilename ?: "";

		if ( !Len( Trim( uuid ) ) || totalChunks <= 0 || !Len( Trim( originalFilename ) ) ) {
			event.renderData( type="json", data={
				  success = false
				, message = translateResource( "cms:assetmanager.chunked.upload.error.missing.parameters" )
			} );
			return;
		}

		if ( !Len( Trim( folder ) ) ) {
			folder = assetManagerService.getRootFolderId();
		}

		chunkedUploadService.cleanupStaleSessions();

		var result = chunkedUploadService.assembleAndSave(
			  uuid             = uuid
			, folder           = folder
			, assetData        = { title=( rc.title ?: "" ), description=( rc.description ?: "" ) }
			, totalChunks      = totalChunks
			, originalFilename = originalFilename
		);

		event.renderData( type="json", data={
			  success = result.success
			, message = result.success ? translateResource( "cms:assetmanager.chunked.upload.success" ) : translateResource( "cms:assetmanager.chunked.upload.error.assemble" )
			, assetId = result.assetId
		} );
	}

	/**
	 * Renders the upload-new-version page. Restricts to a single file of the
	 * same type as the existing asset, no folder/author fields.
	 */
	function uploadNewVersionPage( event, rc, prc ) {
		var assetId = rc.asset ?: "";

		if ( !Len( Trim( assetId ) ) ) {
			event.notFound();
		}

		var asset = assetManagerService.getAsset( id=assetId );
		if ( !asset.recordCount ) {
			event.notFound();
		}

		var fileTypeInfo     = assetManagerService.getAssetType( name=asset.asset_type );
		var allowedExtension = Len( Trim( fileTypeInfo.extension ?: "" ) ) ? ".#fileTypeInfo.extension#" : "";
		var folder           = asset.asset_folder ?: "";
		var folderRestrictions = Len( Trim( folder ) ) ? assetManagerService.getFolderRestrictions( id=folder ) : {};
		var maxFileSize      = Val( folderRestrictions.maxFileSize ?: getSetting( name="assetManager" ).maxFileSize ?: 100 );
		var chunkingThreshold = 0; // Force all files through chunked path on this page

		event.includeData( {
			  allowedExtensions         = allowedExtension
			, maxFileSize               = maxFileSize
			, chunkingThreshold         = chunkingThreshold
			, chunkedUploadChunkUrl     = event.buildAdminLink( linkto="chunkedUpload.uploadChunk" )
			, chunkedUploadFinalizeUrl  = event.buildAdminLink( linkto="chunkedUpload.finalizeNewVersion" )
			, maxFiles                  = 1
		} );

		prc.asset            = asset;
		prc.assetId          = assetId;
		prc.pageIcon         = "picture-o";
		prc.pageTitle        = translateResource( "cms:assetManager" );
		prc.pageSubTitle     = translateResource( "cms:assetmanager.upload.new.version.title" );
	}

	/**
	 * Assembles the uploaded chunks and saves as a new version of an existing asset.
	 */
	function finalizeNewVersion( event, rc, prc ) {
		var uuid             = rc.uuid             ?: "";
		var assetId          = rc.assetId          ?: "";
		var totalChunks      = Val( rc.totalChunks ?: 0 );
		var originalFilename = rc.originalFilename ?: "";

		if ( !Len( Trim( uuid ) ) || !Len( Trim( assetId ) ) || totalChunks <= 0 || !Len( Trim( originalFilename ) ) ) {
			event.renderData( type="json", data={
				  success = false
				, message = translateResource( "cms:assetmanager.chunked.upload.error.missing.parameters" )
			} );
			return;
		}

		chunkedUploadService.cleanupStaleSessions();

		var assembled = chunkedUploadService.assembleTempFile(
			  uuid        = uuid
			, totalChunks = totalChunks
		);

		if ( !assembled.success ) {
			event.renderData( type="json", data={
				  success = false
				, message = translateResource( "cms:assetmanager.chunked.upload.error.assemble" )
			} );
			return;
		}

		try {
			var success = assetManagerService.addAssetVersion(
				  assetId  = assetId
				, filePath  = assembled.filePath
				, fileName  = originalFilename
				, fileSize  = assembled.fileSize
			);

			if ( success ) {
				event.renderData( type="json", data={
					  success  = true
					, message  = translateResource( "cms:assetmanager.upload.new.version.confirmation" )
					, assetId  = assetId
					, redirect = event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=#assetId#" )
				} );
			} else {
				event.renderData( type="json", data={
					  success = false
					, message = translateResource( "cms:assetmanager.upload.new.version.unknown.error" )
				} );
			}
		} catch ( AssetManager.mismatchedGroupName e ) {
			event.renderData( type="json", data={
				  success = false
				, message = translateResource( "cms:assetmanager.upload.new.version.mismatched.type.error" )
			} );
		} catch ( any e ) {
			logError( e );
			event.renderData( type="json", data={
				  success = false
				, message = translateResource( "cms:assetmanager.chunked.upload.error.chunk", { data=[ e.message ] } )
			} );
		} finally {
			// Clean up the temp directory after addAssetVersion is done
			var tempDir = GetTempDirectory() & "preside_chunked_" & uuid & "/";
			if ( DirectoryExists( tempDir ) ) {
				try { DirectoryDelete( tempDir, true ); } catch ( any ignored ) {}
			}
		}
	}

	private void function _checkPermissions( event, rc, prc, required string key ) {
		var permKey   = "assetmanager." & arguments.key;
		var permitted = Len( Trim( rc.folder ?: "" ) )
			? hasCmsPermission( permissionKey=permKey, context="assetmanagerfolder", contextKeys=prc.permissionContext ?: [] )
			: hasCmsPermission( permissionKey=permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

}
