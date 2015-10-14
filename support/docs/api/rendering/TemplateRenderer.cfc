component {

	public string function render( required string template, struct args={}, string helpers="" ) {
		var rendered = "";

		_includeHelpers( arguments.helpers );

		savecontent variable="rendered" {
			include template=arguments.template;
		}

		rendered = new SyntaxHighlighter().renderHighlights( rendered );

		return Trim( rendered );
	}

	public string function markdownToHtml( required string markdown ) {
		var rendered = new SyntaxHighlighter().renderHighlights( arguments.markdown );

		return new api.parsers.ParserFactory().getMarkdownParser().markdownToHtml( rendered );
	}

	private void function _includeHelpers( required string helpers ) {
		if ( Len( Trim( arguments.helpers ) ) ) {
			var fullHelpersPath = ExpandPath( arguments.helpers );
			var files           = DirectoryList( fullHelpersPath, false, "path", "*.cfm" );

			for( var file in files ){
				var mappedPath = arguments.helpers & Replace( file, fullHelpersPath, "" );
				include template=mappedPath;
			}
		}
	}
}