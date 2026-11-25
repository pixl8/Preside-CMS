component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "generateToken()", function(){
			it( "returns a 32 character token from the existing alphabet", function(){
				var restUser = CreateObject( "component", "preside.system.preside-objects.rest.rest_user" );
				var seen     = {};
				var token    = "";
				var i        = 0;

				for ( i=1; i<=20; i++ ) {
					token = restUser.generateToken();

					expect( Len( token ) ).toBe( 32 );
					expect( ReFind( "[^A-Za-z0-9=]", token ) ).toBe( 0 );
					expect( StructKeyExists( seen, token ) ).toBeFalse();

					seen[ token ] = true;
				}
			} );
		} );
	}

}
