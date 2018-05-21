component output=false {

	private any function index( event, rc, prc, fieldName="", preProcessorArgs={} ) output=false {
		var tempFile     = GetTempDirectory() & "/" & createUUID();
		var uploadResult = "";

		if ( not Len( Trim( rc[ arguments.fieldName ] ?: "" ) ) ) {
			return {};
		}

		try {
			uploadResult = FileUpload( tempFile, arguments.fieldName );

			if ( listFindNoCase( "tif,tiff", ListLast( uploadResult.serverFile, "." ) ) ) {
				var file = uploadResult.serverDirectory & "\" & uploadResult.serverFile;
				var update = replaceNoCase( file,ListLast( ListLast( file,"\" ),"." ), "jpg" );
				cfimage ( source = file, name="mySourceImg" )
  		    	cfimage ( action = "convert", source = mySourceImg ,destination= update ,overwrite="true" );
  		    	uploadResult.clientFile = replaceNoCase( uploadResult.clientFile ,ListLast(uploadResult.clientFile,"." ), "jpg" );
  		    	uploadResult.serverFile = replaceNoCase( uploadResult.serverFile ,ListLast(uploadResult.serverFile,"." ), "jpg" );
			}
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
