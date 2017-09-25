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
		,          string  focalPoint          = ""
		,          string  cropHint            = ""
		,          boolean useCropHint         = false
	) {
		var image              = "";
		var interpolation      = arguments.quality;
		var targetAspectRatio  = 0;
		var currentImageInfo   = {};
		var currentAspectRatio = 0;

		try {

			image = ImageNew( correctImageOrientation( arguments.asset ) );
			currentImageInfo = ImageInfo( image );

		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.resize.notAnImage" );
		}

		if ( !arguments.height ) {
			ImageScaleToFit( image, arguments.width, "", interpolation );
		} else if ( !arguments.width ) {
			ImageScaleToFit( image, "", arguments.height, interpolation );
		} else if ( arguments.useCropHint && arguments.cropHint.len() ) {
			cropUsingCropHint(
				  image         = image
				, width         = arguments.width
				, height        = arguments.height
				, cropHint      = arguments.cropHint
			);
			ImageResize( image, arguments.width, arguments.height, interpolation );
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
				} else {
					ImageScaleToFit( image, arguments.width, "", interpolation );
				}
				cropAroundFocalPoint( image, arguments.width, arguments.height, arguments.focalPoint );
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

			image = ImageNew( correctImageOrientation( arguments.asset ) );
			imageInfo = ImageInfo( image );

		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		if ( imageInfo.width > arguments.width || imageInfo.height > arguments.height ) {
			ImageScaleToFit( image, arguments.width, arguments.height, interpolation );
		}else{
			ImageScaleToFit( image, imageInfo.width, imageInfo.height, interpolation );
		}

		return ImageGetBlob( image );
	}

	/**
	 * Crops an image to new dimensions, while ensuring that the asset's focal point
	 * (if defined) is as close to the centre of the image as possible.
	 *
	 * @autodoc
	 * @image.hint      Image object (generally already scaled)
	 * @width.hint      Width of the crop area, in pixels
	 * @height.hint     Height of the crop area, in pixels
	 * @focalPoint.hint Coordinates of the image's focal point. Comma-separated x,y - where each coordinate is a value between 0 and 1, the offset of the point from the top left corner of the image. So "0.5,0.5" would place the focal point in the centre of the image.
	 *
	 */
	public binary function cropAroundFocalPoint(
		  required any     image
		, required numeric width
		, required numeric height
		, required string  focalPoint
	) {
		var image       = arguments.image;
		var originX     = 0;
		var originY     = 0;
		var cropCentreX = originX + int( arguments.width  / 2 );
		var cropCentreY = originY + int( arguments.height / 2 );
		var imageInfo   = ImageInfo( image );
		var focalPoint  = len( arguments.focalPoint ) ? arguments.focalPoint : "0.5,0.5";
		var focalPointX = int( listFirst( focalPoint ) * imageInfo.width  );
		var focalPointY = int( listLast(  focalPoint ) * imageInfo.height );

		if ( focalPointX > cropCentreX ) {
			originX = min( originX + ( focalPointX - cropCentreX ), imageInfo.width - arguments.width );
		}
		if ( focalPointY > cropCentreY ) {
			originY = min( originY + ( focalPointY - cropCentreY ), imageInfo.height - arguments.height );
		}

		ImageCrop( image, originX, originY, arguments.width, arguments.height );

		return ImageGetBlob( image );
	}

	public binary function cropUsingCropHint(
		  required any     image
		, required numeric width
		, required numeric height
		, required string  cropHint
	) {
		var image          = arguments.image;
		var targetWidth    = arguments.width;
		var targetHeight   = arguments.height;
		var targetRatio    = targetWidth / targetHeight;
		var imageInfo      = ImageInfo( image );
		var cropHintCoords = arguments.cropHint.listToArray();
		var cropX          = int( cropHintCoords[ 1 ] * imageInfo.width );
		var cropY          = int( cropHintCoords[ 2 ] * imageInfo.height );
		var cropWidth      = int( cropHintCoords[ 3 ] * imageInfo.width );
		var cropHeight     = int( cropHintCoords[ 4 ] * imageInfo.height );
		var cropHintRatio  = cropWidth / cropHeight;
		var prevCropWidth  = 0;
		var prevCropHeight = 0;
		var widthRatio     = 0;
		var heightRatio    = 0;

		if ( cropHintRatio > targetRatio ) {
			prevCropHeight = cropHeight;
			cropHeight     = int( cropHeight * ( cropHintRatio / targetRatio ) );
			cropY          = int( cropY - ( ( cropHeight - prevCropHeight ) / 2 ) );
		} else if ( cropHintRatio < targetRatio ) {
			prevCropWidth = cropWidth;
			cropWidth     = int( cropWidth * ( targetRatio / cropHintRatio ) );
			cropX         = int( cropX - ( ( cropWidth - prevCropWidth ) / 2 ) );
		}

		if ( targetWidth > cropWidth ) {
			prevCropWidth  = cropWidth;
			widthRatio     = targetWidth / cropWidth;
			cropWidth      = int( cropWidth  * widthRatio );
			cropX          = int( cropX - ( ( cropWidth  - prevCropWidth ) / 2 ) );
		}
		if ( targetHeight > cropHeight ) {
			prevCropHeight = cropHeight;
			heightRatio    = targetHeight / cropHeight;
			cropHeight     = int( cropHeight * heightRatio );
			cropY          = int( cropY - ( ( cropHeight - prevCropHeight ) / 2 ) );
		}


		if ( cropWidth > imageInfo.width || cropHeight > imageInfo.height ) {
			fitRatio       = min( imageInfo.width / cropWidth, imageInfo.height / cropHeight );
			prevCropWidth  = cropWidth;
			prevCropHeight = cropHeight;
			cropWidth      = int( cropWidth  * fitRatio );
			cropX          = int( cropX - ( ( cropWidth  - prevCropWidth ) / 2 ) );
			cropHeight     = int( cropHeight * fitRatio );
			cropY          = int( cropY - ( ( cropHeight - prevCropHeight ) / 2 ) );
		}

		cropX = max( cropX, 0 );
		cropY = max( cropY, 0 );
		cropX = min( cropX, imageInfo.width - cropWidth );
		cropY = min( cropY, imageInfo.height - cropHeight );

		ImageCrop( image, cropX, cropY, cropWidth, cropHeight );
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
		var image = "";
		var imageInfo = {};

		try {

			image = ImageNew( correctImageOrientation( arguments.asset ) );
			imageInfo = ImageInfo( image );

		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		return imageInfo;
	}

	public binary function correctImageOrientation( required binary asset ) {
		var imageBinary = arguments.asset;
		var imageInfo = {};
		var tmpFilePath = GetTempFile( GetTempDirectory(), "ntv" );

		fileWrite( tmpFilePath, imageBinary );
		var oImage = ImageNew( tmpFilePath );

		try {

			imageOrientation = imageGetEXIFTag( oImage, "orientation" );
			imageInfo = imageInfo( oImage );
			if ( findNoCase( "Rotate", imageOrientation ) && !findNoCase( "Mirror", imageOrientation ) ){
				var iRotate = 0;
				if ( imageInfo.width > imageInfo.height ) {
					if ( findNoCase( "Rotate 90 CW", imageOrientation ) ){
						iRotate = 90;
					}
					if ( findNoCase( "Rotate 270 CW", imageOrientation ) ){
						iRotate = 270;
					}
				}
				if ( findNoCase( "Rotate 180", imageOrientation ) ){
					iRotate = 180;
				}
				if ( iRotate > 0 ){
					imageRotate( name = oImage, angle = iRotate, x = 2, interpolation = "bicubic" );
					imageBinary = imageGetBlob( oImage );
				}
			}

		} catch (any e) {
			//No exif tag - orientation
		} finally {
			fileDelete( tmpFilePath );
		}

		return ( imageBinary );
	}

}