component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();
	}

// TESTS
	function test01_listAvailableVersions_shouldReturnVersionsOfPresideBasedOnContentsOfS3BucketForGivenCurrentBranch() output=false {
		var adapter  = _getAdapter();
		var expected = [
			  { version="0.1.1.00089", downloaded=false, path="presidecms/bleeding-edge/PresideCMS-0.1.1.zip" }
			, { version="0.1.2.00345", downloaded=false, path="presidecms/bleeding-edge/PresideCMS-0.1.2.zip" }
		];

		mockSettingsService.$( "getSetting" ).$args( category="updatemanager", setting="branch", default="release" ).$results( "bleedingEdge" );

		adapter.$( "_fetchS3BucketListing", XmlParse( "/tests/resources/updateManager/s3BucketListing.xml" ) );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.1.json" ).$results( { version:"0.1.1.00089" } );
		adapter.$( "_fetchVersionInfo" ).$args( "presidecms/bleeding-edge/PresideCMS-0.1.2.json" ).$results( { version:"0.1.2.00345" } );

		super.assertEquals( expected, adapter.listAvailableVersions() );
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

		super.assertEquals( "0.1.1.00089", adapter.getLatestVersion().version );
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

	function test07_listDownloadedVersions_shouldExamineFileSystemToDiscoverInstalledPresideVersions() output=false  {
		var adapter  = _getAdapter( presidePath="/tests/resources/updateManager/multiversions/0.1.0" );
		var expected = [
			  { version="0.1.0.049"  , path=ExpandPath( "/tests/resources/updateManager/multiversions/0.1.0"  ) }
			, { version="0.1.1.123"  , path=ExpandPath( "/tests/resources/updateManager/multiversions/0.1.1"  ) }
			, { version="0.1.10.9049", path=ExpandPath( "/tests/resources/updateManager/multiversions/0.1.10" ) }
			, { version="0.2.0.2570" , path=ExpandPath( "/tests/resources/updateManager/multiversions/0.2.0"  ) }
		];

		super.assertEquals( expected, adapter.listDownloadedVersions() );
	}

	function test08_versionIsDownloaded_shouldReturnFalse_whenVersionIsNotLocallyDownloaded() output=false {
	}

	function test09_versionIsDownloaded_shouldReturnTrue_whenVersionIsLocallyDownloaded() output=false {
		var adapter = _getAdapter( presidePath="/tests/resources/updateManager/multiversions/0.1.0" );

		super.assert( adapter.versionIsDownloaded( "0.1.10.9049" ) );
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
	private any function _getAdapter( repositoryUrl="", presidePath="/tests/resources/updateManager" ) output=false  {
		var cacheBox = _getCachebox( forceNewInstance=true );

		mockSettingsService = getMockBox().createEmptyMock( "preside.system.services.configuration.SystemConfigurationService" );
		mockApplicationReloadService = getMockBox().createEmptyMock( "preside.system.services.devtools.ApplicationReloadService" );
		adapter = new preside.system.services.updateManager.UpdateManagerService(
			  argumentCollection         = arguments
			, systemConfigurationService = mockSettingsService
			, applicationReloadService   = mockApplicationReloadService
			, lookupCache                = cachebox.getCache( "DefaultQueryCache" )
		);

		return getMockBox().createMock( object=adapter );
	}
}