component output="false" extends="mxunit.framework.TestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		adapter = new preside.system.services.updateManager.UpdateManagerService( repositoryUrl="" );
		adapter = getMockBox().createMock( object=adapter );

		adapter.$( "_fetchS3BucketListing", XmlParse( "/tests/resources/updateManager/s3BucketListing.xml" ) );
	}

// TESTS
	function test01_listVersions_shouldReturnVersionsOfPresideBasedOnContentsOfS3BucketForGivenReleaseBranch() output=false {
		var expected = [ "0.1.1.00089", "0.1.2.00345" ];

		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.1.json" ).$results( { version:"0.1.1.00089" } );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.2.json" ).$results( { version:"0.1.2.00345" } );


		super.assertEquals( expected, adapter.listVersions( branch="bleedingEdge" ) );
	}
}