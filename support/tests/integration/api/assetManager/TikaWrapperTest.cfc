component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		tikaWrapper = new preside.system.services.assetManager.TikaWrapper();
	}

// TESTS
	function test01_getMetaData_shouldExtractMetaDataFromThePassedDocumentFilePath() output=false {
		var meta = tikaWrapper.getMetaData( ExpandPath( "/tests/resources/tikaWrapper/testdocument.pdf" ) );
		var expectedMeta = {
			  author   = "Dominic Watson"
			, title    = "Test document"
			, subject  = "Test subject"
			, keywords = "Test keywords"
		};

		super.assert( StructCount( meta ) );

		for( var key in expectedMeta ) {
			super.assertEquals( expectedMeta[ key ], meta[ key ] ?: "" );
		}
	}


}