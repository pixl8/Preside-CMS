component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "listExtensions()", function(){
			it( "should return an array of structs of extensions in dependency order based on auto discovery within directories", function(){
				_setup();

				var extensions  = manager.listExtensions();
				var basePath    = "/tests/resources/extensionManager/application";
				var baseMapping = "tests.resources.extensionManager.application";
				expect( extensions ).toBe( [ {
					  id            = "anotherExtension"
					, name          = "anotherExtension"
					, title         = "Another extension"
					, author        = "Test author"
					, version       = "2.5.5524"
					, directory     = "#basePath#/extensions/anotherExtension"
					, componentPath = "#baseMapping#.extensions.anotherExtension"
					, dependsOn	    = []
					, isAppLocal    = false
				}, {
					  id            = "someExtension"
					, name          = "someExtension"
					, title         = "Some extension"
					, author        = "Test author"
					, version       = "2.5.5524"
					, dependson     = [ "anotherExtension", "moduleExtension" ]
					, directory     = "#basePath#/extensions/someExtension"
					, componentPath = "#baseMapping#.extensions.someExtension"
					, isAppLocal    = false
				}, {
					  id            = "aardvark-ext"
					, name          = "aardvark-ext"
					, title         = "Aardvark extension"
					, author        = "Test author"
					, version       = "1.0.0"
					, directory     = "#basePath#/extensions_app/aardvark-ext"
					, componentPath = "#baseMapping#.extensions_app.aardvark-ext"
					, dependsOn	    = []
					, isAppLocal    = true
				} ] );
			} );

			it( "should exclude any extensions that it has been told to ignore", function(){
				_setup( [ "anotherExtension", "aardvark-ext" ] );

				var extensions  = manager.listExtensions();
				var basePath    = "/tests/resources/extensionManager/application";
				var baseMapping = "tests.resources.extensionManager.application";

				expect( extensions ).toBe( [ {
					  id            = "someExtension"
					, name          = "someExtension"
					, title         = "Some extension"
					, author        = "Test author"
					, version       = "2.5.5524"
					, dependson     = [ "anotherExtension", "moduleExtension" ]
					, directory     = "#basePath#/extensions/someExtension"
					, componentPath = "#baseMapping#.extensions.someExtension"
					, isAppLocal    = false
				} ] );
			} );
		} );

		describe( "extensionExists()", function(){
			it( "should return true when the extension exists", function() {
				_setup();
				expect( manager.extensionExists( "aardvark-ext" ) ).toBeTrue();
			} );
			it( "should return false when the extension does not exist", function() {
				_setup();
				expect( manager.extensionExists( "idonotexist" ) ).toBeFalse();
			} );
		} );

		describe( "getExtension()", function(){
			it( "should return an empty struct when the extension does not exist", function() {
				_setup();
				expect( manager.getExtension( "blah" ) ).toBe( {} );
			} );

			it( "should return the details of the given extension", function() {
				_setup();
				var basePath   = "/tests/resources/extensionManager/application";
				var baseMapping = "tests.resources.extensionManager.application";
				expect( manager.getExtension( "anotherExtension" ) ).toBe( {
					  id            = "anotherExtension"
					, name          = "anotherExtension"
					, title         = "Another extension"
					, author        = "Test author"
					, version       = "2.5.5524"
					, directory     = "#basePath#/extensions/anotherExtension"
					, componentPath = "#baseMapping#.extensions.anotherExtension"
					, dependsOn	    = []
					, isAppLocal    = false
				} );
			} );
		} );

		describe( "getExtensionDirectory()", function(){
			it( "should return an empty string when the extension does not exist", function() {
				_setup();
				expect( manager.getExtensionDirectory( "blah" ) ).toBe( "" );
			} );

			it( "should return the physical directory of the extensions", function() {
				_setup();
				var basePath   = "/tests/resources/extensionManager/application";
				expect( manager.getExtensionDirectory( "aardvark-ext" ) ).toBe( "#basePath#/extensions_app/aardvark-ext" );
				expect( manager.getExtensionDirectory( "anotherExtension" ) ).toBe( "#basePath#/extensions/anotherExtension" );
			} );
		} );

		describe( "getExtensionComponentPath()", function(){
			it( "should return an empty string when the extension does not exist", function() {
				_setup();
				expect( manager.getExtensionComponentPath( "blah" ) ).toBe( "" );
			} );

			it( "should return the physical directory of the extensions", function() {
				_setup();
				var baseMapping = "tests.resources.extensionManager.application";
				expect( manager.getExtensionComponentPath( "aardvark-ext" ) ).toBe( "#baseMapping#.extensions_app.aardvark-ext" );
				expect( manager.getExtensionComponentPath( "anotherExtension" ) ).toBe( "#baseMapping#.extensions.anotherExtension" );
			} );
		} );

		describe( "isAppExtension()", function(){
			it( "should return false when the extension does not exist", function() {
				_setup();
				expect( manager.isAppExtension( "blah" ) ).toBeFalse();
			} );

			it( "should return whether or not the extension is an 'app' extension", function() {
				_setup();
				expect( manager.isAppExtension( "aardvark-ext" ) ).toBeTrue();
				expect( manager.isAppExtension( "anotherExtension" ) ).toBeFalse();
			} );
		} );

		describe( "getExtensionInfo()", function(){
			beforeEach( function() { _setup(); } );

			it( "should should throw a 'no longer supported' error", function(){
				expect( function(){
					manager.getExtensionInfo( "whatever" );
				} ).toThrow( "method.no.longer.supported" );
			} );
		} );

		describe( "activateExtension()", function(){
			beforeEach( function() { _setup(); } );

			it( "should should throw a 'no longer supported' error", function(){
				expect( function(){
					manager.activateExtension( "whatever" );
				} ).toThrow( "method.no.longer.supported" );
			} );
		} );

		describe( "deactivateExtension()", function(){
			beforeEach( function() { _setup(); } );

			it( "should should throw a 'no longer supported' error", function(){
				expect( function(){
					manager.deactivateExtension( "whatever" );
				} ).toThrow( "method.no.longer.supported" );
			} );
		} );

		describe( "uninstallExtension()", function(){
			beforeEach( function() { _setup(); } );

			it( "should should throw a 'no longer supported' error", function(){
				expect( function(){
					manager.uninstallExtension( "whatever" );
				} ).toThrow( "method.no.longer.supported" );
			} );
		} );

		describe( "installExtension()", function(){
			beforeEach( function() { _setup(); } );

			it( "should should throw a 'no longer supported' error", function(){
				expect( function(){
					manager.installExtension( "whatever" );
				} ).toThrow( "method.no.longer.supported" );
			} );
		} );

	}

// private helpers
	private void function _setup( array ignore=[] ) {
		StructDelete( application, "__presideappExtensions" );
		manager = new preside.system.services.devtools.ExtensionManagerService(
			  appMapping       = "/tests/resources/extensionManager/application"
			, ignoreExtensions = arguments.ignore
		);
	}
	private void function _resetTestResources() {
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