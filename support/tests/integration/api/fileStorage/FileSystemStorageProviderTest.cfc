component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function afterAll() {
		_cleanup();
	}

	function run(){
		describe( "objectExists()", function(){

			it( "should return false when file does not exist in specified location", function(){
				var provider = _getStorageProvider();

				expect( provider.objectExists( path="/some/obj/that/does/not/exist" ) ).toBeFalse();
			} );

			it( "should return true when file does exist in the specified location", function(){
				var provider = _getStorageProvider();

				expect( provider.objectExists( path="/testFile.txt" ) ).toBeTrue();
			} );

			it( "should return true when file does exist in the specified location and paths are missing trailing and leading slashes", function(){
				var provider = _getStorageProvider( "/tests/resources/fileStorage/storage" );

				expect( provider.objectExists( path="testFile.txt" ) ).toBeTrue();
			} );

			it( "should return false when file only exists in public storage and private=true passed", function(){
				var provider = _getStorageProvider();

				expect( provider.objectExists( path="/testFile.txt", private=true ) ).toBeFalse();
			} );

			it( "should return true when file only exists in private storage and private=true passed", function(){
				var provider = _getStorageProvider();

				expect( provider.objectExists( path="/private.txt", private=true ) ).toBeTrue();
			} );

		} );

		describe( "getObject()", function(){

			it( "should return binary of object stored at provided path", function(){
				var provider     = _getStorageProvider();
				var relativePath = "/testDir/loading.gif";
				var fullPath     = "/tests/resources/fileStorage/storage/testDir/loading.gif";
				var binary       = FileReadBinary( fullPath );
				var result       = provider.getObject( path=relativePath );

				expect( ToBase64( result ) ).toBe( ToBase64( binary ) );
			} );

			it( "should throw informative error when object does not exist", function(){
				var provider    = _getStorageProvider();
				var errorThrown = false;

				try {
					provider.getObject( path="/some/nonexistant/file.wmv" );
				} catch( "storageProvider.objectNotFound" e ) {
					expect( e.message ).toBe( "The object, [/some/nonexistant/file.wmv], could not be found or is not accessible" );
					errorThrown = true;
				} catch ( any e ) {}

				expect( errorThrown ).toBeTrue();
			} );

			it( "should return binary of object stored at provided private path", function(){
				var provider     = _getStorageProvider();
				var relativePath = "/private.txt";
				var fullPath     = "/tests/resources/fileStorage/private/private.txt";
				var binary       = FileReadBinary( fullPath );
				var result       = provider.getObject( path=relativePath, private=true );

				expect( ToBase64( result ) ).toBe( ToBase64( binary ) );
			} );

			it( "should throw informative error when object only exists in public store and private store requested", function(){
				var provider    = _getStorageProvider();
				var errorThrown = false;

				try {
					provider.getObject( path="/testDir/loading.gif", private=true );
				} catch( "storageProvider.objectNotFound" e ) {
					expect( e.message ).toBe( "The object, [/testDir/loading.gif], could not be found or is not accessible" );
					errorThrown = true;
				} catch ( any e ) {}

				expect( errorThrown ).toBeTrue();
			} );

		} );

		describe( "putObject()", function(){

			it( "should store an object in the store", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";
				var fileReadFromStore = "";

				tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

				provider.putObject( object=fileToStore, path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );

				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );
			} );

			it( "should create specified sub directories when they do not already exist", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = "/tmptest/another/dir/that/does/not/exist/" & CreateUUId() & ".gif";
				var fileReadFromStore = "";

				tmpDir = "/tests/resources/fileStorage/storage/tmptest/"; // this will get cleaned up by the teardown() function

				provider.putObject( object=fileToStore, path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );

				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );
			} );

			it( "should overwrite object when it already exists", function(){
				var provider            = _getStorageProvider();
				var originalFileToStore = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var secondFileToStore   = FileReadBinary( "/tests/resources/fileStorage/storage/testfile.txt" );
				var pathToStoreItAt     = CreateUUId() & ".gif";
				var fileReadFromStore   = "";

				tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

				provider.putObject( object=originalFileToStore, path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );
				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( originalFileToStore ) );

				provider.putObject( object=secondFileToStore, path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );
				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( secondFileToStore ) );
			} );

			it( "should store an object in the store when object passed as file path", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";
				var fileReadFromStore = "";

				tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

				provider.putObject( object="/tests/resources/fileStorage/storage/testDir/loading.gif", path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );

				expect( ToBase64( fileReadFromStore ), ToBase64( fileToStore ) );
			} );

			it( "should throw informative error when object is neither a binary variable or simple value", function(){
				var provider    = _getStorageProvider();
				var errorThrown = false;
				var badObject   = { some="structure" };

				try {
					provider.putObject( badObject, "/some/path/to/file.pdf" );
				} catch ( "StorageProvider.invalidObject" e ) {
					expect( e.message ).toBe( "The object argument passed to the putObject() method is invalid. Expected either a binary file object or valid file path but received [#SerializeJson( badObject )#]" );
					errorThrown = true;
				}

				expect( errorThrown ).toBe( true );
			} );

			it( "should be able to create file in private store", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = "/tmptest/another/dir/that/does/not/exist/" & CreateUUId() & ".gif";
				var fileReadFromStore = "";

				tmpDir = "/tests/resources/fileStorage/private/tmptest/"; // this will get cleaned up by the teardown() function

				provider.putObject( object=fileToStore, path=pathToStoreItAt, private=true );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt, private=true );

				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );
			} );

		} );

		describe( "deleteObject()", function(){

			it( "should remove an object from the store", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";

				tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

				provider.putObject( object=fileToStore, path=pathToStoreItAt );
				expect( provider.objectExists( pathToStoreItAt ) ).toBeTrue();

				provider.deleteObject( path=pathToStoreItAt );
				expect( provider.objectExists( pathToStoreItAt ) ).toBeFalse();
			} );

			it( "should silently do nothing when object does not exist", function(){
				var provider        = _getStorageProvider();
				var nonExistantPath = "/i/do/not/exist/reallyIDoNot.doc";

				provider.deleteObject( path=nonExistantPath );
				expect( provider.objectExists( nonExistantPath ) ).toBeFalse();
			} );

			it( "should delete an object from the private store", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";

				tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function

				provider.putObject( object=fileToStore, path=pathToStoreItAt, private=true );
				expect( provider.objectExists( path=pathToStoreItAt, private=true ) ).toBeTrue();

				provider.deleteObject( path=pathToStoreItAt, private=true );
				expect( provider.objectExists( path=pathToStoreItAt, private=true ) ).toBeFalse();
			} );

		} );

		describe( "getObjectUrl()", function(){

			it( "should return url relative to configured base url", function(){
				var provider    = _getStorageProvider( rootUrl="http://uploads.mysite.com/" );
				var path        = "/some/file.jpg";
				var expectedUrl = "http://uploads.mysite.com" & path;

				expect( provider.getObjectUrl( path=path ) ).toBe( expectedUrl );
			} );

			it( "should return empty URL when storage provider has no configured public URL", function(){
				var provider    = _getStorageProvider( rootUrl="" );
				var path        = "/some/file.jpg";
				var expectedUrl = "http://uploads.mysite.com" & path;

				expect( provider.getObjectUrl( path=path ) ).toBe( "" );
			} );

		} );

		describe( "getObjectInfo()", function(){

			it( "should return file size and last modified date for given file", function(){
				var provider     = _getStorageProvider();
				var expectedSize = 9427;
				var result       = provider.getObjectInfo( path="/testdir/loading.gif" );

				expect( result.size ).toBe( expectedSize );
				expect( IsDate( result.lastmodified ) ).toBeTrue();
			} );

			it( "should throw suitable error when object does not exist at provided path", function(){
				var provider    = _getStorageProvider();
				var errorThrown = false;

				try {
					provider.getObjectInfo( path="/some/nonexistant/file.wmv" );
				} catch( "storageProvider.objectNotFound" e ) {
					expect( e.message ).toBe( "The object, [/some/nonexistant/file.wmv], could not be found or is not accessible" );
					errorThrown = true;
				} catch ( any e ) {}

				expect( errorThrown ).toBeTrue();
			} );

			it( "should return file size and last modified date for given private file", function(){
				var provider     = _getStorageProvider();
				var expectedSize = 17;
				var result       = provider.getObjectInfo( path="/private.txt", private=true );

				expect( result.size ).toBe( expectedSize );
				expect( IsDate( result.lastmodified ) ).toBeTrue();
			} );

		} );

		describe( "listObjects()", function(){

			it( "should return query of objects in a given path", function(){
				var provider = _getStorageProvider();
				var actual   = provider.listObjects( "testdir/" );
				var expected = [
					  { name="another.txt", path="/testdir/another.txt", size=0, lastmodified="2014-03-17 09:56:11" }
					, { name="file.txt"   , path="/testdir/file.txt"   , size=0, lastmodified="2014-03-17 09:56:19" }
					, { name="loading.gif", path="/testdir/loading.gif", size=9427, lastmodified="2013-07-30 16:11:08" }
				]

				expect( actual.recordCount ).toBe( expected.len() );

				for( var record in actual ) {
					expect( expected.find( function( item ){
						return item.name == record.name;
					} ) ).toBeTrue();
				}
			} );

			it( "should return query of objects in a given private path", function(){
				var provider = _getStorageProvider();
				var actual   = provider.listObjects( path="/", private=true );
				var expected = [
					  { name="private.txt", path="/private.txt", size=17, lastmodified="2014-03-17 09:56:11" }
				];

				expect( actual.recordCount ).toBe( expected.len() );

				for( var record in actual ) {
					expect( expected.find( function( item ){
						return item.name == record.name;
					} ) ).toBeTrue();
				}
			} );

		} );

		describe( "softDeleteObject()", function(){

			it( "should send object to recycle storage", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";
				var trashedPath       = "";
				var fileReadFromStore = "";


				// setup a file to test with
				provider.putObject( object=fileToStore, path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );
				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );

				// do the trashing
				trashedPath = provider.softDeleteObject( path=pathToStoreItAt );
				tmpFile = "/tests/resources/fileStorage/.trash/" & trashedPath; // this will get cleaned up by the teardown() function

				expect( provider.objectExists( path=pathToStoreItAt ) ).toBeFalse();
				expect( FileExists( tmpFile ) ).toBeTrue();
			} );

			it( "should send private object to recycle storage", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";
				var trashedPath       = "";
				var fileReadFromStore = "";


				// setup a file to test with
				provider.putObject( object=fileToStore, path=pathToStoreItAt, private=true );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt, private=true );
				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );

				// do the trashing
				trashedPath = provider.softDeleteObject( path=pathToStoreItAt, private=true );
				tmpFile = "/tests/resources/fileStorage/.trash/" & trashedPath; // this will get cleaned up by the teardown() function

				expect( provider.objectExists( path=pathToStoreItAt, private=true ) ).toBeFalse();
				expect( FileExists( tmpFile ) ).toBeTrue();
			} );

		} );

		describe( "restoreObject", function(){

			it( "should move object from recycle bin to permanent storage", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";
				var trashedPath       = "";
				var fileReadFromStore = "";

				// setup a file to test with
				provider.putObject( object=fileToStore, path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );
				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );

				// do the trashing
				trashedPath = provider.softDeleteObject( path=pathToStoreItAt );
				tmpFile = "/tests/resources/fileStorage/.trash/" & trashedPath;

				expect( provider.objectExists( path=pathToStoreItAt ) ).toBeFalse();
				expect( FileExists( tmpFile ) ).toBeTrue();

				// do the restoring
				expect( provider.restoreObject( trashedPath, pathToStoreItAt ) ).toBeTrue();

				expect( provider.objectExists( path=pathToStoreItAt ) ).toBeTrue;
				expect( FileExists( tmpFile ) ).toBeFalse();

				tmpFile = "/tests/resources/fileStorage/storage/" & pathToStoreItAt; // this will get cleaned up by the teardown() function
			} );

			it( "should move object from recycle bin to private storage", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";
				var trashedPath       = "";
				var fileReadFromStore = "";

				// setup a file to test with
				provider.putObject( object=fileToStore, path=pathToStoreItAt );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt );
				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );

				// do the trashing
				trashedPath = provider.softDeleteObject( path=pathToStoreItAt );
				tmpFile = "/tests/resources/fileStorage/.trash/" & trashedPath;

				expect( provider.objectExists( path=pathToStoreItAt ) ).toBeFalse();
				expect( FileExists( tmpFile ) ).toBeTrue();

				// do the restoring
				expect( provider.restoreObject( trashedPath=trashedPath, newPath=pathToStoreItAt, private=true ) ).toBeTrue();

				expect( provider.objectExists( path=pathToStoreItAt, private=true ) ).toBeTrue;
				expect( FileExists( tmpFile ) ).toBeFalse();

				tmpFile = "/tests/resources/fileStorage/private/" & pathToStoreItAt; // this will get cleaned up by the teardown() function
			} );

		} );

		describe( "moveObject", function(){

			it( "should move objects between private and public stores", function(){
				var provider          = _getStorageProvider();
				var fileToStore       = FileReadBinary( "/tests/resources/fileStorage/storage/testDir/loading.gif" );
				var pathToStoreItAt   = CreateUUId() & ".gif";
				var fileReadFromStore = "";

				// setup a file to test with
				provider.putObject( object=fileToStore, path=pathToStoreItAt, private=false );
				fileReadFromStore = provider.getObject( path=pathToStoreItAt, private=false );
				expect( ToBase64( fileReadFromStore ) ).toBe( ToBase64( fileToStore ) );

				// do the moving
				trashedPath = provider.moveObject( originalPath=pathToStoreItAt, originalIsPrivate=false, newPath=pathToStoreItAt, newIsPrivate=true );
				tmpFile = "/tests/resources/fileStorage/private/" & pathToStoreItAt;

				expect( provider.objectExists( path=pathToStoreItAt, private=false ) ).toBeFalse();
				expect( provider.objectExists( path=pathToStoreItAt, private=true ) ).toBeTrue();
				expect( FileExists( tmpFile ) ).toBeTrue();
			} );

		} );
	}


	private any function _getStorageProvider(
		    string rootDirectory    = "/tests/resources/fileStorage/storage/"
		  , string trashDirectory   = "/tests/resources/fileStorage/.trash/"
		  , string privateDirectory = "/tests/resources/fileStorage/private/"
		  , string rootUrl          = "/"
	) {
		_cleanup();

		return new preside.system.services.fileStorage.FileSystemStorageProvider(
			  rootDirectory    = arguments.rootDirectory
			, trashDirectory   = arguments.trashDirectory
			, privateDirectory = arguments.privateDirectory
			, rootUrl          = arguments.rootUrl
		);
	}

	private void function _cleanup() {
		if ( Len( Trim( tmpDir ?: "" ) ) and DirectoryExists( tmpDir ) ) {
			DirectoryDelete( tmpDir, true );
		}

		if ( Len( Trim( tmpFile ?: "" ) ) and FileExists( tmpFile ) ) {
			FileDelete( tmpFile );
			tmpFile = "";
		}
	}
}