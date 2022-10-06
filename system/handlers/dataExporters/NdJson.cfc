/**
 * @exportFileExtension ndjson
 * @exportMimeType      application/x-ndjson
 * @feature             dataExporterNDJSON
 *
 */
component {

	private any function export(
		  required struct fieldTitles
		, required any    batchedRecordIterator
	) {
		var tempFile = getTempFile( getTempDirectory(), "NdJsonExport" );
		var openFile = FileOpen( tempFile, "write" );
		var data     = "";

		try {
			do {
				data = arguments.batchedRecordIterator();

				for( var record in data ) {
					FileWriteLine( openFile, SerializeJson( record ) );
				}
			} while( data.recordCount );

		} catch ( any e ) {
			rethrow;
		} finally {
			FileClose( openFile );
		}

		return tempFile;
	}
}