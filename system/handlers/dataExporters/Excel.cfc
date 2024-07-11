/**
 * @exportFileExtension xlsx
 * @exportMimeType      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
 * @feature             dataExport
 */
component {

	property name="spreadsheetLib"       inject="spreadsheetLib";
	property name="presideObjectService" inject="presideObjectService";

	private any function export(
		  required struct fieldTitles
		, required any    batchedRecordIterator
		, required struct meta
		, required string objectName
		, required struct propertyRendererMap
	) {
		var tmpFile       = getTempFile( getTempDirectory(), "ExcelExport" );
		var workbook      = spreadsheetLib.new( xmlformat=true, streamingXml=true );
		var data          = [];
		var dataCols      = [];
		var dataColTypes  = [];
		var row           = 1;
		var col           = 0;
		var objectUriRoot = presideObjectService.getResourceBundleUriRoot( arguments.objectName );
		var sheetName     = translateResource( uri=objectUriRoot & "title", defaultValue=arguments.objectname );
			sheetName     = _cleanSheetName( sheetName );

		if ( len( sheetName ) ) {
			spreadsheetLib.renameSheet( workbook, sheetName, 1 );
		}

		do {
			data         = arguments.batchedRecordIterator();
			dataCols     = ListToArray( data.columnList );
			dataColTypes = _getColumnDataTypes( data, arguments.propertyRendererMap );

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
					spreadsheetLib.setCellValue( workbook, record[ field ] ?: "", row, col, dataColTypes[ col ] ?: "string" );
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

	private string function _cleanSheetName( required string sheetname ) {
		var name = rereplace( arguments.sheetname, "[\\\/\*\[\]\:\?]", " ", "all" );
		name     = trim( rereplace( name, "\s+", " ", "all" ) );
		name     = trim( left( name, 31 ) );

		return name;
	}

	private array function _getColumnDataTypes( required query data, required struct propertyRendererMap ) {
		var mappingBehaviour = getSystemSetting( "data-export", "excel_data_types" );
		var metadata         = getMetaData( arguments.data );
		var dataTypes        = [];

		if ( mappingBehaviour == "string" ) {
			return [];
		}

		for( var colDef in metadata ) {
			var typeName = colDef.typeName ?: "";
			if ( ( arguments.propertyRendererMap[ colDef.name ] ?: "none" ) != "none" ) {
				typeName = arguments.propertyRendererMap[ colDef.name ];
			}
			switch( LCase( typeName ) ) {
				case "double":
				case "float":
				case "decimal":
				case "money":
				case "integer":
				case "int":
				case "smallint":
				case "bigint":
					ArrayAppend( dataTypes, "numeric" );
					break;
				case "boolean":
				case "bit":
					ArrayAppend( dataTypes, "boolean" );
					break;
				case "timestamp":
				case "date":
				case "datetime":
					ArrayAppend( dataTypes, "date" );
					break;
				case "time":
					ArrayAppend( dataTypes, "time" );
					break;
				default:
					ArrayAppend( dataTypes, "string" );
					break;
			}
		}

		return dataTypes;
	}
}