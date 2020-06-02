/**
 * @singleton true
 *
 */
component {

// PUBLIC API METHODS
	public any function writeNext( required array line ) {
		getOpenCsvWriter().writeNext( arguments.line );
		return this;
	}

	public any function flush() {
		getOpenCsvWriter().flush();
		return this;
	}

	public void function close() {
		getOpenCsvWriter().close();
	}

// FACTORY METHODS
	public any function newWriter(
		  required string filePath
		,          string delimiter = ","
	) {
		var fileWriter    = CreateObject( "java", "java.io.FileWriter" ).init( arguments.filePath );
		var openCsvWriter = CreateObject( "java", "com.opencsv.CSVWriter", [ "/preside/system/services/dataExport/lib/opencsv-3.8.jar" ] ).init( fileWriter, JavaCast( "char", arguments.delimiter ) );
		var writer        = Duplicate( this );

		writer.setOpenCsvWriter( openCsvWriter );

		return writer;
	}

	public void function setOpenCsvWriter( required any writer ) {
		_openCsvWriter = arguments.writer;
	}
	public any function getOpenCsvWriter() {
		return _openCsvWriter ?: throw( type="preside.csvWriter.not.initialized", message="Writer not initialized. Use the newWriter() method to get a new initialized instance of a writer." );
	}

}