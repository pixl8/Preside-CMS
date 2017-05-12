/**
 * @exportFileExtension xls
 * @exportMimeType      application/vnd.ms-excel
 *
 */
component {

	property name="spreadsheetLib"       inject="spreadsheetLib";
	property name="presideObjectService" inject="presideObjectService";

	private any function export(
		  required array  selectFields
		, required struct fieldTitles
		, required any    batchedRecordIterator
		, required struct meta
		, required string objectName
	) {
		var tmpFile       = getTempFile( getTempDirectory(), "ExcelExport" );
		var workbook      = spreadsheetLib.new();
		var headers       = [];
		var row           = 1;
		var col           = 0;
		var objectUriRoot = presideObjectService.getResourceBundleUriRoot( arguments.objectName );
		var objectTitle   = translateResource( uri=objectUriRoot & "title", defaultValue=arguments.objectname );

		spreadsheetLib.renameSheet( workbook, objectTitle, 1 );

		for( var i=1; i <= arguments.selectFields.len(); i++ ){
			spreadsheetLib.setCellValue( workbook, ( fieldTitles[ arguments.selectFields[i] ] ?: "" ), 1, i );
		}

		do {
			data = arguments.batchedRecordIterator();
			for( var record in data ) {
				row++;
				col = 0;
				for( var field in arguments.selectFields ) {
					col++;
					spreadsheetLib.setCellValue( workbook, record[ field ] ?: "", row, col, "string" );
				}
			}
		} while( data.recordCount );

		spreadsheetLib.formatRow( workbook, { bold=true }, 1 );
		spreadsheetLib.addFreezePane( workbook, 0, 1 );
		for( var i=1; i <= headers.len(); i++ ){
			spreadsheetLib.autoSizeColumn( workbook, i );
		}

		spreadsheetLib.write( workbook, tmpFile, true );

		return tmpFile;
	}
}