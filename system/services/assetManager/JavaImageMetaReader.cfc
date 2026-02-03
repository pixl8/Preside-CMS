/**
 * Provides logic for extracting XMP metadata from an image file
 *
 * @autodoc   true
 * @singleton true
 * @feature   assetManager
 */
component {

	/**
	 * Returns a structure of found metadata from the passed file path
	 *
	 * @autodoc
	 * @filePath.hint Path to the file from which to return meta
	 *
	 */
	public static function readMeta( required string filePath ) {
		try {
			var fileobj = CreateObject( "java", "java.io.File" ).init( filePath );
			var imageInfo = CreateObject( "java", "org.apache.commons.imaging.Imaging" ).getImageInfo( fileobj );

			return {
				  width                = imageInfo.getWidth()
				, height               = imageInfo.getHeight()
				, format               = imageInfo.getFormatName()
				, formatDetails        = imageInfo.getFormatDetails()
				, progressive          = imageInfo.isProgressive()
				, transparent          = imageInfo.isTransparent()
				, bitsPerPixel         = imageInfo.getBitsPerPixel()
				, numberOfImages       = imageInfo.getNumberOfImages()
			};
		} catch( any e ) {
			return {};
		}
	}

}