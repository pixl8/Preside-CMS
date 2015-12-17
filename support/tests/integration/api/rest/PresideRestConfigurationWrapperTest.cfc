component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "getSetting", function(){

			it( "should fetch the configuration value from the global rest configuration struct when passed key matches", function(){
				var wrapper = getWrapper( { someSetting="test" } );

				expect( wrapper.getSetting( name="someSetting" ) ).toBe( "test" );
			} );

			it( "it should return empty string when the configuration setting does not exist", function(){
				var wrapper = getWrapper();

				expect( wrapper.getSetting( name="nonExistantSetting" ) ).toBe( "" );
			} );

			it( "it should return supplied default value when the configuration setting does not exist", function(){
				var wrapper = getWrapper();

				expect( wrapper.getSetting( name="nonExistantSetting", defaultValue="test" ) ).toBe( "test" );
			} );

			it( "it should return the value of specific API configuration when supplied API matches a configured API", function(){
				var wrapper = getWrapper( {
					  someSetting = "test"
					, apis        = {
						  "/myapi/v2" = { someSetting="more specific" }
					}
				} );

				expect( wrapper.getSetting( name="someSetting", api="/myapi/v2" ) ).toBe( "more specific" );

			} );
		} );

	}

	private any function getWrapper( struct configuration={} ) {
		return new preside.system.services.rest.PresideRestConfigurationWrapper(
			configuration=arguments.configuration
		);
	}

}