/**
 * @exportFileExtension xlsx
 * @exportMimeType      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
 *
 */
component {

	property name="spreadsheetLib"       inject="spreadsheetLib";
	property name="presideObjectService" inject="presideObjectService";

	private any function export(
		  required struct fieldTitles
		, required any    batchedRecordIterator
		, required struct meta
		, required string objectName
	) {
		var tmpFile       = getTempFile( getTempDirectory(), "ExcelExport" );
		var workbook      = spreadsheetLib.new( xmlformat=true );
		var data          = [];
		var dataCols      = [];
		var row           = 1;
		var col           = 0;
		var objectUriRoot = presideObjectService.getResourceBundleUriRoot( arguments.objectName );
		var objectTitle   = translateResource( uri=objectUriRoot & "title", defaultValue=arguments.objectname );

		objectTitle = Left( objectTitle, 31 );
		spreadsheetLib.renameSheet( workbook, objectTitle, 1 );

		do {
			data     = arguments.batchedRecordIterator();
			dataCols = ListToArray( data.columnList );

			if ( row == 1 ) {
				for( var i=1; i <= dataCols.len(); i++ ){
					spreadsheetLib.setCellValue( workbook, ( fieldTitles[ dataCols[i] ] ?: "" ), 1, i );
				}
			}
			for( var record in data ) {
				row++;
				col = 0;
				for( var field in dataCols ) {
					col++;
					spreadsheetLib.setCellValue( workbook, record[ field ] ?: "", row, col, "string" );
				}
			}
		} while( data.recordCount );

		spreadsheetLib.formatRow( workbook, { bold=true }, 1 );
		spreadsheetLib.addFreezePane( workbook, 0, 1 );
		for( var i=1; i <= dataCols.len(); i++ ){
			spreadsheetLib.autoSizeColumn( workbook, i );
		}

		spreadsheetLib.write( workbook, tmpFile, true );

		return tmpFile;
	}
}