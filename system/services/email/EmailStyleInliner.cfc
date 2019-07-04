/**
 * Service to convert html email styles to be inline.
 *
 * @singleton      true
 * @autodoc        true
 */
component {
	variables._lib   = [];
	variables._jsoup = "";

	public any function init() {
		_jsoup = _new( "org.jsoup.Jsoup" );

		return this;
	}

	/**
	 * Recieves an html string and returns the same HTML
	 * but with all style definitions that reside in `style` tags
	 * converted to inline styles suitable for email sending.
	 *
	 * @autodoc   true
	 * @html.hint the original HTML
	 */
	public string function inlineStyles( required string html ) {
		var doc           = _jsoup.parse( arguments.html );
		var elementStyles = _getElementsWithStylesToApply( doc );

		for( var elementStyle in elementStyles ) {
			elementStyle.element.attr( "style", elementStyle.style );
		}

		return doc.toString();
	}

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

	private array function _readStyles( required any doc ) {
		var styleElements = doc.select( "style" );
		var ruleDelims    = "{}";
		var styles        = [];

		for( var styleElement in styleElements ) {
			var elementStyleRules = styleElement.getAllElements().get( 0 ).data().replaceAll( "\n", "" ).replaceAll( "\/\*.*?\*\/", "" ).trim();
			var tokenizer         = CreateObject( "java", "java.util.StringTokenizer" ).init( elementStyleRules, ruleDelims );

			while( tokenizer.countTokens() > 1 ) {
				var selector = tokenizer.nextToken();
				var style    = tokenizer.nextToken();

				if ( !selector.contains( ":" ) ) { // skip a:hover rules, etc.
					style = style.reReplace( "[^;]$", ";" );
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

		return _orderStylesBySelectorPrecedence( styles );
	}

	private array function _getElementsWithStylesToApply( required any doc ) {
		var styles        = _readStyles( doc );
		var elems         = [];
		var elemStyles    = [];

		for( var style in styles ) {
			try {
				var selectedElements = doc.select( style.selector );
			} catch( any e ) {
				continue;
			}

			for ( var selectedElem in selectedElements ) {
				var index = elems.find( selectedElem );
				if ( !index ) {
					elems.append( selectedElem );
					elemStyles.append( StructNew( "linked" ) );
					index = elems.len();
				}
				var elemStyle = elemStyles[ index ];


				if ( !elemStyle.count() ) {
					var existingInlineStyles = selectedElem.attr( "style" ).listToArray( ";" );
					for( var existingInlineStyle in existingInlineStyles ) {
						existingInlineStyle = existingInlineStyle.trim();
						if ( existingInlineStyle.len() ) {
							var prop  = existingInlineStyle.listFirst( ":" ).trim();
							var value = existingInlineStyle.listRest( ":" ).trim();

							elemStyle[ prop ] = {
								  value = value
								, score = [ 0, 1, 0, 0, 0 ]
							};
						}
					}
				}

				var prop  = style.rule.listFirst( ":" ).trim();
				var value = style.rule.listRest( ":" ).trim();

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
				style = style.listAppend( "#prop#:#elem[ prop ].value#", ";" );
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
		var selectorTokens = selector.listToArray( " >+" );

		for( var selectorToken in selectorTokens ) {
			selectorToken = Trim( selectorToken );

			if ( selectorToken.reFind( "^##" ) ) {
				score[ 3 ]++;
			} else if ( selectorToken.reFind( "^\." ) ) {
				score[ 4 ]++;
			} else {
				score[ 5 ]++;
			}
		}

		if ( rule.trim().contains( "!important" ) ) {
			score[ 1 ]++;
		}

		return score;
	}


	private string function _concatenateStyles( required string oldStyles, required string newStyles ) {
		var concatenated = oldStyles.trim();

		if ( !concatenated.endsWith( ";" ) ) {
			concatenated &= ";";
		}

		concatenated &= newStyles.trim();

		return concatenated;
	}

	private string function _cleanupStyleWhiteSpace( required string style ) {
		var cleanedUp = style.trim();

		cleanedUp = cleanedUp.reReplace( "\s{2,}", " ", "all" );
		cleanedUp = cleanedUp.reReplace( "\s:", ":", "all" );
		cleanedUp = cleanedUp.reReplace( ":\s", ":", "all" );
		cleanedUp = cleanedUp.reReplace( ";$", "" );

		return cleanedUp;
	}

}