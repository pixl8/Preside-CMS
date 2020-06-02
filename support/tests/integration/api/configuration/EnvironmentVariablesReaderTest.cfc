component extends="testbox.system.BaseSpec"{

	function run(){
		var reader = createMock( object = new preside.system.services.configuration.EnvironmentVariablesReader() );

		describe( "getConfigFromEnvironmentVariables()", function(){
			it( "should return an empty struct when no environment variables detected", function(){
				reader.$( "_getEnv", {} );

				expect( reader.getConfigFromEnvironmentVariables() ).toBe( {} );
			} );

			it( "should return an empty struct when no environment variables begin with PRESIDE_", function(){
				reader.$( "_getEnv", { PATH="/usr/bin;/usr/local/bin;" } );

				expect( reader.getConfigFromEnvironmentVariables() ).toBe( {} );
			} );

			it( "should return a struct with all PRESIDE_ variables lowercased and with the PRESIDE_ prefix removed", function(){
				reader.$( "_getEnv", {
					  PATH="/usr/bin;/usr/local/bin;"
					, PRESIDE_DATASOURCE_CONNECTION_STRING="jdbc:lsdkjlasfljljfalsdfj"
					, "PRESIDE_ASSET-MANAGER.IMAGEMAGICK_PATH" = "/usr/bin/"
					, NONPRESIDE_VAR = "Whatever"
					, "PRESIDE_SHOWERRORS" = "true"
				} );

				expect( reader.getConfigFromEnvironmentVariables() ).toBe( {
					  "datasource_connection_string"="jdbc:lsdkjlasfljljfalsdfj"
					, "asset-manager.imagemagick_path" = "/usr/bin/"
					, "showerrors" = "true"
				} );
			} );

			it( "should ignore legacy variables used for a separate settings injection system", function(){
				reader.$( "_getEnv", {
					  PRESIDE_APPLICATION_ID             = "test"
					, PRESIDE_SERVER_MANAGER_URL         = "test"
					, PRESIDE_SERVER_MANAGER_SERVER_ID   = "test"
					, PRESIDE_SERVER_MANAGER_PUBLIC_KEY  = "test"
					, PRESIDE_SERVER_MANAGER_PRIVATE_KEY = "test"
				} );

				expect( reader.getConfigFromEnvironmentVariables() ).toBe( {} );
			} );
		} );
	}
}