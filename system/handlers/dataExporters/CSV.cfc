/**
 * @exportFileExtension csv
 * @exportMimeType      text/csv
 *
 */
component {

	property name="csvWriter" inject="csvWriter";

	private any function export(
		  required array  selectFields
		, required struct fieldTitles
		, required any    batchedRecordIterator
	) {
		var tmpFile = getTempFile( getTempDirectory(), "CSVEXport" );
		var writer  = csvWriter.newWriter( tmpFile, Chr( 9 ) );
		var row     = [];
		var data    = "";

		try {
			for( var field in arguments.selectFields ) {
				row.append( arguments.fieldTitles[ field ] ?: "?" );
			}
			writer.writeNext( row );

			do {
				data = arguments.batchedRecordIterator();
				for( var record in data ) {
					row  = [];
					for( var field in arguments.selectFields ) {
						row.append( record[ field ] ?: "" );
					}
					writer.writeNext( row );
				}
				writer.flush;
			} while( data.recordCount );

		} catch ( any e ) {
			rethrow;
		} finally {
			writer.close();
		}

		return tmpFile;
	}
}