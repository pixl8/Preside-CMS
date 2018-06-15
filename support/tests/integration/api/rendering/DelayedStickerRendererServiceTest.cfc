component extends="tests.resources.HelperObjects.PresideBddTestCase"{

	function run(){
		describe( "renderDelayedStickerIncludes()", function(){
			it( "should recursively replace delayed Sticker include markup with dynamically rendered includes until there are no more Sticker include markup tags left in the given content", function(){
				var service    = _getService();
				var complexArg = { test="this" };
				var tags       = [
					  "<!--ds:(type=js,group=head)({""data"":{},""includes"":[""head_script.js"",""head_styles.css""],""adhoc"":{}}):ds-->"
					, "<!--ds:(type=css,group=head)({""includes"":[""head_script.js"",""head_styles.css""],""adhoc"":{}}):ds-->"
				];
				var replacements = {
					  "#tags[1]#" = CreateUUId()
					, "#tags[2]#" = CreateUUId()
				};
				var content = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
#tags[1]# exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in #tags[1]# voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in #tags[2]# culpa qui officia deserunt mollit anim id est laborum.";
				var expected = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
#replacements[ tags[1] ]# exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in #replacements[ tags[1] ]# voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in #replacements[ tags[2] ]# culpa qui officia deserunt mollit anim id est laborum.";


				requestContext.$( "renderIncludes" ).$args(
					  type    = "js"
					, group   = "head"
					, delayed = false
				).$results( replacements[ tags[1] ] );
				requestContext.$( "renderIncludes" ).$args(
					  type    = "css"
					, group   = "head"
					, delayed = false
				).$results( replacements[ tags[2] ] );

				expect( service.renderDelayedStickerIncludes( content ) ).toBe( expected );
			} );
		} );

		describe( "renderDelayedViewletTag()", function(){
			it( "should return an html comment string with urlencoded and json serialized args", function(){
				var service  = _getService();
				var expected = "";
				var memento  = {
					  "includes" = {
					  	  "default" = StructNew( "linked" )
					  	, "head"    = StructNew( "linked" )
					  }
					, "adhoc"    = StructNew( "linked" )
					, "data"     = StructNew( "linked" )
				};
				memento.includes.default[ "script.js" ]    = "";
				memento.includes.default[ "styles.css" ]   = "";
				memento.includes.head[ "head_script.js" ]  = "";
				memento.includes.head[ "head_styles.css" ] = "";

				expected = "<!--ds:(type=js,group=head)({""data"":{},""includes"":[""head_script.js"",""head_styles.css""],""adhoc"":{}}):ds-->";

				expect( service.renderDelayedStickerTag(
					  type    = "js"
					, group   = "head"
					, memento = memento
				) ).toBe( expected );
			} );
		} );

	}

	private function _getService(){
		variables.mockColdbox         = CreateStub();
		variables.requestContext      = CreateStub();

		var service = CreateMock( object=new preside.system.services.rendering.DelayedStickerRendererService() );

		mockColdbox.$( "getRequestContext" ).$results( requestContext );
		requestContext.$( "include" ).$results( nullValue() );
		service.$( "$getColdbox", mockColdbox );
		service.$( "$isFeatureEnabled", true );

		return service;
	}


}