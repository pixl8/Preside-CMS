component output="false" extends="mxunit.framework.TestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();
	}

// TESTS
	function test01_listVersions_shouldReturnVersionsOfPresideBasedOnContentsOfS3BucketForGivenCurrentBranch() output=false {
		var adapter  = _getAdapter();
		var expected = [ "0.1.1.00089", "0.1.2.00345" ];

		mockSettingsService.$( "getSetting" ).$args( category="updatemanager", setting="branch", default="release" ).$results( "bleedingEdge" );

		adapter.$( "_fetchS3BucketListing", XmlParse( "/tests/resources/updateManager/s3BucketListing.xml" ) );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.1.json" ).$results( { version:"0.1.1.00089" } );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.2.json" ).$results( { version:"0.1.2.00345" } );

		super.assertEquals( expected, adapter.listVersions() );
	}

	function test02_getCurrentVersion_shouldReturnVersionAsIndicatedByVersionFileInRootOfPresideInstall() output=false {
		var adapter  = _getAdapter();
		super.assertEquals( "10.0.2.00045", adapter.getCurrentVersion() );

	}

	function test03_getCurrentVersion_shouldReturnUnknownWhenVersionFileDoesNotExist() output=false {
		var adapter  = _getAdapter( presidePath="/tests" );

		super.assertEquals( "unknown", adapter.getCurrentVersion() );
	}

	function test04_getLatestVersion_shouldReturnTheLatestVersionForTheCurrentBranch() output=false {
		var adapter  = _getAdapter();

		mockSettingsService.$( "getSetting" ).$args( category="updatemanager", setting="branch", default="release" ).$results( "stable" );

		adapter.$( "_fetchS3BucketListing", XmlParse( "/tests/resources/updateManager/s3BucketListing.xml" ) );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/stable/PresideCMS-0.1.0.json" ).$results( { version:"0.1.0.00011" } );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/stable/PresideCMS-0.1.1.json" ).$results( { version:"0.1.1.00089" } );

		super.assertEquals( "0.1.1.00089", adapter.getLatestVersion() );
	}

	function test05_getSettings_shouldFetchSettingsFromSystemConfigurationService() output=false {
		var adapter       = _getAdapter();
		var dummySettings = { branch="bleedingEdge" };

		mockSettingsService.$( "getCategorySettings" ).$args( category="updatemanager" ).$results( dummySettings );

		super.assertEquals( dummySettings, adapter.getSettings() );
	}

	function test06_saveSettings_shouldSaveSettingsThroughSystemConfigurationService() output=false {
		var adapter       = _getAdapter();
		var dummySettings = { branch="stable", meh="test" };

		mockSettingsService.$( "saveSetting" ).$args( category="updatemanager", setting="branch", value="stable" ).$results( 1 );
		mockSettingsService.$( "saveSetting" ).$args( category="updatemanager", setting="meh"   , value="test"   ).$results( 1 );

		adapter.saveSettings( settings=dummySettings );

		super.assertEquals( 2, mockSettingsService.$callLog().saveSetting.len() );
	}

// PRIVATE HELPERS
	private any function _getAdapter( repositoryUrl="", presidePath="/tests/resources/updateManager" ) output=false  {
		mockSettingsService = getMockBox().createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
		adapter = new preside.system.services.updateManager.UpdateManagerService( argumentCollection=arguments, systemConfigurationService=mockSettingsService );

		return getMockBox().createMock( object=adapter );
	}
}