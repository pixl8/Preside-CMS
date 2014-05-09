component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP & TEARDOWN
	function teardown() output=false {
		if ( Len( Trim( tmpDir ?: "" ) ) and DirectoryExists( tmpDir ) ) {
			DirectoryDelete( tmpDir, true );
		}

		if ( Len( Trim( tmpFile ?: "" ) ) and FileExists( tmpFile ) ) {
			FileDelete( tmpFile );
			tmpFile = "";
		}
	};

// TESTS
	function test01_objectExists_shouldReturnFalse_whenFileDoesNotExistInSpecifiedLocation() output=false {
		var provider = _getStorageProvider();

		super.assertFalse( provider.objectExists( path="/some/obj/that/does/not/exist" ) );
	}

	function test02_objectExists_shouldReturnTrue_whenFileDoesExistInTheSpecifiedLocation() output=false {
		var provider = _getStorageProvider();

		super.assert( provider.objectExists( path="/testFile.txt" ) );
	}

	function test03_objectExists_shouldReturnTrue_whenFileDoesExistInTheSpecifiedLocationAndPathsAreMissingTrailingAndLeadingSlashes() output=false {
		var provider = _getStorageProvider( "/tests/resources/fileStorage/storage" );

		super.assert( provider.objectExists( path="testFile.txt" ) );
	}

	function test04_getObject_shouldReturnBinaryOfSuppliedObject() output=false {
		var provider     = _getStorageProvider();
		var relativePath = "/testDir/loading.gif";
		var fullPath     = "/tests/resources/fileStorage/storage/testDir/loading.gif";
		var binary       = FileReadBinary( fullPath );
		var result       = provider.getObject( path=relativePath );

		super.assertEquals( ToBase64( binary ), ToBase64( result ) );
	}

	function test05_getObject_shouldThrowInformativeError_whenObjectDoesNotExist() output=false {
		var provider    = _getStorageProvider();
		var errorThrown = false;

		try {
			provider.getObject( path="/some/nonexistant/file.wmv" );
		} catch( "storageProvider.objectNotFound" e ) {
			super.assertEquals( "The object, [/some/nonexistant/file.wmv], could not be found or is not accessible", e.message );
			errorThrown = true;
		} catch ( any e ) {}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test06_putObject_shouldStoreAnObjectInTheStore() output=false {
		var provider          = _getStorageProvider();
		var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
		var pathToStoreItAt   = CreateUUId() & ".gif";
		var fileReadFromStore = "";

		tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

		provider.putObject( object=fileToStore, path=pathToStoreItAt );
		fileReadFromStore = provider.getObject( path=pathToStoreItAt );

		super.assertEquals( ToBase64( fileToStore ), ToBase64( fileReadFromStore ) );
	}

	function test07_putObject_shouldCreateSpecifiedSubDirectories_whenTheyDoNotAlreadyExist() output=false {
		var provider          = _getStorageProvider();
		var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
		var pathToStoreItAt   = "/tmptest/another/dir/that/does/not/exist/" & CreateUUId() & ".gif";
		var fileReadFromStore = "";

		tmpDir = "/tests/resources/fileStorage/storage/tmptest/"; // this will get cleaned up by the teardown() function

		provider.putObject( object=fileToStore, path=pathToStoreItAt );
		fileReadFromStore = provider.getObject( path=pathToStoreItAt );

		super.assertEquals( ToBase64( fileToStore ), ToBase64( fileReadFromStore ) );
	}

	function test08_putObject_shouldOverwriteObject_whenItAlreadyExists() output=false {
		var provider            = _getStorageProvider();
		var originalFileToStore = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
		var secondFileToStore   = FileReadBinary( "/tests/resources/fileStorage/storage/testfile.txt" );
		var pathToStoreItAt     = CreateUUId() & ".gif";
		var fileReadFromStore   = "";

		tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

		provider.putObject( object=originalFileToStore, path=pathToStoreItAt );
		fileReadFromStore = provider.getObject( path=pathToStoreItAt );
		super.assertEquals( ToBase64( originalFileToStore ), ToBase64( fileReadFromStore ) );

		provider.putObject( object=secondFileToStore, path=pathToStoreItAt );
		fileReadFromStore = provider.getObject( path=pathToStoreItAt );
		super.assertEquals( ToBase64( secondFileToStore ), ToBase64( fileReadFromStore ) );
	}

	function test09_deleteObject_shouldRemoveAnObjectFromTheStore() output=false {
		var provider          = _getStorageProvider();
		var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
		var pathToStoreItAt   = CreateUUId() & ".gif";

		tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

		provider.putObject( object=fileToStore, path=pathToStoreItAt );
		super.assert( provider.objectExists( pathToStoreItAt ) );

		provider.deleteObject( path=pathToStoreItAt );
		super.assertFalse( provider.objectExists( pathToStoreItAt ) );
	}

	function test10_deleteObject_shouldSilentlyDoNothing_whenObjectDoesNotExist() output=false {
		var provider        = _getStorageProvider();
		var nonExistantPath = "/i/do/not/exist/reallyIDoNot.doc";

		provider.deleteObject( path=nonExistantPath );
		super.assertFalse( provider.objectExists( nonExistantPath ) );
	}

	function test11_getObjectUrl_shouldReturnUrl_relativeToConfiguredBaseUrl() output=false {
		var provider    = _getStorageProvider( rootUrl="http://uploads.mysite.com/" );
		var path        = "/some/file.jpg";
		var expectedUrl = "http://uploads.mysite.com" & path;

		super.assertEquals( expectedUrl, provider.getObjectUrl( path=path ) );
	}

	function test12_putObject_shouldStoreAnObjectInTheStore_whenObjectPassedAsFilePath() output=false {
		var provider          = _getStorageProvider();
		var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
		var pathToStoreItAt   = CreateUUId() & ".gif";
		var fileReadFromStore = "";

		tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

		provider.putObject( object="/tests/resources/fileStorage/storage/testDir/loading.gif", path=pathToStoreItAt );
		fileReadFromStore = provider.getObject( path=pathToStoreItAt );

		super.assertEquals( ToBase64( fileToStore ), ToBase64( fileReadFromStore ) );
	}

	function test13_putObject_shouldThrowInformativeError_whenObjectIsNeitherABinaryVariableOrSimpleValue() output=false {
		var provider    = _getStorageProvider();
		var errorThrown = false;
		var badObject   = { some="structure" };

		try {
			provider.putObject( badObject, "/some/path/to/file.pdf" );
		} catch ( "StorageProvider.invalidObject" e ) {
			super.assertEquals( "The object argument passed to the putObject() method is invalid. Expected either a binary file object or valid file path but received [#SerializeJson( badObject )#]", e.message );
			errorThrown = true;
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test14_getObjectInfo_shouldReturnFileSizeAndLastModifiedDateForGivenFile() output=false {
		var provider     = _getStorageProvider();
		var expectedSize = 9427;
		var result       = provider.getObjectInfo( path="/testdir/loading.gif" );

		super.assertEquals( expectedSize, result.size );
		super.assert( IsDate( result.lastmodified ) );
	}

	function test15_getObjectInfo_shouldThrowSuitableError_whenObjectDoesNotExistAtProvidedPath() output=false {
		var provider    = _getStorageProvider();
		var errorThrown = false;

		try {
			provider.getObjectInfo( path="/some/nonexistant/file.wmv" );
		} catch( "storageProvider.objectNotFound" e ) {
			super.assertEquals( "The object, [/some/nonexistant/file.wmv], could not be found or is not accessible", e.message );
			errorThrown = true;
		} catch ( any e ) {}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test16_listObjects_shouldReturnQueryOfObjectsInAGivenPath() output=false {
		var provider = _getStorageProvider();
		var actual   = provider.listObjects( "testdir/" );
		var expected = [
			  { name="another.txt", path="/testdir/another.txt", size=0, lastmodified="2014-03-17 09:56:11" }
			, { name="file.txt"   , path="/testdir/file.txt"   , size=0, lastmodified="2014-03-17 09:56:19" }
			, { name="loading.gif", path="/testdir/loading.gif", size=9427, lastmodified="2013-07-30 16:11:08" }
		]

		super.assertEquals( expected.len(), actual.recordCount );

		for( var record in actual ) {
			super.assert( expected.find( function( item ){
				return item.name == record.name;
			} ) );
		}
	}

	function test17_softDeleteObject_shouldSendObjectToRecycleStorage() output=false {
		var provider          = _getStorageProvider();
		var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
		var pathToStoreItAt   = CreateUUId() & ".gif";
		var trashedPath       = "";
		var fileReadFromStore = "";


		// setup a file to test with
		provider.putObject( object=fileToStore, path=pathToStoreItAt );
		fileReadFromStore = provider.getObject( path=pathToStoreItAt );
		super.assertEquals( ToBase64( fileToStore ), ToBase64( fileReadFromStore ) );

		// do the trashing
		trashedPath = provider.softDeleteObject( path=pathToStoreItAt );
		tmpFile = "/tests/resources/fileStorage/.trash/" & trashedPath; // this will get cleaned up by the teardown() function

		super.assertFalse( provider.objectExists( path=pathToStoreItAt ) );
		super.assert( FileExists( tmpFile ) );
	}

	function test18_restoreObject_shouldMoveObjectFromRecycleBinToPermanentStorage() output=false {
		var provider          = _getStorageProvider();
		var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
		var pathToStoreItAt   = CreateUUId() & ".gif";
		var trashedPath       = "";
		var fileReadFromStore = "";

		// setup a file to test with
		provider.putObject( object=fileToStore, path=pathToStoreItAt );
		fileReadFromStore = provider.getObject( path=pathToStoreItAt );
		super.assertEquals( ToBase64( fileToStore ), ToBase64( fileReadFromStore ) );

		// do the trashing
		trashedPath = provider.softDeleteObject( path=pathToStoreItAt );
		tmpFile = "/tests/resources/fileStorage/.trash/" & trashedPath;

		super.assertFalse( provider.objectExists( path=pathToStoreItAt ) );
		super.assert( FileExists( tmpFile ) );

		// do the restoring
		super.assert( provider.restoreObject( trashedPath, pathToStoreItAt ) );

		super.assert( provider.objectExists( path=pathToStoreItAt ) );
		super.assertFalse( FileExists( tmpFile ) );

		tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function
	}

// PRIVATE HELPERS

	private any function _getStorageProvider( string rootDirectory="/tests/resources/fileStorage/storage/", string trashDirectory="/tests/resources/fileStorage/.trash/", string rootUrl="/" ) output=false {
		return new preside.system.api.fileStorage.FileSystemStorageProvider(
			  rootDirectory  = arguments.rootDirectory
			, trashDirectory = arguments.trashDirectory
			, rootUrl        = arguments.rootUrl
		);
	}

}