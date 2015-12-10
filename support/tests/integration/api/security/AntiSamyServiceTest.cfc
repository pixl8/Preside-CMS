component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		antiSamy = new preside.system.services.security.AntiSamyService();
	}

	function run(){

		describe( "clean()", function(){

			it( "should strip script tags from content (we know it should do much more, but just to test...)", function(){
				var dirty   = "some test <script>alert('hello')</script> to be cleaned";
				var cleaned = "some test  to be cleaned";
				var actual  = antiSamy.clean( dirty );

				expect( actual ).toBe( cleaned );
			} );

			it( "should wrap css in CDATA for the myspace policy", function(){
				var dirty   = "some input <style>.class { color: red }</style> with css in it";
				var cleaned = "some input <style><![CDATA[*.class { color: red; } ]]></style> with css in it";
				var actual  = antiSamy.clean( dirty, "myspace" );

				expect( actual contains "CDATA").toBeTrue();
			} );

			it( "should entirely strip css for more stricter policies", function(){
				var dirty   = "some input <style>.class { color: red }</style> with css in it";
				var cleaned = "some input  with css in it";
				var actual  = antiSamy.clean( dirty, "tinymce" );

				expect( actual ).toBe( cleaned );
			} );

			it( "should throw a helpful error when the passed policy does not exist", function(){
				expect( function(){
					antiSamy.clean( "blah", "non-existant-policy" );
				} ).toThrow( type="preside.antisamyservice.policy.not.found" );
			} );

		} );

	}
}