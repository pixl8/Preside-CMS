/**
 * Provides logic for extracting XMP metadata from an image file
 *
 * @autodoc
 * @singleton
 */
component {

	public function init() {
		_setupMetaFactory();

		return this;
	}

	/**
	 * Returns a structure of found XMP metadata
	 * from the provided file binary. Returns an
	 * empty structure if no data found.
	 *
	 * @autodoc
	 * @filecontent.help The binary of the file to read meta from
	 *
	 */
	public struct function readMeta( required binary fileContent ) {
		var source    = ToString( fileContent );
		var regex     = "^.*(<x:xmpmeta.*<\/x:xmpmeta>).*$";
		var xmp       = ReReplace( source, regex, "\1" );
		var extracted = {};

		if ( xmp.len() < source.len() && IsXml( xmp ) ) {
			var meta     = _getMetaFactory().parseFromString( Trim( xmp ) );
			var iterator = meta.iterator();

			while( iterator.hasNext() ) {
				var prop  = iterator.next();
				var path  = prop.getPath();
				var value = prop.getValue();

				if ( Len( Trim( path ?: "" ) ) && Len( Trim( value ?: "" ) ) ) {
					path = ListRest( path, ":" );
					path = ReReplace( path, "\[[0-9]+\]", "", "all" );

					extracted[ path ] = value;
				}
			}
		}

		return extracted;
	}

// PRIVATE HELPERS
	private void function _setupMetaFactory() {
		var lib     = [ GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/xmpcore.jar" ];
		var factory = CreateObject( "java", "com.adobe.xmp.XMPMetaFactory", lib );

		_setMetaFactory( factory );
	}

// GETTERS AND SETTERS
	private any function _getMetaFactory() {
		return _factory;
	}
	private void function _setMetaFactory( required any factory ) {
		_factory = arguments.factory;
	}
}