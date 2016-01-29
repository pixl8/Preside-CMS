component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		antiSamy = new preside.system.services.security.AntiSamyService();
	}

	function run(){

		describe( "clean()", function(){

			it( "should strip script tags from content (we know it should do much more, but just to test...)", function(){
				var dirty   = '<b>BigBossKent</b><button onclick="f()">Alert - please click</button><script>function f() {confirm(“Youve been hacked!")}</script>';
				var cleaned = "<b>BigBossKent</b>#chr(10)#<button>Alert - please click</button>";
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