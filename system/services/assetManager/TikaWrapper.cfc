/**
 * The Tika Wrapper service object is a simple CFML API for interacting with Apache Tika (http://tika.apache.org).
 *
 * Its purpose in the context of PresideCMS is for metadata and content extraction from uploaded documents.
 */
component singleton=true autodoc=true displayName="Apache Tika Wrapper" {

// CONSTRUCTOR
	public any function init() {
		_setTikaJarPath( "/preside/system/externals/tika/tika-app-1.2.jar" );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * This method returns any metadata as a cfml structure that Tika can extract from the passed file (path)
	 *
	 * @fileContent.hint Binary content of the file for which you want to extract meta data
	 * @autodoc true
	 */
	public struct function getMetaData( required any fileContent ) {
		var result = _parse( fileContent = arguments.fileContent, includeText = false );

		return result.metadata ?: {};
	}

	/**
	 * This method returns raw text read from the document, useful for populating search engines, etc.
	 *
	 * @fileContent.hint Binary content of the file for which you want to extract meta data
	 * @autodoc true
	 */
	public string function getText( required any fileContent ) {
		var result = _parse( fileContent = arguments.fileContent, includeMeta=false );

		return result.text ?: "";
	}

// PRIVATE HELPERS
	private struct function _parse( required any fileContent, boolean includeMeta=true, boolean includeText=true ) {
		var result  = {};
		var is      = "";
		var jarPath = _getTikaJarPath();

		if ( IsBinary( arguments.fileContent ) ) {
			is = CreateObject( "java", "java.io.ByteArrayInputStream" ).init( arguments.fileContent );
		} else {
			// TODO, support plain string input (i.e. html)
			return {};
		}

		try {
			var parser = CreateObject( "java", "org.apache.tika.parser.AutoDetectParser", jarPath );
			var ch     = CreateObject( "java", "org.apache.tika.sax.BodyContentHandler" , jarPath ).init(-1);
			var md     = CreateObject( "java", "org.apache.tika.metadata.Metadata"      , jarPath ).init();

			parser.parse( is, ch, md );

			if ( arguments.includeMeta ) {
				result.metadata = {};

				for( var key in md.names() ) {
					var mdval = md.get( key );
					if ( !isNull( mdval ) ) {
						result.metadata[ key ] = _removeNonUnicodeChars( mdval );
					}
				}
			}

			if ( arguments.includeText ) {
				result.text = _removeNonUnicodeChars( ch.toString() );
			}

		} catch( any e ) {
			result = { error = e };
		}

		return result;
	}

	private string function _removeNonUnicodeChars( required string potentiallyDirtyString ) {
		return ReReplace( arguments.potentiallyDirtyString, "[^\x20-\x7E]", "", "all" );
	}

// GETTERS AND SETTERS
	private string function _getTikaJarPath() {
		return _tikaJarPath;
	}
	private void function _setTikaJarPath( required string tikaJarPath ) {
		_tikaJarPath = arguments.tikaJarPath;
	}

}