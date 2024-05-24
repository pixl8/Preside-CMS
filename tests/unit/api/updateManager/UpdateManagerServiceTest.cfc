component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();
	}

// TESTS
	function test02_getCurrentVersion_shouldReturnVersionAsIndicatedByVersionFileInRootOfPresideInstall() output=false {
		var adapter  = _getAdapter();
		super.assertEquals( "10.0.2.00045", adapter.getCurrentVersion() );
	}

	function test03_getCurrentVersion_shouldReturnUnknownWhenVersionFileDoesNotExist() output=false {
		var adapter  = _getAdapter( presidePath="/tests" );

		super.assertEquals( "unknown", adapter.getCurrentVersion() );
	}

	function test10_compareVersions_shouldReturnMinus1_whenFirstVersionIsLessThanSecond() output=false {
		var adapter = _getAdapter();

		super.assertEquals( -1, adapter.compareVersions( "0.9.5", "0.10.43" ) );
	}

	function test11_compareVersions_shouldReturn1_whenFirstVersionIsGreaterThanSecond() output=false {
		var adapter = _getAdapter();

		super.assertEquals( 1, adapter.compareVersions( "0.10.43", "0.9.5" ) );
	}

	function test11_compareVersions_shouldReturn0_whenVersionsAreEqual() output=false {
		var adapter = _getAdapter();

		super.assertEquals( 0, adapter.compareVersions( "0.10.43", "0.10.43" ) );
	}

// PRIVATE HELPERS
	private any function _getAdapter( presidePath="/tests/resources/updateManager" ) output=false  {
		adapter = new preside.system.services.updateManager.UpdateManagerService( argumentCollection=arguments );

		return getMockBox().createMock( object=adapter );
	}
}