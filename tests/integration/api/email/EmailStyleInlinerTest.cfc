component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		var inliner = CreateMock( object=new preside.system.services.email.EmailStyleInliner() );

		describe( "inlineStyles()", function(){
			it( "should take all styles defined in &lt;style&gt; tags and make them inline in HTML elements", function(){
				var originalHtml = FileRead( "/resources/emailStyleInliner/originalExample1.html" );
				var expectedHtml = FileRead( "/resources/emailStyleInliner/inlinedExample1.html" );

				inliner.$( "$isFeatureEnabled" ).$args( "emailStyleInlinerAscii" ).$results( false );


				expect( inliner.inlineStyles( originalHtml ) ).toBe( expectedHtml );
			} );

			it( "should ignore styles in media queries", function(){
				var originalHtml = FileRead( "/resources/emailStyleInliner/originalExampleWithMediaQueries.html" );
				var expectedHtml = FileRead( "/resources/emailStyleInliner/inlinedExampleWithMediaQueries.html" );

				inliner.$( "$isFeatureEnabled" ).$args( "emailStyleInlinerAscii" ).$results( false );

				expect( inliner.inlineStyles( originalHtml ) ).toBe( expectedHtml );
			} );

			it( "should preserve html entities when emailStyleInlinerAscii feature is enabled", function(){
				var originalHtml = FileRead( "/resources/emailStyleInliner/originalExample1.html" );
				var expectedHtml = FileRead( "/resources/emailStyleInliner/inlinedExample1_preservedEntities.html" );

				inliner.$( "$isFeatureEnabled" ).$args( "emailStyleInlinerAscii" ).$results( true );

				expect( inliner.inlineStyles( originalHtml ) ).toBe( expectedHtml );
			} );
		} );
	}
}