/**
 * @exportFileExtension csv
 * @exportMimeType      text/csv
 *
 */
component {

	property name="csvWriter" inject="csvWriter";
	property name="csvExportDelimiter" inject="coldbox:setting:dataExport.csv.delimiter";

	private any function export(
		  required struct fieldTitles
		, required any    batchedRecordIterator
	) {
		var tmpFile  = getTempFile( getTempDirectory(), "CSVExport" );
		var writer   = csvWriter.newWriter( tmpFile, csvExportDelimiter );
		var row      = [];
		var data     = "";
		var dataCols = "";

		try {
			do {
				data     = arguments.batchedRecordIterator();
				dataCols = ListToArray( data.columnList );

				if ( !row.len() ) {
					for( var field in dataCols ) {
						row.append( arguments.fieldTitles[ field ] ?: field );
					}
					writer.writeNext( row );
				}
				for( var record in data ) {
					row  = [];
					for( var field in dataCols ) {
						row.append( record[ field ] ?: "" );
					}
					writer.writeNext( row );
				}
				writer.flush();
			} while( data.recordCount );

		} catch ( any e ) {
			rethrow;
		} finally {
			writer.close();
		}

		return tmpFile;
	}
}