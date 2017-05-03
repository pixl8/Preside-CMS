---
id: dataexporters
title: Creating custom data exporters
---

## Overview

As of **10.8.1**, PresideCMS comes with a data export system and a concept of custom data exporters. A data exporter consists of a single handler action and an i18n `.properties` file to describe it.

The core system comes with a CSV exporter and an Excel exporter. The exporter logic is responsible for accepting data and some metadata about the export and for then producing a file.

### Step 1: Create exporter handler

All exporter handlers must live under `/handlers/dataExporters/` folder. The name of the handler is considered the ID of the exporter. The CSV exporter, for example, lives at `/handlers/dataExporters/CSV.cfc`.

The handler must declare mime type and file extension in its component attributes and implement an `export` method. For example:

```luceescript
/**
 * @exportFileExtension csv
 * @exportMimeType      text/csv
 *
 */
component {

	property name="csvWriter" inject="csvWriter";

	private string function export(
		  required array  selectFields
		, required struct fieldTitles
		, required any    batchedRecordIterator
		,          struct meta
	) {
		// create a tmp file and instantiate TAB delimited CSV writer
		var tmpFile = getTempFile( getTempDirectory(), "CSVEXport" );
		var writer  = csvWriter.newWriter( tmpFile, Chr( 9 ) );
		var row     = [];
		var data    = "";

		try {
			// create title row
			for( var field in arguments.selectFields ) {
				row.append( arguments.fieldTitles[ field ] ?: "?" );
			}
			writer.writeNext( row );

			// repeatedly call batchedRecordIterator until
			// no data left, adding rows to our CSV
			do {
				data = arguments.batchedRecordIterator();
				for( var record in data ) {
					row  = [];
					for( var field in arguments.selectFields ) {
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

		// return filepath of file containing our CSV
		return tmpFile;
	}
}
```

#### Arguments to the EXPORT method

**batchedRecordIterator**

An anonymous function that can be called repeatedly to get the next batch of data (a CFML query object). The function accepts no arguments. Example usage:

```luceescript
var data = "";
do {
	data = batchedRecordIterator();
	// ... your exporter logic for data
} while( data.recordCount );
```

**selectFields**

An array of fieldnames in the data. The order of this array should be respected for table based exports.

**fieldTitles**

A struct of human readable field _titles_ that correspond to the field _names_ in the `selectFields` array. For example:

```luceescript
selectFields = [ "field1", "field2", "field3" ];
fieldTitles  = {
	  field1 = "Field 1"
	, field2 = "Field 2"
	, field3 = "Field 3"
};
```

**meta**

A struct of arbitrary metadata to do with the export. This may be used to embed in a document for example. Keys may include `title`, `author`, `datecreated` and so on. Individual exporters may wish to use this metadata in their exported documents.

### Step 2: Create exporter .properties file

A corresponding `.properties` file should live at `/i18n/dataExporters/{exporterId}.properties`. Three keys are required, `title`, `description` and `iconClass`. e.g.

```properties
title=CSV File
description=Download data in plain text CSV (Character Separated Values)
iconClass=fa-table
```
