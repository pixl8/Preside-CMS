component output=false {

// CONSTRUCTOR
	public any function init() output=false {
		return this;
	}

// PUBLIC API METHODS
	public binary function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          boolean maintainAspectRatio = false
	) output=false {
		var image              = "";
		var interpolation      = "highestperformance";
		var targetAspectRatio  = 0;
		var currentImageInfo   = {};
		var currentAspectRatio = 0;

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.resize.notAnImage" );
		}

		if ( not arguments.height ) {
			ImageScaleToFit( image, arguments.width, "", interpolation );
		} else if ( not arguments.width ) {
			ImageScaleToFit( image, "", arguments.height, interpolation );
		} else {
			if ( maintainAspectRatio ) {
				currentImageInfo   = ImageInfo( image );
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

	public binary function shrinkToFit( required binary asset, required numeric width, required numeric height ) output=false {
		var image         = "";
		var imageInfo     = "";
		var interpolation = "highestperformance";

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		imageInfo = ImageInfo( image );
		if ( imageInfo.width > arguments.width && imageInfo.height > arguments.height ) {
			if ( ( imageInfo.width - arguments.width ) > ( imageInfo.height - arguments.height ) ) {
				ImageScaleToFit( image, arguments.width, "", interpolation );
			} else {
				ImageScaleToFit( image, "", arguments.height, interpolation );
			}
		} elseif ( imageInfo.width > arguments.width ) {
			ImageScaleToFit( image, arguments.width, "", interpolation );
		} elseif ( imageInfo.height > arguments.height ) {
			ImageScaleToFit( image, "", arguments.height, interpolation );
		}

		return ImageGetBlob( image );
	}

	public binary function pdfPreview( required binary asset, numeric page=1 ) output=false {
		var imagePrefix = CreateUUId();
		var tmpFilePath = GetTempDirectory() & "/" & imagePrefix & "_page_" & arguments.page & ".jpg";

		pdf action="thumbnail" source=asset destination=GetTempDirectory() imagePrefix=imagePrefix;

		return FileReadBinary( tmpFilePath );
	}
}