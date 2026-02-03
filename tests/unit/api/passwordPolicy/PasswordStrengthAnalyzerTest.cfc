component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){
		describe( "calculatePasswordStrength()", function(){
			var analyzer = new preside.system.services.passwordPolicy.PasswordStrengthAnalyzer();

			it( "should return zero for very simple passwords", function(){
				expect( analyzer.calculatePasswordStrength( "password" ) ).toBe( 0 );
			} );

			it( "should return 100 for a reasonably complicated password", function(){
				expect( analyzer.calculatePasswordStrength( "mPzxAJ4QmQbGsBfWALdd6hxe8QeBpGtpHHs" ) ).toBe( 100 );
			} );

			it( "should return a good score for decent password", function(){
				expect( analyzer.calculatePasswordStrength( "a non-weak pass" ) ).toBe( 87 );
			} );

			it( "should return a low score for a poor password", function(){
				expect( analyzer.calculatePasswordStrength( "weak" ) ).toBe( 9 );
			} );

			it( "should work with very long password", function(){
				var pw = [];
				for( var i=1; i<=2000; i++ ) {
					ArrayAppend( pw, RandRange( 0, 9 ) );
				}

				expect( analyzer.calculatePasswordStrength( ArrayToList( pw, "" ) ) ).toBe( 100 );
			} );
		} );
	}

}
