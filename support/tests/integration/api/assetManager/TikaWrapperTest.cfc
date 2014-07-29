component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		tikaWrapper = new preside.system.services.assetManager.TikaWrapper();
	}

// TESTS
	function test01_getMetaData_shouldExtractMetaDataFromThePassedDocument() output=false {
		var fileBinary = FileReadBinary( "/tests/resources/tikaWrapper/testdocument.pdf" );
		var meta = tikaWrapper.getMetaData( fileBinary );
		var expectedMeta = {
			  author   = "Dominic Watson"
			, title    = "Test document"
			, subject  = "Test subject"
			, keywords = "Test keywords"
		};

		for( var key in expectedMeta ) {
			super.assertEquals( expectedMeta[ key ], meta[ key ] ?: "" );
		}
	}

	function test02_getMetaData_shouldExtractMetaDataFromThePassedJpgFilePath() output=false {
		var fileBinary = FileReadBinary( "/tests/resources/tikaWrapper/jpg_with_exif.jpg" );
		var meta = tikaWrapper.getMetaData( fileBinary );
		var expectedMeta = {
			  comment   = "Finlay McWalter made this"
			, Copyright = "Copyright Cthulhu"
		};

		for( var key in expectedMeta ) {
			super.assertEquals( expectedMeta[ key ], meta[ key ] ?: "" );
		}
	}


}