/**
 * Provides logic for manipulating images.
 *
 * @singleton
 * @autodoc
 * @presideService true
 *
 */
component displayname="Image Manipulation Service" {

	// CONSTRUCTOR
	public any function init() {
		ImageWrappers = $getPresideCategorySettings( "asset-manager" );

		if ( structKeyExists( ImageWrappers , "isImageMagick" ) && val( ImageWrappers.isImageMagick ) ) {
			ImageWrappers = new ImageMagickWrapper( ImageWrappers.pathToImageMagick , ImageWrappers.timeout );
		} else {
			ImageWrappers = new NativeImageWrapper();
		}

		return this;
	}

	public string function resize(
		  required binary  asset
		,          struct  assetProperty       = {}
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
	) {
       	return ImageWrappers.resize(argumentCollection = arguments);
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          struct  assetProperty = {}
		,          string  quality       = "highPerformance"
	) {
		return ImageWrappers.shrinkToFit(argumentCollection = arguments);
	}

	public binary function pdfPreview(
		  required binary asset
		,          string scale
		,          string resolution
		,          string format
		,          string pages
		,          string transparent
	) {
		return ImageWrappers.pdfPreview(argumentCollection = arguments);
	}

	public struct function getImageInformation( required binary asset ) {
		try {
			return ImageInfo( ImageNew( arguments.asset ) );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		return {};
	}
}