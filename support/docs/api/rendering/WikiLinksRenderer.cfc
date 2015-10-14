component accessors=true {

	property name="docTree";

	public string function renderLinks( required string text, required any builder ) {
		var rendered = arguments.text;
		var link     = "";

		do {
			link = _getNextLink( rendered );
			if ( !IsNull( link ) ) {
				rendered = Replace( rendered, link.rawMatch, arguments.builder.renderLink( link.page ?: NullValue(), link.title ), "all" );
			}
		} while( !IsNull( link ) );

		return rendered;
	}

// PRIVATE HELPERS
	private any function _getNextLink( required string text, required string startPos=1 ) {
		var referenceRegex  = "\[\[(.*?)\]\]";
		var regexFindResult = ReFind( referenceRegex, arguments.text, arguments.startPos, true );
		var found           = regexFindResult.len[1] > 0;

		if ( !found ) {
			return;
		}

		var precedingContent = regexFindResult.pos[1] == 1 ? "" : Trim( Left( arguments.text, regexFindResult.pos[1]-1 ) );
		var matchIsWithinCodeBlock = precedingContent.endsWith( "<pre>" ) || precedingContent.endsWith( "<code>" );

		if ( matchIsWithinCodeBlock ) {
			return _getNextLink( arguments.text, regexFindResult.pos[1]+regexFindResult.len[1] );
		}

		var rawMatch  = Mid( arguments.text, regexFindResult.pos[1], regexFindResult.len[1] );
		var reference = Mid( arguments.text, regexFindResult.pos[2], regexFindResult.len[2] );
		var pageId    = ListFirst( reference, "|" );
		var page      = getDocTree().getPage( pageId );
		var title     = ListLen( reference, "|" ) > 1 ? ListRest( reference, "|" ) : ( IsNull( page ) ? pageId : page.getTitle() );

		return {
			  rawMatch = rawMatch
			, page     = page  ?: NullValue()
			, title    = title ?: pageId
		};
	}
}