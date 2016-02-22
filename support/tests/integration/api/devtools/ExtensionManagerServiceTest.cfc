component output="false" extends="mxunit.framework.TestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		_resetTestResources();

		manager = new preside.system.services.devtools.ExtensionManagerService(
			extensionsDirectory = "/tests/resources/extensionManager/extensions"
		);
	}

// TESTS
	function test01_listExtensions_shouldReturnArrayOfExtensions_inPriorityOrder_withActiveAndInstalledStatus() output=false {
		var expected = [
			  { name="anotherExtension"   , priority=200, installed=true , active=false, directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="untracked"          , priority=0  , installed=true , active=false, directory="/tests/resources/extensionManager/extensions/untracked" }
		];

		super.assertEquals( expected, manager.listExtensions() );
	}

	function test02_activateExtension_shouldActivateSuppliedExtension() output=false {
		var expected = [
			  { name="anotherExtension"   , priority=200, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="untracked"          , priority=0  , installed=true , active=false, directory="/tests/resources/extensionManager/extensions/untracked" }
		];

		manager.activateExtension( "anotherExtension" );

		super.assertEquals( expected, manager.listExtensions() );
	}

	function test03_activateExtension_shouldActivateUntrackedExtension() output=false {
		var expected = [
			  { name="anotherExtension"   , priority=200, installed=true , active=false, directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="untracked"          , priority=0  , installed=true , active=true , directory="/tests/resources/extensionManager/extensions/untracked" }
		];

		manager.activateExtension( "untracked" );

		super.assertEquals( expected, manager.listExtensions() );
	}

	function test04_activateExtension_shouldThrowInformativeError_whenExtensionDoesNotExist() output=false {
		var errorThrown = false;

		try {
			manager.activateExtension( "nonExinsting" );

		} catch ( "ExtensionManager.missingExtension" e ) {
			super.assert( e.message.startsWith( "The extension, [nonExinsting], could not be found" ) );
			errorThrown=true;
		} catch ( any e ){}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test05_deactivateExtension_shouldDeactivateSuppliedExtension() output=false {
		var expected = [
			  { name="anotherExtension"   , priority=200, installed=true , active=false , directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=false , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="untracked"          , priority=0  , installed=true , active=false, directory="/tests/resources/extensionManager/extensions/untracked" }
		];

		manager.deactivateExtension( "someExtension" );

		super.assertEquals( expected, manager.listExtensions() );
	}

	function test06_deactivateExtension_shouldDeactivateUntrackedExtension() output=false {
		var expected = [
			  { name="anotherExtension"   , priority=200, installed=true , active=false, directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="untracked"          , priority=0  , installed=true , active=false , directory="/tests/resources/extensionManager/extensions/untracked" }
		];

		manager.deactivateExtension( "untracked" );

		super.assertEquals( expected, manager.listExtensions() );
	}

	function test07_deactivateExtension_shouldThrowInformativeError_whenExtensionDoesNotExist() output=false {
		var errorThrown = false;

		try {
			manager.deactivateExtension( "idonotexist" );

		} catch ( "ExtensionManager.missingExtension" e ) {
			super.assert( e.message.startsWith( "The extension, [idonotexist], could not be found" ) );
			errorThrown=true;
		} catch ( any e ){}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test08_uninstallExtension_shouldRemoveTrackingInfoAndFiles() output=false {
		DirectoryCreate( "/tests/resources/extensionManager/extensions/testExtension" );
		FileWrite( "/tests/resources/extensionManager/extensions/testExtension/manifest.json", '{ "id" : "test", "title" : "test extension", "author" : "Test author", "version" : "2.5.5524", "changelog" : "Things change man" }' );
		manager.activateExtension( "testExtension" );

		super.assertEquals([
			  { name="anotherExtension"   , priority=200, installed=true , active=false, directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="testExtension"      , priority=0  , installed=true , active=true , directory="/tests/resources/extensionManager/extensions/testExtension" }
			, { name="untracked"          , priority=0  , installed=true , active=false, directory="/tests/resources/extensionManager/extensions/untracked" }
		], manager.listExtensions() );

		manager.uninstallExtension( "testExtension" );

		super.assertEquals([
			  { name="anotherExtension"   , priority=200, installed=true , active=false, directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="untracked"          , priority=0  , installed=true , active=false, directory="/tests/resources/extensionManager/extensions/untracked" }
		], manager.listExtensions() );

		super.assertFalse( DirectoryExists( "/tests/resources/extensionManager/extensions/testExtension" ) );
	}

	function test09_getExtensionInfo_shouldReadExtensionManifestFileAndReturnExtensionDetails() output=false {
		var expected = {
			  id        = "someExtension"
			, title     = "Some extension"
			, author    = "Test author"
			, version   = "2.5.5524"
			, changelog = "Things change man"
		};

		super.assertEquals( expected, manager.getExtensionInfo( "someExtension" ) );
	}

	function test10_getExtensionInfo_shouldThrowInformativeErrorWhenExtensionIsNotInstalled() output=false {
		var errorThrown = false;

		try {
			manager.getExtensionInfo( "blah" );

		} catch ( "ExtensionManager.missingExtension" e ) {
			super.assert( e.message.startsWith( "The extension, [blah], could not be found" ) );
			errorThrown=true;
		} catch ( any e ){}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test11_getExtensionInfo_shouldThrowInformativeErrorWhenExtensionHasNoManifest() output=false {
		var errorThrown = false;
		var badManager = new preside.system.services.devtools.ExtensionManagerService(
			extensionsDirectory = "/tests/resources/extensionManager/badextensions"
		);

		try {
			badManager.getExtensionInfo( "nomanifest" );

		} catch ( "ExtensionManager.missingManifest" e ) {
			super.assertEquals( "The extension, [nomanifest], does not have a manifest file", e.message );
			errorThrown = true;
		} catch ( any e ){}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test12_getExtensionInfo_shouldReadInfoFromExtensionsThatAreNotYetInstalled() output=false {
		var expected = {
			  id        = "validExtension"
			, title     = "Valid Extension"
			, author    = "Vladimir Valid"
			, version   = "0.0.1"
			, changelog = ""
		};

		super.assertEquals( expected, manager.getExtensionInfo( "/tests/resources/extensionManager/notYetInstalledExtensions/validExtension" ) );
	}

	function test13_getExtensionInfo_shouldThrowInformativeError_whenManifestIsNotValidJson() output=false {
		var errorThrown = false;

		try {
			manager.getExtensionInfo( "/tests/resources/extensionManager/notYetInstalledExtensions/invalidJsonManifest" );

		} catch ( "ExtensionManager.invalidManifest" e ) {
			super.assertEquals( "The extension, [/tests/resources/extensionManager/notYetInstalledExtensions/invalidJsonManifest], has a manifest file with invalid json", e.message );
			errorThrown = true;
		} catch ( any e ){}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test14_getExtensionInfo_shouldThrowInformativeError_whenManifestDoesNotContainRequiredFields() output=false {
		var errorThrown = false;

		try {
			manager.getExtensionInfo( "/tests/resources/extensionManager/notYetInstalledExtensions/manifestWithMissingFields" );

		} catch ( "ExtensionManager.invalidManifest" e ) {
			super.assertEquals( "The extension, [/tests/resources/extensionManager/notYetInstalledExtensions/manifestWithMissingFields], has an invalid manifest file. Missing required fields: [id], [title], [author], [version]", e.message );
			errorThrown = true;
		} catch ( any e ){}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test15_installExtension_shouldInstallExtensionFromGivenSourcePath() output=false {
		var expected = [
			  { name="anotherExtension"   , priority=200, installed=true , active=false, directory="/tests/resources/extensionManager/extensions/anotherExtension" }
			, { name="someExtension"      , priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
			, { name="yetAnotherExtension", priority=50 , installed=false, active=false, directory="" }
			, { name="myextension"        , priority=0  , installed=true , active=false, directory="/tests/resources/extensionManager/extensions/myextension" }
			, { name="untracked"          , priority=0  , installed=true , active=false, directory="/tests/resources/extensionManager/extensions/untracked" }
		];

		manager.installExtension( "/tests/resources/extensionManager/notYetInstalledExtensions/extensionWithDiffIdFromFolder/" );

		super.assertEquals( expected, manager.listExtensions() );
	}

	function test16_installExtension_shouldThrowAnInformativeErrorWhenExtensionAlreadyExists() output=false {
		var errorThrown = false;

		try {
			manager.installExtension( "/tests/resources/extensionManager/notYetInstalledExtensions/preExistingExtension" );

		} catch ( "ExtensionManager.manifestExists" e ) {
			super.assertEquals( "The extension, [someExtension], is already installed", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test17_listExtensions_shouldOnlyReturnActiveAndInstalledExtensions_whenActiveOnlyFlagIsPassedAsTrue() output=false {
		var expected = [
			{ name="someExtension", priority=100, installed=true , active=true , directory="/tests/resources/extensionManager/extensions/someExtension" }
		];

		super.assertEquals( expected, manager.listExtensions( activeOnly=true ) );
	}


// PRIVATE HELPERS
	private void function _resetTestResources() output=false {
		FileCopy( "/tests/resources/extensionManager/extensions/extensions.json.bak", "/tests/resources/extensionManager/extensions/extensions.json" );
		var dirs         = DirectoryList( "/tests/resources/extensionManager/extensions/", false, "Query" );
		var expectedDirs = [ "anotherExtension", "someExtension", "untracked" ];

		for( var dir in dirs ){
			if ( dir.type == "Dir" && !ArrayFind( expectedDirs, dir.name ) ) {
				DirectoryDelete( "/tests/resources/extensionManager/extensions/" & dir.name, true );
			}
		}
	}
}