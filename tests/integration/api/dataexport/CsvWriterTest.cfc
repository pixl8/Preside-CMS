component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "CSV Writer", function(){
			it( "should create a CSV file with suitably escaped entries", function(){
				var service = _getService();
				var csvFile = GetTempFile( GetTempDirectory(), "" ) & ".csv";
				var writer  = service.newWriter( csvFile, Chr(9) );

				writer.writeNext( [ "Title", "Row", "Here" ] )
				      .writeNext( [ "Row 1", "Some content 	with tabs in", "Some ""content ""with quotes""" ] )
				      .flush()
				      .writeNext( [ "Row 2", "Some content 	with tabs in", "Some ""content ""with quotes""" ] )
				      .writeNext( [ "Row 3", "Some content 	with tabs in", "Some ""content ""with quotes""" ] )
				      .close();

				expect( FileRead( csvFile ) ).toBe( FileRead( "/resources/csvWriter/csvWriterTestFile.csv" ) );
			} );
		} );
	}

// private helpers
	private any function _getService() {
		return new preside.system.services.dataExport.CsvWriter();
	}
}