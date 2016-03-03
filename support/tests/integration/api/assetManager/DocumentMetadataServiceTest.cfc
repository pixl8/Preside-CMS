component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "getMetaData()", function(){

			it( "Should, for now, not attempt to read meta from non-image files, returning an empty struct", function(){
				var metaService = _getService();
				var fileBinary = FileReadBinary( "/tests/resources/documentMetadataService/testdocument.pdf" );
				var meta = metaService.getMetaData( fileBinary );

				expect( meta ).toBe( {} );
			} );

			it( "Should read combined XMP and EXIF metadata from images", function(){
				var metaService = _getService();
				var fileBinary = FileReadBinary( "/tests/resources/documentMetadataService/jpg_with_exif.jpg" );
				var xmp  = { rights="Some copyright notice", test=CreateUUId() };
				var expectedMeta = {
					  width  = 100
					, height = 100
				};

				expectedMeta.append( xmp );
				mockXmpReader.$( "readMeta" ).$args( fileBinary ).$results( xmp );

				var meta = metaService.getMetaData( fileBinary );

				for( var key in expectedMeta ) {
					expect( meta[ key ] ?: "" ).toBe( expectedMeta[ key ] );
				}
			} );

		} );
	}

	private any function _getService() {
		mockXmpReader = createEmptyMock( "preside.system.services.assetmanager.xmp.XmpMetaReader" );
		mockXmpReader.$( "readMeta", {} );

		return new preside.system.services.assetManager.DocumentMetadataService(
			xmpMetaReader = mockXmpReader
		);
	}

}