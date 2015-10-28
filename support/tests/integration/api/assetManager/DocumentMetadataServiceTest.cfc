component extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		metaService = new preside.system.services.assetManager.DocumentMetadataService();
	}

// TESTS
	function test01_getMetaData_shouldExtractMetaDataFromThePassedDocument() {
		var fileBinary = FileReadBinary( "/tests/resources/documentMetadataService/testdocument.pdf" );
		var meta = metaService.getMetaData( fileBinary );
		var expectedMeta = {};

		for( var key in expectedMeta ) {
			super.assertEquals( expectedMeta[ key ], meta[ key ] ?: "" );
		}
	}

	function test02_getMetaData_shouldExtractMetaDataFromThePassedJpgFilePath() {
		var fileBinary = FileReadBinary( "/tests/resources/documentMetadataService/jpg_with_exif.jpg" );
		var meta = metaService.getMetaData( fileBinary );
		var expectedMeta = {
			  width  = 100
			, height = 100
		};

		for( var key in expectedMeta ) {
			super.assertEquals( expectedMeta[ key ], meta[ key ] ?: "" );
		}
	}


}