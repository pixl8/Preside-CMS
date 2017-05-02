component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "readExporterFromCfcMetadata()", function(){
			it( "should return details of exporter as read from component metadata + with translated convention based name, icon and description", function(){
				var service = _getService();
				var meta    = {
					  exportFileExtension = "xlsx"
					, exportMimeType      = "application/octet-stream"
					, name                = "app.handlers.dataexporter.Excel"
				};

				service.$( "$translateResource" ).$args( uri="dataexporters.Excel:title"      , defaultValue="Excel"       ).$results( "Microsoft Excel" );
				service.$( "$translateResource" ).$args( uri="dataexporters.Excel:description", defaultValue=""            ).$results( "This is an excel exporter..." );
				service.$( "$translateResource" ).$args( uri="dataexporters.Excel:iconClass"  , defaultValue="fa-download" ).$results( "fa-file-excel" );

				var exporter = service.readExporterFromCfcMetadata( meta );

				expect( exporter ).toBe( {
					  id            = "excel"
					, fileExtension = "xlsx"
					, mimeType      = "application/octet-stream"
					, title         = "Microsoft Excel"
					, description   = "This is an excel exporter..."
					, iconClass     = "fa-file-excel"
				} );
			} );

			it( "should throw an informative error when the handler CFC does not specify a file extension", function(){
				var service = _getService();
				var meta    = {
					  exportMimeType = "application/octet-stream"
					, name           = "app.handlers.dataexporter.Excel"
				};
				var errorThrown = false;

				try {
					service.readExporterFromCfcMetadata( meta );
				} catch( "preside.dataExporter.missing.param" e ) {
					expect( e.message ).toBe( "The data exporter [#meta.name#] does not define a file extension for exported files. All exporters must define an extension with the @exportFileExtension attribute on the CFC file (see documentation for further details)." );
					errorThrown = true;
				}

				expect( errorThrown ).toBeTrue();
			} );

			it( "should throw an informative error when the handler CFC does not specify a mime type", function(){
				var service = _getService();
				var meta    = {
					  name                = "app.handlers.dataexporter.Excel"
					, exportFileExtension = "blah"
				};
				var errorThrown = false;

				try {
					service.readExporterFromCfcMetadata( meta );
				} catch( "preside.dataExporter.missing.param" e ) {
					expect( e.message ).toBe( "The data exporter [#meta.name#] does not define an export file mimetype. All exporters must define an export mime type with the @exportMimeType attribute on the CFC file (see documentation for further details)." );
					errorThrown = true;
				}

				expect( errorThrown ).toBeTrue();
			} );
		} );
	}

// private helpers
	private any function _getService() {
		var service = createMock( object=new preside.system.services.dataExport.DataExporterReader( [] ) );

		return service;
	}
}