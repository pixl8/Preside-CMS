component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){}

	// executes after all suites+specs in the run() method
	function afterAll(){}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "listProviders", function(){
			it( "should return an array of configured provider ids", function(){
				var service   = _getService();
				var providers = service.listProviders();

				providers.sort( "textnocase" );

				expect( providers ).toBe( [ "file", "s3" ] );

			} );
		} );

		describe( "getProvider", function(){
			it( "should return an instance of the configured class for the given provider", function(){
				var service      = _getService();
				var mockProvider = getMockBox().createStub();

				mockProvider.id = CreateUUId();

				service.$( "_createObject" ).$args( cfcPath="preside.system.fileStorage.S3StorageProvider" ).$results( mockProvider );

				expect( service.getProvider( "s3" ) ).toBe( mockProvider );
			} );

			it( "should throw a suitable error when the provider does not exist", function(){
				var service = _getService();

				expect( function(){
					service.getProvider( CreateUUId() );
				} ).toThrow( type="presidecms.storage.provider.not.found" );
			} );
		} );
	}

/************************************ HELPERS ************************************************/
	private function _getService(
		struct configuredProviders = _getDefaultConfiguredProviders()
	) {
		return getMockBox().createMock( object=new preside.system.services.fileStorage.StorageProviderService(
			configuredProviders = arguments.configuredProviders
		) );
	}

	private struct function _getDefaultConfiguredProviders() {
		return {
			  file = { class="preside.system.fileStorage.FileStorageProvider" }
			, s3   = { class="preside.system.fileStorage.S3StorageProvider"   }
		}
	}
}