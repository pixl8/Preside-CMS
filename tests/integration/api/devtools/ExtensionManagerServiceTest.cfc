component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "listExtensions()", function(){
			it( "should return an array of structs of extensions in dependency order based on auto discovery within directories", function(){
				_setup();

				var extensions = manager.listExtensions();
				var basePath   = "/tests/resources/extensionManager/application";

				expect( extensions ).toBe( [ {
					  id        = "anotherExtension"
					, name      = "anotherExtension"
					, title     = "Another extension"
					, author    = "Test author"
					, version   = "2.5.5524"
					, changelog = "Things change man"
					, directory = "#basePath#/extensions/anotherExtension"
					, dependsOn	= []
				}, {
					  id        = "someExtension"
					, name      = "someExtension"
					, title     = "Some extension"
					, author    = "Test author"
					, version   = "2.5.5524"
					, changelog = "Things change man"
					, dependson = [ "anotherExtension", "moduleExtension" ]
					, directory = "#basePath#/extensions/someExtension"
				} ] );
			} );

			it( "should exclude any extensions that it has been told to ignore", function(){
				_setup( [ "anotherExtension" ] );

				var extensions = manager.listExtensions();
				var basePath   = "/tests/resources/extensionManager/application";

				expect( extensions ).toBe( [ {
					  id        = "someExtension"
					, name      = "someExtension"
					, title     = "Some extension"
					, author    = "Test author"
					, version   = "2.5.5524"
					, changelog = "Things change man"
					, dependson = [ "anotherExtension", "moduleExtension" ]
					, directory = "#basePath#/extensions/someExtension"
				} ] );
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