/**
 * Provides logic for manipulating Native images.
 *
 * @singleton
 * @autodoc
 *
 */
component displayname="Native Image Manipulation Service" {

// CONSTRUCTOR
	/**
	 * @svgToPngService.inject svgToPngService
	 *
	 */
	public any function init( required any svgToPngService ) {
		_setSvgToPngService( arguments.svgToPngService );

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
	 * @focalPoint.hint          Comma-separated list (x,y) defining coordinates of the image's focal point. When cropped, this point will be kept as close as possible to the centre of the resulting image.
	 * @cropHintArea.hint        Struct (x,y,width,height) defining a crop hint area of the image. Image will be cropped to this area before resizing.
	 *
	 */
	public binary function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
		,          string  focalPoint          = ""
		,          struct  cropHintArea        = {}
		,          struct  fileProperties      = {}
	) {
		var image              = "";
		var interpolation      = arguments.quality;
		var targetAspectRatio  = 0;
		var currentImageInfo   = {};
		var currentAspectRatio = 0;
		var isSvg              = ( fileProperties.fileExt ?: "" ) == "svg";

		try {
			var assetBinary = arguments.asset;

			if( isSvg ) {
				assetBinary = _getSvgToPngService().SVGToPngBinary( arguments.asset, arguments.width, arguments.height );
				fileProperties.fileExt = "png";
			}

			image = ImageNew( correctImageOrientation( assetBinary ) );
			currentImageInfo = ImageInfo( image );

		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.resize.notAnImage" );
		}

		if ( !arguments.height ) {
			ImageScaleToFit( image, arguments.width, "", interpolation );
		} else if ( !arguments.width ) {
			ImageScaleToFit( image, "", arguments.height, interpolation );
		} else if ( !arguments.cropHintArea.isEmpty() ) {
			ImageCrop( image, arguments.cropHintArea.x, arguments.cropHintArea.y, arguments.cropHintArea.width, arguments.cropHintArea.height );
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
		,          struct  fileProperties = {}

	) {
		var image         = "";
		var imageInfo     = "";
		var interpolation = arguments.quality;
		var isSvg         = ( fileProperties.fileExt ?: "" ) == "svg";

		try {
			var assetBinary = arguments.asset;

			if( isSvg ) {
				assetBinary = _getSvgToPngService().SVGToPngBinary ( arguments.asset, arguments.width, arguments.height );
				fileProperties.fileExt = "png";
			}

			image = ImageNew( correctImageOrientation( assetBinary ) );
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
		  required binary  asset
		,          string  scale
		,          string  resolution
		,          string  format
		,          string  pages
		,          string  transparent
		,          numeric width = 300
		,          struct  fileProperties = {}
	) {
		var imagePrefix = CreateUUId();
		var tmpFilePath = GetTempDirectory() & "/" & imagePrefix & "_page_" & arguments.page & ".jpg";
		var allowedArgs = [ "scale", "resolution", "format", "pages", "transparent", "maxscale", "maxlength", "maxbreadth", "width" ];
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

		if ( Val( Left( SERVER.lucee.version ?: "", 1 ) ) >= 5 ) {
			var tmpFilePDF  = GetTempDirectory() & imagePrefix & "_page_" & arguments.page & ".pdf";
			var tmpFileJPG  = GetTempDirectory() & imagePrefix & "1.jpg";

			FileWrite( tmpFilePDF, pdfAttributes.source );

			var returnFilePrefix = GetTempDirectory() & imagePrefix;
			var bufferedImage    = createObject("java","java.awt.image.BufferedImage");
			var imageWriter      = createObject("java","org.apache.pdfbox.util.PDFImageWriter");
			var document         = createObject("java","org.apache.pdfbox.pdmodel.PDDocument").load( tmpFilePDF );

			imageWriter.writeImage( document, JavaCast( "string", "jpg" ), JavaCast( "string", "" ), "1", "1", JavaCast( "string", returnFilePrefix ), bufferedImage.TYPE_INT_RGB, arguments.width );
			document.close();

			cfimage(
				  action      = "resize"
				, source      = tmpFileJPG
				, destination = tmpFileJPG
				, overwrite   = true
				, width       = arguments.width
			);

			tmpFilePath = tmpFileJPG;
		} else {
			pdf attributeCollection=pdfAttributes;
		}

		fileProperties.fileExt = "jpg";

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

// GETTERS/SETTERS
	private any function _getSvgToPngService() {
	    return _svgToPngService;
	}
	private void function _setSvgToPngService( required any svgToPngService ) {
	    _svgToPngService = arguments.svgToPngService;
	}

}