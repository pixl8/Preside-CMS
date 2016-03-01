/**
 * Provides logic for manipulating images.
 *
 * @singleton
 * @autodoc
 * @presideservice
 *
 */
component displayname="Image Manipulation Service" {

	// CONSTRUCTOR
	/**
     * @nativeImageImplementation.inject nativeImageService
     * @imageMagickImplementation.inject imageMagickService
     *
     */
    public any function init(
          required any nativeImageImplementation
        , required any imageMagickImplementation
    ) {
        _setNativeImageImplementation( arguments.nativeImageImplementation );
        _setImageMagickImplementation( arguments.imageMagickImplementation );
        return this;
    }

	public string function resize(
		  required binary  asset
		, required string  filename
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
	) {
       	return _getImplementation().resize(argumentCollection = arguments);
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required string  filename
		, required numeric width
		, required numeric height
		,          string  quality       = "highPerformance"
	) {
		return _getImplementation().shrinkToFit(argumentCollection = arguments);
	}

	public binary function pdfPreview(
		  required binary asset
		, required string filename
		,          string scale
		,          string resolution
		,          string format
		,          string pages
		,          string transparent
	) {
		return _getImplementation().pdfPreview(argumentCollection = arguments);
	}

	public struct function getImageInformation( required binary asset ) {
		try {
			return ImageInfo( ImageNew( arguments.asset ) );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		return {};
	}

	private function _getImplementation() {
	    var useImageMagick = $getPresideSetting( "asset-manager", "isImageMagick" );

	    if ( IsBoolean( useImageMagick ) && useImageMagick ) {

	        return _getImageMagickImplementation();
	    }
	    return _getNativeImageImplementation();
	}

	private any function _setNativeImageImplementation(required any nativeImageImplementation) {
		_nativeImageImplementation = arguments.nativeImageImplementation;
	}

	private any function _setImageMagickImplementation(required any imageMagickImplementation) {
		var path = $getPresideSetting( "asset-manager", "pathToImageMagick" );
	    var timeout = $getPresideSetting( "asset-manager", "timeout" );
		_imageMagickImplementation = arguments.imageMagickImplementation.init(path, timeout);
	}

	private any function _getNativeImageImplementation() {
		return _nativeImageImplementation;
	}

	private any function _getImageMagickImplementation() {
		return _imageMagickImplementation;
	}

}