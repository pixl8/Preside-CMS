component {

	private any function index( event, rc, prc, fieldName="", preProcessorArgs={}, readBinary=true ) {
		var tempFile     = GetTempDirectory() & "/" & createUUID();
		var uploadResult = "";

		if ( not Len( Trim( rc[ arguments.fieldName ] ?: "" ) ) ) {
			return {};
		}

		try {
			uploadResult = FileUpload( tempFile, arguments.fieldName );
			var convertTiffs = IsTrue( getSystemSetting( category="asset-manager", setting="tiff_conversion", default=false ) );
			if ( ListFindNoCase( "tif,tiff", ListLast( uploadResult.serverFile, "." ) ) && convertTiffs ) {
				var file = uploadResult.serverDirectory & "\" & uploadResult.serverFile;
				var update = ReplaceNoCase( file, ListLast( ListLast( file, "\/" ), "." ), "jpg" );
				var sourceImg = "";
				image source=file name="sourceImg";
			    image action="convert" source= sourceImg destination=update overwrite=true;
			    uploadResult.clientFile = ReplaceNoCase( uploadResult.clientFile ,ListLast( uploadResult.clientFile, "." ), "jpg" );
			    uploadResult.serverFile = ReplaceNoCase( uploadResult.serverFile ,ListLast( uploadResult.serverFile, "." ), "jpg" );
			}
		} catch ( any e ) {
			logError( e );
		}

		if ( ! ( uploadResult.fileWasSaved ?: false ) ) {
			throw( message="Failed to upload file." );
		}

		var returnInfo = {
			  fileName     = uploadResult.clientFile
			, size         = uploadResult.fileSize
			, path         = uploadResult.serverDirectory & "/" & uploadResult.serverFile
			, tempFileInfo = uploadResult
		};

		if ( arguments.readBinary && IsTrue( arguments.preProcessorArgs.preProcessBinary ?: true ) ) {
			returnInfo.binary = FileReadBinary( returnInfo.path );
		}

		return returnInfo;
	}

}
