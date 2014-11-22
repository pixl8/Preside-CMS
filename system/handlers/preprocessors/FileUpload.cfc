component output=false {

	private any function index( event, rc, prc, fieldName="", preProcessorArgs={} ) output=false {
		var tempFile     = GetTempDirectory() & "/" & createUUID();
		var uploadResult = "";

		if ( not Len( Trim( rc[ arguments.fieldName ] ?: "" ) ) ) {
			return {};
		}

		try {
			uploadResult = FileUpload( tempFile, arguments.fieldName );
		} catch ( any e ) {}

		if ( ! ( uploadResult.fileWasSaved ?: false ) ) {
			// todo, something more useful here (logging, i18n message, etc.)
			throw( message="Failed to upload file." );
		}

		return {
			  fileName = uploadResult.clientFile
			, size     = uploadResult.fileSize
			, binary   = FileReadBinary( uploadResult.serverDirectory & "/" & uploadResult.serverFile )
		};
	}

}