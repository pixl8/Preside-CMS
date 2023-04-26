component extends="testbox.system.BaseSpec" {


	function run(){
		describe( "firstNonEmptyString()", function(){
			it( "should return the first non-empty string from the supplied arguments", function(){
				include "/preside/system/helpers/stringUtils.cfm";

				expect( firstNonEmptyString() ).toBe( "" );
				expect( firstNonEmptyString( "", "" ) ).toBe( "" );
				expect( firstNonEmptyString( "", "one", "two" ) ).toBe( "one" );
				expect( firstNonEmptyString( "", [ "one" ], "two" ) ).toBe( "two" );
				expect( firstNonEmptyString( "", [ "one" ], {a="two"} ) ).toBe( "" );
			} );
		} );

	}

}