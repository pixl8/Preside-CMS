/**
 * The Tika Wrapper service object is a simple CFML API for interacting with Apache Tika (http://tika.apache.org).
 *
 * Its purpose in the context of PresideCMS is for metadata and content extraction from uploaded documents.
 */
component output=false autodoc=true {

// CONSTRUCTOR
	public any function init() output=false {
		_setTikaJarPath( "/preside/system/externals/tika/tika-app-1.5.jar" );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * This method returns any metadata as a cfml structure that Tika can extract from the passed file (path)
	 *
	 * @filePath.hint Path to the file that you wish to extract metadata from (must be absolute)
	 */
	public struct function getMetaData( required string filePath ) output=false {
		var result = _parse( filePath = arguments.filePath, includeText = false );

		return result.metadata ?: {};
	}

// PRIVATE HELPERS
	private struct function _parse( required string filePath, boolean includeMeta=true, boolean includeText=true ) output=false {
		var result  = {};
		var f       = CreateObject( "java", "java.io.File"            ).init( filePath );
		var fis     = CreateObject( "java", "java.io.FileInputStream" ).init( f );
		var jarPath = _getTikaJarPath();

		try {
			var parser = CreateObject( "java", "org.apache.tika.parser.AutoDetectParser", jarPath );
			var ch     = CreateObject( "java", "org.apache.tika.sax.BodyContentHandler" , jarPath ).init(-1);
			var md     = CreateObject( "java", "org.apache.tika.metadata.Metadata"      , jarPath ).init();

			parser.parse( fis, ch, md );

			if ( arguments.includeMeta ) {
				result.metadata = {};

				for( var key in md.names() ) {
					var mdval = md.get( key );
					if ( !isNull( mdval ) ) {
						result.metadata[ key ] = mdval;
					}
				}
			}

			if ( arguments.includeText ) {
				result.text = ch.toString();
			}

		} catch( any e ) {
			result = { error = e };
		}

		fis.close();

		return result;
	}

// GETTERS AND SETTERS
	private string function _getTikaJarPath() output=false {
		return _tikaJarPath;
	}
	private void function _setTikaJarPath( required string tikaJarPath ) output=false {
		_tikaJarPath = arguments.tikaJarPath;
	}

}