component output="false" extends="mxunit.framework.TestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		adapter = new preside.system.services.updateManager.UpdateManagerService( repositoryUrl="", presidePath="/tests/resources/updateManager" );
		adapter = getMockBox().createMock( object=adapter );


	}

// TESTS
	function test01_listVersions_shouldReturnVersionsOfPresideBasedOnContentsOfS3BucketForGivenReleaseBranch() output=false {
		var adapter  = _getAdapter();
		var expected = [ "0.1.1.00089", "0.1.2.00345" ];

		adapter.$( "_fetchS3BucketListing", XmlParse( "/tests/resources/updateManager/s3BucketListing.xml" ) );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.1.json" ).$results( { version:"0.1.1.00089" } );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.2.json" ).$results( { version:"0.1.2.00345" } );

		super.assertEquals( expected, adapter.listVersions( branch="bleedingEdge" ) );
	}

	function test02_getCurrentVersion_shouldReturnVersionAsIndicatedByVersionFileInRootOfPresideInstall() output=false {
		var adapter  = _getAdapter();
		super.assertEquals( "10.0.2.00045", adapter.getCurrentVersion() );

	}

	function test03_getCurrentVersion_shouldReturnUnknownWhenVersionFileDoesNotExist() output=false {
		var adapter  = _getAdapter( presidePath="/tests" );

		super.assertEquals( "unknown", adapter.getCurrentVersion() );
	}

// PRIVATE HELPERS
	private any function _getAdapter( repositoryUrl="", presidePath="/tests/resources/updateManager" ) output=false  {
		adapter = new preside.system.services.updateManager.UpdateManagerService( argumentCollection=arguments );
		return getMockBox().createMock( object=adapter );
	}
}