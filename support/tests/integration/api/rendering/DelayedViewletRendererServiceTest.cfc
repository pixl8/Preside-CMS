component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){
		describe( "renderDelayedViewlets()", function(){
			it( "should recursively replace delayed viewlet markup with dynamically rendered versions of the viewlet until there are no more viewlet markup tags left in the given content", function(){
				var service = _getService();
				var dvs     = [
					  "<!--dv:test.viewlet(arg1=true,arg2='test')-->"
					, "<!--dv:another.test.viewlet(arg3=false)-->"
					, "<!--dv:nested.viewlet()-->"
				];
				var replacements = {
					  "#dvs[1]#" = CreateUUId()
					, "#dvs[2]#" = "Test #dvs[3]#"
					, "#dvs[3]#" = CreateUUId()
				};
				var content = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
#dvs[1]# exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in #dvs[1]# voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in #dvs[2]# culpa qui officia deserunt mollit anim id est laborum.";
				var expected = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
#replacements[ dvs[1] ]# exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in #replacements[ dvs[1] ]# voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in Test #replacements[ dvs[3] ]# culpa qui officia deserunt mollit anim id est laborum.";

				mockColdbox.$( "runEvent" ).$args(
					  event          = "test.viewlet"
					, private        = true
					, prepostExempt  = true
					, eventArguments = {
						  delayedViewlet = true
						, args           = { arg1=true, arg2='test' }
					  }
				).$results( replacements[ dvs[1] ] );
				mockColdbox.$( "runEvent" ).$args(
					  event          = "another.test.viewlet"
					, private        = true
					, prepostExempt  = true
					, eventArguments = {
						  delayedViewlet = true
						, args           = { arg3=false }
					  }
				).$results( replacements[ dvs[2] ] );
				mockColdbox.$( "runEvent" ).$args(
					  event          = "nested.viewlet"
					, private        = true
					, prepostExempt  = true
					, eventArguments = {
						  delayedViewlet = true
						, args           = {}
					  }
				).$results( replacements[ dvs[3] ] );


				expect( service.renderDelayedViewlets( content ) ).toBe( expected );
			} );
		} );
	}

	private function _getService(){
		variables.mockColdbox = CreateStub();

		var service = CreateMock( object=new preside.system.services.rendering.DelayedViewletRendererService() );

		service.$( "$getColdbox", mockColdbox );

		return service;
	}


}