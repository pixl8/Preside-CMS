component {

	private any function index( event, rc, prc, fieldName="", preProcessorArgs={} ) output=false {
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

		return {
			  fileName     = uploadResult.clientFile
			, size         = uploadResult.fileSize
			, binary       = FileReadBinary( uploadResult.serverDirectory & "/" & uploadResult.serverFile )
			, tempFileInfo = uploadResult
		};
	}

}
