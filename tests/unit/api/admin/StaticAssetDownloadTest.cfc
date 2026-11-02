component extends="testbox.system.BaseSpec" {

	function run() {

		describe( "_fileExists()", function(){

			it( "should allow files in the core static assets directory", function(){
				var handler = _getHandler( "resources/testSite" );
				var asset   = ExpandPath( "/preside/system/assets/css/admin/core/core.less" );

				expect( handler._fileExists( asset ) ).toBeTrue();
			} );

			it( "should allow files in a standard extension assets directory", function(){
				var handler = _getHandler( "resources/extensionManager/application" );
				var asset   = ExpandPath( "/resources/extensionManager/application/extensions/someExtension/assets/test.css" );

				expect( handler._fileExists( asset ) ).toBeTrue();
			} );

			it( "should reject source files in a standard extension", function(){
				var handler = _getHandler( "resources/extensionManager/application" );
				var source  = ExpandPath( "/resources/extensionManager/application/extensions/someExtension/manifest.json" );

				expect( handler._fileExists( source ) ).toBeFalse();
			} );

			it( "should reject source files in an app extension", function(){
				var handler = _getHandler( "resources/extensionManager/application" );
				var source  = ExpandPath( "/resources/extensionManager/application/extensions_app/aardvark-ext/manifest.json" );

				expect( handler._fileExists( source ) ).toBeFalse();
			} );

			it( "should reject files outside the permitted directories", function(){
				var handler = _getHandler( "resources/testSite" );
				var source  = ExpandPath( "/resources/testSite/config/Config.cfc" );

				expect( handler._fileExists( source ) ).toBeFalse();
			} );

			it( "should reject paths that escape the core static assets directory", function(){
				var handler = _getHandler( "resources/testSite" );
				var source  = ExpandPath( "/preside/system/assets/../handlers/admin/StaticAssetDownload.cfc" );

				expect( handler._fileExists( source ) ).toBeFalse();
			} );

		} );

	}

// PRIVATE HELPERS
	private any function _getHandler( required string appMapping ) {
		var handler = createMock( "preside.system.handlers.admin.StaticAssetDownload" );

		handler.$property( propertyName="appMapping", mock=arguments.appMapping );
		makePublic( handler, "_fileExists" );

		return handler;
	}

}
