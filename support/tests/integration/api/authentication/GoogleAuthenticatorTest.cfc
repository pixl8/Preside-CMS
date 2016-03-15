component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		authenticator = createMock( object=new preside.system.services.authentication.GoogleAuthenticator() );
		authenticator.$( "getCurrentTime", 0 );
	}

	function run(){

		describe( "base32decodeString()", function(){
			it( "should correctly decode base 32 encoded strings", function(){
				expect( authenticator.base32decodeString(""                 ) ).toBe( ""       );
				expect( authenticator.base32decodeString("MY======"         ) ).toBe( "f"      );
				expect( authenticator.base32decodeString("MZXQ===="         ) ).toBe( "fo"     );
				expect( authenticator.base32decodeString("MZXW6==="         ) ).toBe( "foo"    );
				expect( authenticator.base32decodeString("MZXW6YQ="         ) ).toBe( "foob"   );
				expect( authenticator.base32decodeString("MZXW6YTB"         ) ).toBe( "fooba"  );
				expect( authenticator.base32decodeString("MZXW6YTBOI======" ) ).toBe( "foobar" );
			} );
		} );

		describe( "base32encodeString()", function(){
			it( "should accept a string and encode in Base 32", function(){
				expect( authenticator.base32encodeString(""       ) ).toBe( ""                 );
				expect( authenticator.base32encodeString("f"      ) ).toBe( "MY======"         );
				expect( authenticator.base32encodeString("fo"     ) ).toBe( "MZXQ===="         );
				expect( authenticator.base32encodeString("foo"    ) ).toBe( "MZXW6==="         );
				expect( authenticator.base32encodeString("foob"   ) ).toBe( "MZXW6YQ="         );
				expect( authenticator.base32encodeString("fooba"  ) ).toBe( "MZXW6YTB"         );
				expect( authenticator.base32encodeString("foobar" ) ).toBe( "MZXW6YTBOI======" );
			} );
		} );

		describe( "base32encode()", function(){
			it( "should accept a byte array an encode in Base 32", function(){
				var bytes = javaCast( "byte[]", [ 0, 0, 0, 0, 0 ] );

				expect( authenticator.base32encode( bytes ) ).toBe( "AAAAAAAA" );
			} );
		} );

		describe( "base32decode()", function(){
			it( "should decode a base 32 string as a byte array", function(){
				var dec = authenticator.base32decode( "AAAAAAAA" );

				expect( ArrayLen( dec ) ).toBe( 5 );
				for( var i = 1; i <= 5; i++ ) {
					expect( dec[ i ] ).toBe( 0 );
				}
			} );
		} );

		describe( "generateKey()", function(){

			it( "should create a 16 character key when supplied a simple password", function(){
				var key = authenticator.generateKey( "whatever i like" );

				expect( key.len() ).toBe( 16 );
			} );

			it( "should throw an informative error when provided a bad salt", function(){
				var badSalt = JavaCast( "byte[]", [ 0, 0 ] );

				try {
					authenticator.generateKey( "blah", badSalt );
					fail( "No error was thrown" );
				} catch ( any e ) {
					expect( e.errorCode ).toBe( "GoogleAuthenticator.BadSalt" );
				}
			} );

			it( "should provide a predictable key when using a known salt and password", function(){
				var goodSalt = CharsetDecode( "1234567890123456", "utf-8" );
				var key      = authenticator.generateKey( "password", goodSalt );

				expect( key ).toBe( "D5NJOIFNXEB4DL7M" );
			} );

		} );

		describe( "getOneTimeToken()", function(){

			it( "should return a predictable token given a known secret key and counter", function(){
				var token = authenticator.getOneTimeToken( "D5NJOIFNXEB4DL7M", 0 );

				expect( token ).toBe( "731217" );
			} );

		} );

		describe( "getGoogleToken()", function(){

			it( "should return a predictable token given a known secret key and counter based on 30 second interval counters", function(){


				var token = authenticator.getGoogleToken( "D5NJOIFNXEB4DL7M" );
				expect( token ).toBe( "731217" );
			} );

		} );

		describe( "verifyGoogleToken()", function(){

			it( "should return false when invalid value passed", function(){
				expect( authenticator.verifyGoogleToken( "D5NJOIFNXEB4DL7M", "000000", 0 ) ).toBeFalse();
			} );

			it( "should return true when expected valid value passed", function(){
				expect( authenticator.verifyGoogleToken( "D5NJOIFNXEB4DL7M", "731217", 0 ) ).toBeTrue();
			} );

			it( "should return false when old valid value passed with no grace", function(){
				expect( authenticator.verifyGoogleToken( "D5NJOIFNXEB4DL7M", "434975", 0 ) ).toBeFalse();
			} );

			it( "should return true when old valid value passed with grace", function(){
				expect( authenticator.verifyGoogleToken( "D5NJOIFNXEB4DL7M", "434975", 1 ) ).toBeTrue();
			} );

			it( "should return true when old valid value passed with excess grace", function(){
				expect( authenticator.verifyGoogleToken( "D5NJOIFNXEB4DL7M", "434975", 2 ) ).toBeTrue();
			} );

		} );

		describe( "getOtpUrl", function(){

			it( "should return a URL that can be used in a QR code with the Google Authenticator app", function(){
				var otpUrl = authenticator.getOtpUrl( "My app", "test@example.com", "D5NJOIFNXEB4DL7M" );

				expect( otpUrl ).toBe( "otpauth://totp/My%20app:test@example.com?secret=D5NJOIFNXEB4DL7M" );
			} );

		} );
	}
}