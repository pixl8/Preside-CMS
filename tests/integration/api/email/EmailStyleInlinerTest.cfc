component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		var mockCache = CreateStub();
		helpers       = getMockBox().createStub();

		var inliner = createMock( object=new preside.system.services.email.EmailStyleInliner( templateCache=mockCache, styleCache=mockCache ) );
		inliner.$property( propertyName="$helpers", mock=helpers );
		helpers.$( method="hasTags", callback=function( val ){
			return ReFind(  "<[^>]*>",arguments.val );
		} );

		mockCache.$( "get" );
		mockCache.$( "set" );
		mockCache.$( "clear" );
		mockCache.$( "clearAll" );

		describe( "inlineStyles()", function(){
			it( "should take all styles defined in &lt;style&gt; tags and make them inline in HTML elements", function(){
				var originalHtml = FileRead( "/resources/emailStyleInliner/originalExample1.html" );
				var expectedHtml = FileRead( "/resources/emailStyleInliner/inlinedExample1.html" );

				expect( inliner.inlineStyles( originalHtml ) ).toBe( expectedHtml );
			} );

			it( "should ignore styles in media queries", function(){
				var originalHtml = FileRead( "/resources/emailStyleInliner/originalExampleWithMediaQueries.html" );
				var expectedHtml = FileRead( "/resources/emailStyleInliner/inlinedExampleWithMediaQueries.html" );

				expect( inliner.inlineStyles( originalHtml ) ).toBe( expectedHtml );
			} );

			it( "should ignore html without tags", function(){
				var originalHtml = "a string without tags";
				var expectedHtml = "a string without tags";

				expect( inliner.inlineStyles( originalHtml ) ).toBe( expectedHtml );
			} );

			it( "should work fine with table cell only html snippets", function(){
				var originalHtml = "<td>table cell content</td>";
				var expectedHtml = "<td>table cell content</td>";

				expect( inliner.inlineStyles( originalHtml ) ).toBe( expectedHtml );
			} );

			it( "should work fine with table row only html snippets", function(){
				var originalHtml = "<tr><td>table row cell content</td></tr>";
				var expectedHtml = "<tr><td>table row cell content</td></tr>";

				var actualHtml = inliner.inlineStyles( originalHtml );

				// attention: jsoup adds some whitespace between tags
				actualHtml = reReplace( actualHtml, "<tr>\s*<td>", "<tr><td>" );
				actualHtml = reReplace( actualHtml, "</td>\s*</tr>", "</td></tr>" );

				expect( actualHtml ).toBe( expectedHtml );
			} );
		} );


	}
}