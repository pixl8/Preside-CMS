/**
 * @presideService true
 * @singleton      true
 * @feature        assetManager
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

	public void function svgToPng(
		  required string  svgFilePath
		,          numeric width  = 0
		,          numeric height = 0
	) {
		var pngFilePath = getTempFile( GetTempDirectory(), "png" );

		try{
			var lib     = _getLib();
			var t       = createObject("java", "org.apache.batik.transcoder.image.PNGTranscoder", lib ).init();
			var svgURI  = createObject("java", "java.io.File").init( arguments.svgFilePath ).toURL().toString();
			var input   = createObject("java", "org.apache.batik.transcoder.TranscoderInput", lib ).init( svgURI );
			var ostream = createObject("java", "java.io.FileOutputStream" ).init( pngFilePath );
			var output  = createObject("java", "org.apache.batik.transcoder.TranscoderOutput", lib ).init( ostream );

			if ( arguments.width ) {
				t.addTranscodingHint( t.KEY_WIDTH, JavaCast( "float", arguments.width ) );
			}
			if ( arguments.height ) {
				t.addTranscodingHint( t.KEY_HEIGHT, JavaCast( "float", arguments.height ) );
			}

			t.transcode( input, output );

			ostream.flush();
			ostream.close();

			FileMove( pngFilePath, arguments.svgFilePath );
		} catch ( any e ) {
			$raiseError( e );
			rethrow;
		} finally {
			if ( FileExists( pngFilePath ) ) {
				FileDelete( pngFilePath )
			}
		}
	}

	private array function _getLib() {
		return [
			  "/preside/system/services/assetmanager/lib/batik-all-1.9.jar"
			, "/preside/system/services/assetmanager/lib/xml-apis-ext-1.3.04.jar"
			, "/preside/system/services/assetmanager/lib/xmlgraphics-commons-2.3.jar"
		];
	}

}