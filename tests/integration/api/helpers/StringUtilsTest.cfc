component extends="testbox.system.BaseSpec" {


	function run(){
		describe( "the firstNonEmptyString() helper function", function(){
			it( "should return an empty string if no arguments are supplied", function(){
				include "/preside/system/helpers/stringUtils.cfm";

				expect( firstNonEmptyString() ).toBe( "" );
			} );

			it( "should return the first non-empty string from the supplied arguments", function(){
				include "/preside/system/helpers/stringUtils.cfm";

				expect( firstNonEmptyString( "", "" ) ).toBe( "" );
				expect( firstNonEmptyString( "", "   ", "one", "two" ) ).toBe( "one" );
				expect( firstNonEmptyString( "one", "", "two" ) ).toBe( "one" );
				expect( firstNonEmptyString( "", "one", "two" ) ).toBe( "one" );
			} );

			it( "should ignore any supplied arguments that are not simple values", function(){
				include "/preside/system/helpers/stringUtils.cfm";

				expect( firstNonEmptyString( "", [ "one" ], "two" ) ).toBe( "two" );
				expect( firstNonEmptyString( "", [ "one" ], {a="two"} ) ).toBe( "" );
			} );

			it( "should treat null-valued arguments as empty string without erroring", function(){
				include "/preside/system/helpers/stringUtils.cfm";

				expect( firstNonEmptyString( nullValue(), "", "one", "two" ) ).toBe( "one" );
				expect( firstNonEmptyString( nullValue() ) ).toBe( "" );
			} );
		} );

	}

}