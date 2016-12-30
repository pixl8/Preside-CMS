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
		var styleElements = doc.select( "style" );
		var ruleDelims    = "{}";

		for( var styleElement in styleElements ) {
			var elementStyleRules = styleElement.getAllElements().get( 0 ).data().replaceAll( "\n", "" ).replaceAll( "\/\*.*?\*\/", "" ).trim();
			var tokenizer         = CreateObject( "java", "java.util.StringTokenizer" ).init( elementStyleRules, ruleDelims );

			while( tokenizer.countTokens() > 1 ) {
				var selector = tokenizer.nextToken();
				var styles   = tokenizer.nextToken();

				if ( !selector.contains( ":" ) ) { // skip a:hover rules, etc.
					var selectedElements = doc.select( selector );
					for ( var selectedElem in selectedElements ) {
						var oldStyle = selectedElem.attr( "style" );
						var newStyle = styles.trim();

						if ( oldStyle.len() ) {
							newStyle = _concatenateStyles( oldStyle, newStyle );
						}

						newStyle = _cleanupStyleWhiteSpace( newStyle );

						selectedElem.attr( "style", newStyle );
					}
				}
			}
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