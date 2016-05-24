component output=false {

	private any function index( event, rc, prc, fieldName="", preProcessorArgs={} ) output=false {
		var tempFile     = GetTempDirectory() & "/" & createUUID();
		var uploadResult = "";

		if ( not Len( Trim( rc[ arguments.fieldName ] ?: "" ) ) ) {
			return {};
		}

		try {
			uploadResult = FileUpload( tempFile, arguments.fieldName );
		} catch ( any e ) {
			logError( e );
		}

		if ( ! ( uploadResult.fileWasSaved ?: false ) ) {
			throw( message="Failed to upload file." );
		}

		return {
			  fileName     = uploadResult.clientFile
			, size         = uploadResult.fileSize
			, binary       = FileReadBinary( uploadResult.serverDirectory & "/" & uploadResult.serverFile )
			, tempFileInfo = uploadResult
		};
	}

}
