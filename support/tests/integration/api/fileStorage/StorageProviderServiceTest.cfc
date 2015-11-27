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