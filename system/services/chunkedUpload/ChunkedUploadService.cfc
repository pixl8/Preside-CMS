/**
 * @singleton
 * @presideService
 * @feature        assetManager
 *
 */
component {

	/**
	 * @assetManagerService.inject assetManagerService
	 * @errorLogService.inject     errorLogService
	 *
	 */
	public any function init(
		  required any assetManagerService
		, required any errorLogService
	) {
		_setAssetManagerService( arguments.assetManagerService );
		_setErrorLogService( arguments.errorLogService );

		return this;
	}

	/**
	 * Save a chunk to the temp directory.
	 * The temp dir is created on first chunk. No separate session step required.
	 *
	 * @uuid        Unique upload identifier generated client-side
	 * @chunkNumber 1-based chunk index
	 * @filePath    Path to the uploaded chunk temp file (copied to chunk dir; caller cleans up source)
	 */
	public boolean function saveChunk(
		  required string  uuid
		, required numeric chunkNumber
		, required string  filePath
	) {
		var tempDir   = _getTempDir( arguments.uuid );
		var chunkFile = tempDir & "chunk_" & arguments.chunkNumber & ".bin";

		if ( !DirectoryExists( tempDir ) ) {
			DirectoryCreate( tempDir );
		}
		FileCopy( arguments.filePath, chunkFile );

		return true;
	}

	/**
	 * Assembles chunks into a temp file and returns the path + size.
	 * The caller is responsible for cleanup on success. Used when the assembled
	 * file needs to be processed differently (e.g. as a new asset version).
	 *
	 * @uuid        Upload identifier
	 * @totalChunks Expected number of chunks
	 */
	public struct function assembleTempFile( required string uuid, required numeric totalChunks ) {
		var result   = { success=false, message="", filePath="", fileSize=0 };
		var tempDir  = _getTempDir( arguments.uuid );
		var tempFile = tempDir & "assembled.tmp";

		try {
			var fileOutputStream = createObject( "java", "java.io.FileOutputStream" ).init( javacast( "string", tempFile ) );

			try {
				for ( var i = 1; i <= arguments.totalChunks; i++ ) {
					var chunkFile = tempDir & "chunk_" & i & ".bin";
					if ( FileExists( chunkFile ) ) {
						fileOutputStream.write( FileReadBinary( chunkFile ) );
					} else {
						result.message = "Missing chunk " & i;
						return result;
					}
				}
			} finally {
				fileOutputStream.close();
			}

			result.success  = true;
			result.filePath = tempFile;
			result.fileSize = GetFileInfo( tempFile ).size;

		} catch ( any e ) {
			_getErrorLogService().raiseError( e );
			result.message = e.message;
			_cleanupTempFiles( tempDir );
		}

		return result;
	}

	/**
	 * Assembles uploaded chunks and saves as a new Preside asset.
	 * Delegates assembly to assembleTempFile() and always cleans up temp files.
	 *
	 * @uuid             Upload identifier
	 * @folder           Target Preside asset folder ID
	 * @assetData        Additional asset metadata (title, description)
	 * @totalChunks      Expected total number of chunks
	 * @originalFilename Original client filename
	 */
	public struct function assembleAndSave(
		  required string  uuid
		, required string  folder
		, required struct  assetData
		, required numeric totalChunks
		, required string  originalFilename
	) {
		var result    = { success=false, message="", assetId="" };
		var assembled = assembleTempFile( uuid = arguments.uuid, totalChunks = arguments.totalChunks );

		if ( !assembled.success ) {
			// assembleTempFile cleans up on exception but not on missing-chunk early return,
			// so call cleanup defensively here (_cleanupTempFiles ignores missing dirs)
			_cleanupTempFiles( _getTempDir( arguments.uuid ) );
			return { success=false, message=assembled.message, assetId="" };
		}

		try {
			var assetId = _getAssetManagerService().addAsset(
				  filePath          = assembled.filePath
				, fileSize          = assembled.fileSize
				, folder            = arguments.folder
				, fileName          = arguments.originalFilename
				, assetData         = arguments.assetData
				, ensureUniqueTitle = true
			);

			result.success = true;
			result.assetId = assetId;

		} catch ( any e ) {
			_getErrorLogService().raiseError( e );
			result.message = e.message;
		} finally {
			_cleanupTempFiles( _getTempDir( arguments.uuid ) );
		}

		return result;
	}

// PRIVATE HELPERS

	public boolean function isValidUUID( required string uuid ) {
		return ReFind( "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", arguments.uuid ) > 0;
	}

	private string function _getTempDir( required string uuid ) {
		if ( !isValidUUID( arguments.uuid ) ) {
			throw( type="ChunkedUploadService.invalidUUID", message="Invalid upload UUID format" );
		}
		return GetTempDirectory() & "preside_chunked_" & arguments.uuid & "/";
	}

	public void function cleanupTempDir( required string uuid ) {
		_cleanupTempFiles( _getTempDir( arguments.uuid ) );
	}

	private void function _cleanupTempFiles( required string tempDir ) {
		if ( DirectoryExists( tempDir ) ) {
			try {
				DirectoryDelete( tempDir, true );
			} catch ( any e ) {
				// Ignore
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getAssetManagerService() { return _assetManagerService; }
	private void function _setAssetManagerService( required any assetManagerService ) { _assetManagerService = arguments.assetManagerService; }

	private any function _getErrorLogService() { return _errorLogService; }
	private void function _setErrorLogService( required any errorLogService ) { _errorLogService = arguments.errorLogService; }

}
