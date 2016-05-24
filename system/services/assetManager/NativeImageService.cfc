/**
 * Provides logic for manipulating Native images.
 *
 * @singleton
 * @autodoc
 *
 */
component displayname="Native Image Manipulation Service" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * Resizes an native image
	 *
	 * @autodoc
	 * @asset.hint               Binary of the native image to resize
	 * @width.hint               New width, in pixels
	 * @height.hint              New height, in pixels
	 * @quality.hint             Resize algorithm quality. Options are: highestQuality, highQuality, mediumQuality, highestPerformance, highPerformance and mediumPerformance
	 * @maintainAspectRatio.hint Whether or not maintain the aspect ratio of the native image (if true, an autocrop may be applied if the aspect ratio of the resize differs from the source native image)
	 *
	 */
	public binary function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
	) {
		var image              = "";
		var interpolation      = arguments.quality
		var targetAspectRatio  = 0;
		var currentImageInfo   = {};
		var currentAspectRatio = 0;

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.resize.notAnImage" );
		}

		currentImageInfo = ImageInfo( image );

		if ( !arguments.height ) {
			if ( currentImageInfo.width == arguments.width ) {
				return arguments.asset;
			}
			ImageScaleToFit( image, arguments.width, "", interpolation );
		} else if ( !arguments.width ) {
			if ( currentImageInfo.height == arguments.height ) {
				return arguments.asset;
			}
			ImageScaleToFit( image, "", arguments.height, interpolation );
		} else if ( currentImageInfo.width == arguments.width && currentImageInfo.height == arguments.height ) {
			return arguments.asset;
		} else {
			if ( maintainAspectRatio ) {
				currentAspectRatio = currentImageInfo.width / currentImageInfo.height;
				targetAspectRatio  = arguments.width / arguments.height;
			}

			if ( not maintainAspectRatio or targetAspectRatio eq currentAspectRatio ) {
				ImageResize( image, arguments.width, arguments.height, interpolation );
			} else {
				if ( currentAspectRatio gt targetAspectRatio ) {
					ImageScaleToFit( image, "", arguments.height, interpolation );
					var scaledImgInfo = ImageInfo( image );
					ImageCrop( image, Int( ( scaledImgInfo.width - arguments.width ) / 2 ), 0, arguments.width, arguments.height );
				} else {
					ImageScaleToFit( image, arguments.width, "", interpolation );
					var scaledImgInfo = ImageInfo( image );
					ImageCrop( image, 0, Int( ( scaledImgInfo.height - arguments.height ) / 2 ), arguments.width, arguments.height );
				}
			}
		}

		return ImageGetBlob( image );
	}

	/**
	 * Shrinks an native image to fit within a given width and height, without changing
	 * the native images aspect ratio.
	 *
	 * @autodoc
	 * @asset.hint   Binary of the native image to transorm
	 * @width.hint   Maximum width for the native image, in pixels
	 * @height.hint  Maximum height for the native image, in pixels
	 * @quality.hint Resize algorithm quality. Options are: highestQuality, highQuality, mediumQuality, highestPerformance, highPerformance and mediumPerformance
	 *
	 */
	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          string  quality = "highPerformance"
	) {
		var image         = "";
		var imageInfo     = "";
		var interpolation = arguments.quality;

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		imageInfo = ImageInfo( image );
		if ( imageInfo.width > arguments.width || imageInfo.height > arguments.height ) {
			ImageScaleToFit( image, arguments.width, arguments.height, interpolation );
		}

		return ImageGetBlob( image );
	}

	/**
	 * Generates an native image from the first page of the provided PDF binary
	 *
	 * @autodoc
	 * @asset.hint       Binary of the PDF
	 * @scale.hint       Size of the thumbnail relative to the source page. The value represents a percentage from 1 through 100.
	 * @resolution.hint  Native Image quality used to generate thumbnail native images
	 * @format.hint      File type of thumbnail native image output
	 * @pages.hint       Page or pages in the source PDF document on which to perform the action. You can specify multiple pages and page ranges as follows: "1,6-9,56-89,100, 110-120".
	 * @transparent.hint (format="png" only) Specifies whether the native image background is transparent or opaque
	 *
	 */
	public binary function pdfPreview(
		  required binary asset
		,          string scale
		,          string resolution
		,          string format
		,          string pages
		,          string transparent
	) {
		var imagePrefix = CreateUUId();
		var tmpFilePath = GetTempDirectory() & "/" & imagePrefix & "_page_" & arguments.page & ".jpg";
		var allowedArgs = [ "scale", "resolution", "format", "pages", "transparent", "maxscale", "maxlength", "maxbreadth" ];
		var pdfAttributes = {
			  action      = "thumbnail"
			, source      = asset
			, destination = GetTempDirectory()
			, imagePrefix = imagePrefix
		};

		for( var arg in allowedArgs ) {
			if ( StructKeyExists( arguments, arg ) ) {
				pdfAttributes[ arg ] = arguments[ arg ];
			}
		}

		pdf attributeCollection=pdfAttributes;

		return FileReadBinary( tmpFilePath );
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