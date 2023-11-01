component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){
		var sut = new preside.system.services.rendering.DynamicFindAndReplaceService();

		describe( "dynamicFindAndReplace()", function(){
			it( "should leave string untouched when there are no matches", function(){
				var source = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
				var pattern = "\{\{widget:blah:test\}\}";

				var result = sut.dynamicFindAndReplace( source=source, regexPattern=pattern, recurse=false, processor=function( captureGroups ){
					return "replacement";
				} );

				expect( result  ).toBe( source );
			} );


			it( "should replace all matches with logic from the provided processor", function(){
				var source = "Lorem {{test1:value}} ipsum dolor {{test2:value2}} sit {{blah:empty}}amet.{{test3:value3}}";
				var expected = "Lorem Test 1 ipsum dolor Testing is fun sit amet.Testing is easy (is it?)";
				var pattern = "\{\{(.*?):(.*?)\}\}";

				var result = sut.dynamicFindAndReplace( source=source, regexPattern=pattern, recurse=false, processor=function( captureGroups ){
					switch( captureGroups[ 2 ] ) {
						case "test1":
							return "Test 1";
						break;
						case "test2":
							return "Testing is fun";
						break;
						case "test3":
							return "Testing is easy (is it?)"
						break;
					}
					return "";
				} );

				expect( result  ).toBe( expected );
			} );


			it( "should pass all capture groups through to the processor", function(){
				var source  = "Lorem {{test1:value}}";
				var pattern = "\{\{(.*?):(.*?)\}\}";
				var groups  = "";

				var result = sut.dynamicFindAndReplace( source=source, regexPattern=pattern, recurse=false, processor=function( captureGroups ){
					groups = arguments.captureGroups;
					return "whatever";
				} );

				expect( result  ).toBe( "Lorem whatever" );
				expect( groups ).toBe( [ "{{test1:value}}", "test1", "value" ] );
			} );

			it( "should recurse when asked to", function(){
				var source = "Lorem {{test1:value}} ipsum dolor {{test2:value2}} sit {{blah:empty}}amet.{{test3:value3}} some other text.";
				var expected = "Lorem Test 1 Testing is fun Testing is easy (is it?) ipsum dolor Testing is fun Testing is easy (is it?) sit amet.Testing is easy (is it?) some other text.";
				var pattern = "\{\{(.*?):(.*?)\}\}";

				var result = sut.dynamicFindAndReplace( source=source, regexPattern=pattern, recurse=true, processor=function( captureGroups ){
					switch( captureGroups[ 2 ] ) {
						case "test1":
							return "Test 1 {{test2:whatever}}";
						break;
						case "test2":
							return "Testing is fun {{test3:meh}}";
						break;
						case "test3":
							return "Testing is easy (is it?)"
						break;
					}
					return "";
				} );

				expect( result  ).toBe( expected );
			} );

			it( "should prevent endless recursion", function(){
				var source = "Lorem {{test1:value}} ipsum dolor {{test2:value2}} sit {{blah:empty}}amet.{{test3:value3}} some other text.";
				var expected = "Lorem Test 1 Testing is fun  ipsum dolor Testing is fun Test 1 Testing is fun  sit amet.Testing is easy (is it?) some other text.";
				var pattern = "\{\{(.*?):(.*?)\}\}";

				var result = sut.dynamicFindAndReplace( source=source, regexPattern=pattern, recurse=true, processor=function( captureGroups ){
					switch( captureGroups[ 2 ] ) {
						case "test1":
							return "Test 1 {{test2:whatever}}";
						break;
						case "test2":
							return "Testing is fun {{test1:value}}";
						break;
						case "test3":
							return "Testing is easy (is it?)"
						break;
					}
					return "";
				} );

				expect( result  ).toBe( expected );
			} );

			it( "should not choke on numeric input", function(){
				var source  = 5
				var pattern = "\{\{(.*?):(.*?)\}\}";
				var groups  = "";

				var result = sut.dynamicFindAndReplace( source=source, regexPattern=pattern, recurse=false, processor=function( captureGroups ){
					return "whatever";
				} );

				expect( result  ).toBe( "5" );
			} );
		} );
	}
}