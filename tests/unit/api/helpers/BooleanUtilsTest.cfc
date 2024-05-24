component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "the isTrue() helper function", function(){
			it( "should return true if a truthy argument is supplied", function(){
				include "/preside/system/helpers/booleanUtils.cfm";

				expect( isTrue( true ) ).toBe( true );
				expect( isTrue( "true" ) ).toBe( true );
				expect( isTrue( 1 ) ).toBe( true );
				expect( isTrue( -1 ) ).toBe( true );
				expect( isTrue( 50 ) ).toBe( true );
			} );

			it( "should return false if a falsey argument is supplied", function(){
				include "/preside/system/helpers/booleanUtils.cfm";

				expect( isTrue( false ) ).toBe( false );
				expect( isTrue( "false" ) ).toBe( false );
				expect( isTrue( "some random string" ) ).toBe( false );
				expect( isTrue( 0 ) ).toBe( false );
				expect( isTrue( "" ) ).toBe( false );
				expect( isTrue( NullValue() ) ).toBe( false );
				expect( isTrue() ).toBe( false );
			} );
		} );

		describe( "the isFalse() helper function", function(){
			it( "should return false if a truthy argument is supplied", function(){
				include "/preside/system/helpers/booleanUtils.cfm";

				expect( isFalse( true ) ).toBe( false );
				expect( isFalse( "true" ) ).toBe( false );
				expect( isFalse( 1 ) ).toBe( false );
				expect( isFalse( -1 ) ).toBe( false );
				expect( isFalse( 50 ) ).toBe( false );
			} );

			it( "should return true if a falsey argument is supplied", function(){
				include "/preside/system/helpers/booleanUtils.cfm";

				expect( isFalse( false ) ).toBe( true );
				expect( isFalse( "false" ) ).toBe( true );
				expect( isFalse( "some random string" ) ).toBe( true );
				expect( isFalse( 0 ) ).toBe( true );
				expect( isFalse( "" ) ).toBe( true );
				expect( isFalse( NullValue() ) ).toBe( true );
				expect( isFalse() ).toBe( true );
			} );
		} );
	}

}