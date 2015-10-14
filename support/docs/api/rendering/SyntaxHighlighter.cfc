component {

	public string function renderHighlights( required string text ) {
		var rendered  = arguments.text;
		var highlight = "";

		do {
			highlight = _getNextHighlight( rendered );
			if ( !IsNull( highlight ) ) {
				rendered  = Replace( rendered, highlight.rawMatch, renderHighlight( highlight.code, highlight.language ), "all" );
			}
		} while( !IsNull( highlight ) );

		return rendered;
	}

	public string function renderHighlight( required string code, required string language ) {
		var jars        = [ "../lib/pyg-in-blankets-1.0-SNAPSHOT-jar-with-dependencies.jar" ];
		var highlighter = CreateObject( 'java', 'com.dominicwatson.pyginblankets.PygmentsWrapper', jars );

		if ( arguments.language == "luceescript" ) {
			arguments.language = "cfs";
		}
		if ( arguments.language == "lucee" ) {
			arguments.language = "cfm";
		}

		return highlighter.highlight( arguments.code, arguments.language, false );
	}

// PRIVATE HELPERS
	private any function _getNextHighlight( required string text, required string startPos=1 ) {
		var referenceRegex  = "```([a-z]+)?\n(.*?)\n```";
		var regexFindResult = ReFind( referenceRegex, arguments.text, arguments.startPos, true );
		var found           = regexFindResult.len[1] > 0;
		var result          = {};

		if ( !found ) {
			return;
		}

		var precedingContent = regexFindResult.pos[1] == 1 ? "" : Trim( Left( arguments.text, regexFindResult.pos[1]-1 ) );
		var matchIsWithinCodeBlock = precedingContent.endsWith( "<pre>" ) || precedingContent.endsWith( "<code>" );

		if ( matchIsWithinCodeBlock ) {
			return _getNextHighlight( arguments.text, regexFindResult.pos[1]+regexFindResult.len[1] );
		}

		result = {
			  rawMatch = Mid( arguments.text, regexFindResult.pos[1], regexFindResult.len[1] )
			, code     = Mid( arguments.text, regexFindResult.pos[3], regexFindResult.len[3] )
		};

		if ( regexFindResult.pos[2] ) {
			result.language = Mid( arguments.text, regexFindResult.pos[2], regexFindResult.len[2] );
		} else {
			result.language = "text";
		}

		return result;
	}

}