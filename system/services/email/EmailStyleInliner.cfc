/**
 * Service to convert html email styles to be inline.
 *
 * @singleton      true
 * @autodoc        true
 * @presideService true
 * @feature        emailStyleInliner
 */
component {
	variables._lib   = [];
	variables._jsoup = "";

	/**
	 * @styleCache.inject    cachebox:emailStyleInlinerCache
	 * @templateCache.inject cachebox:emailTemplateCache
	 */
	public any function init(
		  required any styleCache
		, required any templateCache
	) {
		_jsoup = _new( "org.jsoup.Jsoup" );

		_setStyleCache( arguments.styleCache );
		_setTemplateCache( arguments.templateCache );

		return this;
	}

	/**
	 * Receives an html string and returns the same HTML
	 * but with all style definitions that reside in `style` tags
	 * converted to inline styles suitable for email sending.
	 *
	 * @autodoc   true
	 * @html.hint the original HTML
	 */
	public string function inlineStyles( required string html, array styles ) {
 		if ( !$helpers.hasTags( arguments.html ) ) {
			return arguments.html;
		}

		var cacheKey = "htmlInlineStyles-#Hash( arguments.html )#";
		var fromCache = _getTemplateCache().get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		arguments.html = trim( arguments.html );

		var innerHtmlOnly = !FindNoCase( "</html>", arguments.html );

		// special cases of widget which only consist of a table cell or row without a wrapping table tag
		// jsoup will remove the TD / TR tags in those cases, therefore adding now and stripping after processing
		var isHtmlTableCell = innerHtmlOnly && ReFindNoCase( "^<td[^>]*>", arguments.html );
		var isHtmlTableRow  = innerHtmlOnly && !isHtmlTableCell && ReFindNoCase( "^<tr[^>]*>", arguments.html );

		// add dummy wrapping html table and row tags to make sure jsoup parsing works as expected
		if ( isHtmlTableCell ) {
			arguments.html = "<table><tbody><tr id='_emailstyleinliner_wrap'>" & arguments.html & "</tr></tbody></table>";
		}
		else if ( isHtmlTableRow ) {
			arguments.html = "<table><tbody id='_emailstyleinliner_wrap'>" & arguments.html & "</tbody></table>"; // tbody useful here as jsoup adds it anyway
		}

		var doc = _jsoup.parse( arguments.html );

		if ( !StructKeyExists( arguments, "styles" ) ) {
			arguments.styles = readStyles( doc );
		}
		var elementStyles = _getElementsWithStylesToApply( doc, arguments.styles );

		for( var elementStyle in elementStyles ) {
			elementStyle.element.attr( "style", elementStyle.style );
		}

		var result = "";
		if ( innerHtmlOnly ) {
			var selector = ( isHtmlTableCell || isHtmlTableRow ) ? "##_emailstyleinliner_wrap" : "body";
			result = doc.select( selector );
			if ( IsArray( local.result ?: "" ) && ArrayLen( result ) ) {
				result = result[ 1 ].html();
			} else {
				result = doc.toString();
			}
		} else {
			result = doc.toString();
		}

		_getTemplateCache().set( cacheKey, result );

		return result;
	}

	/**
	 * Receives an html string or jSoup doc and returns an array
	 * of style rules found
	 *
	 * @autodoc   true
	 * @doc.hint  the original HTML, or a jSoup doc
	 */
	public array function readStyles( required any doc ) {
		if ( IsSimpleValue( arguments.doc ) ) {
			arguments.doc = _jsoup.parse( arguments.doc );
		}

		var styleElements = doc.select( "style" );
		var cacheKey = "stylescache-" & Hash( styleElements.toString() );
		var fromCache = _getStyleCache().get( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		var ruleDelims    = "{}";
		var styles        = [];

		for( var styleElement in styleElements ) {
			var elementStyleRules = styleElement.getAllElements().get( 0 ).data().replaceAll( "\n", "" ).replaceAll( "\/\*.*?\*\/", "" ).reReplaceNoCase( "\@media.*?\{(.*?\})?\s*?\}", "", "all" ).trim();
			var tokenizer         = CreateObject( "java", "java.util.StringTokenizer" ).init( elementStyleRules, ruleDelims );

			while( tokenizer.countTokens() > 1 ) {
				var selector = tokenizer.nextToken();
				var style    = tokenizer.nextToken();

				if ( !selector.contains( ":" ) ) { // skip a:hover rules, etc.
					style = style.reReplace( "([^;])$", "\1;" );
					var rules = style.listToArray( ";" );
					for( var rule in rules ) {
						rule = rule.trim();

						if ( rule.len() ) {
							styles.append({
								  selector = selector
								, rule     = rule
								, score    = _scoreStylePrecedence( selector, rule )
							});
						}
					}
				}
			}
		}

		styles = _orderStylesBySelectorPrecedence( styles );

		_getStyleCache().set( cacheKey, styles );

		return styles;
	}

// PRIVATE HELPERS

	private any function _new( required string className ) {
		return CreateObject( "java", arguments.className, _getLib() );
	}

	private array function _getLib() {
		if ( !_lib.len() ) {
			var libDir = GetDirectoryFromPath( getCurrentTemplatePath() ) & "/lib";
			_lib = DirectoryList( libDir, false, "path", "*.jar" );
		}
		return _lib;
	}

	private array function _getElementsWithStylesToApply( required any doc, required array styles ) {
		var elems         = [];
		var elemStyles    = [];

		for( var style in styles ) {
			try {
				var selectedElements = doc.select( style.selector );
			} catch( any e ) {
				continue;
			}

			for ( var selectedElem in selectedElements ) {
				var index = ArrayFind( elems, selectedElem );
				if ( !index ) {
					ArrayAppend( elems, selectedElem );
					ArrayAppend( elemStyles, StructNew( "linked" ) );
					index = ArrayLen( elems );
				}
				var elemStyle = elemStyles[ index ];


				if ( !StructCount( elemStyle ) ) {
					var existingInlineStyles = ListToArray( selectedElem.attr( "style" ), ";" );
					for( var existingInlineStyle in existingInlineStyles ) {
						existingInlineStyle = Trim(  existingInlineStyle );
						if ( existingInlineStyle.len() ) {
							var prop  = Trim( ListFirst( existingInlineStyle, ":" ) );
							var value = Trim( ListRest( existingInlineStyle, ":" ) );

							elemStyle[ prop ] = {
								  value = value
								, score = [ 0, 1, 0, 0, 0 ]
							};
						}
					}
				}

				var prop  = Trim( ListFirst( style.rule, ":" ) );
				var value = Trim( ListRest( style.rule, ":" ) );

				if ( !StructKeyExists( elemStyle, prop ) || _compareScores( elemStyle[ prop ].score, style.score ) == 1 ) {
					elemStyle[ prop ] = {
						  value = value
						, score = style.score
					};
				}
			}
		}

		var index = 1;
		for( var elem in elemStyles ) {
			var style = "";
			for( var prop in elem ) {
				style = ListAppend( style, "#prop#:#elem[ prop ].value#", ";" );
			}

			elems[ index ] = {
				  element = elems[ index ]
				, style   = style
			};

			index++;
		}

		return elems;
	}

	private array function _orderStylesBySelectorPrecedence( required array styles ) {
		styles.sort( function( a, b ){
			return _compareScores( _scoreStylePrecedence( a.selector, a.rule ), _scoreStylePrecedence( b.selector, b.rule ) );
		} );

		return styles;
	}

	private numeric function _compareScores( a, b ) {
		for( var i=1; i<=5; i++ ) {
			if ( a[ i ] == b[ i ] ) {
				continue;
			}

			return a[ i ] > b[ i ] ? -1 : 1;
		}

		return 0;
	}

	private array function _scoreStylePrecedence( required string selector, required string rule ) {
		var score          = [ 0, 0, 0, 0, 0 ];
		var selectorTokens = ListToArray( selector," >+" );

		for( var selectorToken in selectorTokens ) {
			selectorToken = Trim( selectorToken );

			if ( ReFind( "^##", selectorToken ) ) {
				score[ 3 ]++;
			} else if ( ReFind( "^\.", selectorToken ) ) {
				score[ 4 ]++;
			} else {
				score[ 5 ]++;
			}
		}

		if ( Trim( rule ) contains "!important" ) {
			score[ 1 ]++;
		}

		return score;
	}


	private string function _concatenateStyles( required string oldStyles, required string newStyles ) {
		var concatenated = Trim( oldStyles );

		if ( !concatenated.endsWith( ";" ) ) {
			concatenated &= ";";
		}

		concatenated &= Trim( newStyles );

		return concatenated;
	}

	private string function _cleanupStyleWhiteSpace( required string style ) {
		var cleanedUp = Trim( style );

		cleanedUp = ReReplace( cleanedUp, "\s{2,}", " ", "all" );
		cleanedUp = ReReplace( cleanedUp, "\s:", ":", "all" );
		cleanedUp = ReReplace( cleanedUp, ":\s", ":", "all" );
		cleanedUp = ReReplace( cleanedUp, ";$", "" );

		return cleanedUp;
	}

// GETTERS AND SETTERS
	private any function _getStyleCache() {
	    return _styleCache;
	}
	private void function _setStyleCache( required any styleCache ) {
	    _styleCache = arguments.styleCache;
	}

	private any function _getTemplateCache() {
	    return _templateCache;
	}
	private void function _setTemplateCache( required any templateCache ) {
	    _templateCache = arguments.templateCache;
	}

}